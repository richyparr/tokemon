import Foundation

/// HTTP client for fetching Claude usage data from the OAuth endpoint.
/// Handles authentication, token refresh, and error mapping.
struct OAuthClient {

    /// Write diagnostic log to ~/.tokemon/oauth-debug.log
    private static func debugLog(_ message: String) {
        let line = "[\(ISO8601DateFormatter().string(from: Date()))] \(message)\n"
        print(line, terminator: "")
        let logDir = NSString(string: "~/.tokemon").expandingTildeInPath
        let logPath = "\(logDir)/oauth-debug.log"
        try? FileManager.default.createDirectory(atPath: logDir, withIntermediateDirectories: true, attributes: nil)
        if let handle = FileHandle(forWritingAtPath: logPath) {
            handle.seekToEndOfFile()
            handle.write(line.data(using: .utf8) ?? Data())
            handle.closeFile()
        } else {
            FileManager.default.createFile(atPath: logPath, contents: line.data(using: .utf8))
        }
    }

    // MARK: - Types

    /// Errors that can occur during OAuth API calls
    enum OAuthError: Error, LocalizedError {
        case invalidResponse
        case tokenExpired
        case insufficientScope
        case rateLimited
        case httpError(Int, String?)
        case networkError(Error)

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Invalid response from usage API"
            case .tokenExpired:
                return "OAuth access token has expired"
            case .insufficientScope:
                return "OAuth token missing required scope for usage data"
            case .rateLimited:
                return "Usage API rate limited (common during active Claude Code sessions)"
            case .httpError(let code, let body):
                if let body = body {
                    return "HTTP \(code): \(body)"
                }
                return "HTTP error \(code)"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - API Methods

    /// Fetch usage data from the OAuth endpoint using a provided access token.
    /// On 429, retries once after a 2s delay then gives up (rate limit is persistent during active sessions).
    /// - Parameter accessToken: A valid OAuth access token with `user:profile` scope.
    /// - Returns: The decoded `OAuthUsageResponse`.
    /// - Throws: `OAuthError` for HTTP errors, network failures, or invalid responses.
    static func fetchUsage(accessToken: String, canRetry: Bool = true) async throws -> OAuthUsageResponse {
        guard let url = URL(string: Constants.oauthUsageURL) else {
            throw OAuthError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.setValue("Tokemon/1.0", forHTTPHeaderField: "User-Agent")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw OAuthError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OAuthError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            do {
                let response = try JSONDecoder().decode(OAuthUsageResponse.self, from: data)
                debugLog("API 200, 5h=\(response.fiveHour?.utilization ?? -1)%")
                return response
            } catch {
                debugLog("API 200 but decode failed: \(error)")
                throw OAuthError.invalidResponse
            }
        case 401:
            debugLog("API 401 (token expired)")
            throw OAuthError.tokenExpired
        case 403:
            debugLog("API 403 (insufficient scope)")
            throw OAuthError.insufficientScope
        case 429:
            debugLog("API 429")

            // Single retry after 2s — rate limit is persistent during active sessions,
            // so more retries just waste time
            if canRetry {
                debugLog("Retrying in 2s...")
                try await Task.sleep(nanoseconds: 2_000_000_000)
                return try await fetchUsage(accessToken: accessToken, canRetry: false)
            }

            throw OAuthError.rateLimited
        default:
            let bodyString = String(data: data, encoding: .utf8)
            debugLog("API \(httpResponse.statusCode): \(bodyString ?? "no body")")
            throw OAuthError.httpError(httpResponse.statusCode, bodyString)
        }
    }

    /// Fetch usage data with automatic token refresh on expiry.
    ///
    /// Flow:
    /// 1. Try to get access token from Keychain
    /// 2. If expired, attempt refresh using refresh token
    /// 3. If refresh fails, re-read keychain (Claude Code may have already refreshed)
    /// 4. Call the usage endpoint
    /// 5. If 401 returned, attempt one refresh cycle and retry (with same re-read fallback)
    ///
    /// - Returns: The decoded `OAuthUsageResponse`.
    /// - Throws: `OAuthError` or `TokenManager.TokenError` if all attempts fail.
    static func fetchUsageWithTokenRefresh() async throws -> OAuthUsageResponse {
        let accessToken: String

        do {
            accessToken = try TokenManager.getAccessToken()
            debugLog("got access token (expires check passed)")
        } catch TokenManager.TokenError.expired {
            // Token expired -- attempt refresh, with keychain re-read fallback
            debugLog("token expired, attempting refresh")
            let resolvedToken = try await refreshWithKeychainFallback()
            return try await fetchUsage(accessToken: resolvedToken)
        } catch {
            debugLog("getAccessToken failed: \(error)")
            throw error
        }

        // Token is valid -- try the API call
        do {
            return try await fetchUsage(accessToken: accessToken)
        } catch OAuthError.tokenExpired {
            // Server returned 401 despite our local check -- attempt refresh with fallback
            debugLog("API returned 401, attempting refresh")
            let resolvedToken = try await refreshWithKeychainFallback()
            return try await fetchUsage(accessToken: resolvedToken)
        }
    }

    // MARK: - Profile-Based Fetch Methods

    /// Fetch usage using credentials stored in a profile (not from system keychain).
    /// - Parameter credentialsJSON: The raw JSON string containing claudeAiOauth credentials.
    /// - Returns: The decoded OAuthUsageResponse.
    /// - Throws: OAuthError or TokenManager.TokenError if credentials are invalid/expired.
    static func fetchUsageWithCredentials(_ credentialsJSON: String) async throws -> OAuthUsageResponse {
        guard let data = credentialsJSON.data(using: .utf8) else {
            throw OAuthError.invalidResponse
        }

        let credentials = try JSONDecoder().decode(
            TokenManager.ClaudeCredentials.self,
            from: data
        )
        let oauth = credentials.claudeAiOauth

        // Check expiry with 10-minute buffer
        let expiresAtDate = Date(timeIntervalSince1970: Double(oauth.expiresAt) / 1000.0)
        let bufferDate = Date().addingTimeInterval(10 * 60)

        if expiresAtDate < bufferDate {
            // Try to refresh using the stored refresh token
            let tokenResponse = try await TokenManager.refreshAccessToken(
                refreshToken: oauth.refreshToken
            )
            // Return usage with the refreshed token
            // Note: We don't write back to system keychain here -- only the active profile's
            // credentials get written to keychain on switch
            return try await fetchUsage(accessToken: tokenResponse.accessToken)
        }

        return try await fetchUsage(accessToken: oauth.accessToken)
    }

    /// Fetch usage using a manual session key (API key style auth).
    /// - Parameters:
    ///   - sessionKey: The Claude session key.
    ///   - orgId: Optional organization ID.
    /// - Returns: The decoded OAuthUsageResponse.
    static func fetchUsageWithSessionKey(_ sessionKey: String, orgId: String? = nil) async throws -> OAuthUsageResponse {
        // Session keys are used as Bearer tokens directly
        return try await fetchUsage(accessToken: sessionKey)
    }

    // MARK: - Private Helpers

    /// Attempt token refresh, falling back to a keychain re-read if refresh fails.
    ///
    /// During an active Claude Code session, both Tokemon and Claude Code share the same
    /// keychain credentials. If Claude Code refreshes first, the refresh token Tokemon holds
    /// is already consumed. This method catches that failure and re-reads the keychain to
    /// pick up the fresh token Claude Code has written.
    ///
    /// - Returns: A valid access token string.
    /// - Throws: If both refresh and keychain re-read fail.
    private static func refreshWithKeychainFallback() async throws -> String {
        do {
            let token = try await performTokenRefresh()
            debugLog("token refresh succeeded")
            return token
        } catch {
            debugLog("token refresh failed: \(error), re-reading keychain...")

            // Claude Code may have already refreshed -- re-read keychain for fresh credentials.
            // Use actual expiry (no proactive buffer) since the token may still be valid.
            do {
                let fallbackToken = try TokenManager.getAccessTokenIgnoringBuffer()
                debugLog("found valid token from keychain re-read")
                return fallbackToken
            } catch {
                debugLog("keychain re-read also failed: \(error)")
            }

            // Keychain re-read also failed -- propagate the original refresh error
            throw error
        }
    }

    /// Perform the full token refresh cycle: get refresh token, refresh, update Keychain.
    /// - Returns: The new access token string.
    /// - Throws: Token or network errors if refresh fails.
    private static func performTokenRefresh() async throws -> String {
        let refreshToken = try TokenManager.getRefreshToken()
        let tokenResponse = try await TokenManager.refreshAccessToken(refreshToken: refreshToken)

        // Update the Keychain with new credentials (preserves unknown fields)
        try TokenManager.updateKeychainCredentials(response: tokenResponse)

        return tokenResponse.accessToken
    }
}
