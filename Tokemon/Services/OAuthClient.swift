import Foundation

/// HTTP client for fetching Claude usage data from the OAuth endpoint.
/// Handles authentication, token refresh, and error mapping.
struct OAuthClient {

    // MARK: - Types

    /// Errors that can occur during OAuth API calls
    enum OAuthError: Error, LocalizedError {
        case invalidResponse
        case tokenExpired
        case insufficientScope
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
    /// - Parameter accessToken: A valid OAuth access token with `user:profile` scope.
    /// - Returns: The decoded `OAuthUsageResponse`.
    /// - Throws: `OAuthError` for HTTP errors, network failures, or invalid responses.
    static func fetchUsage(accessToken: String) async throws -> OAuthUsageResponse {
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
                return try JSONDecoder().decode(OAuthUsageResponse.self, from: data)
            } catch {
                throw OAuthError.invalidResponse
            }
        case 401:
            throw OAuthError.tokenExpired
        case 403:
            throw OAuthError.insufficientScope
        default:
            let bodyString = String(data: data, encoding: .utf8)
            throw OAuthError.httpError(httpResponse.statusCode, bodyString)
        }
    }

    /// Fetch usage data with automatic token refresh on expiry.
    ///
    /// Flow:
    /// 1. Try to get access token from Keychain
    /// 2. If expired, attempt refresh using refresh token
    /// 3. Call the usage endpoint
    /// 4. If 401 returned, attempt one refresh cycle and retry
    ///
    /// - Returns: The decoded `OAuthUsageResponse`.
    /// - Throws: `OAuthError` or `TokenManager.TokenError` if all attempts fail.
    static func fetchUsageWithTokenRefresh() async throws -> OAuthUsageResponse {
        let accessToken: String

        do {
            accessToken = try TokenManager.getAccessToken()
        } catch TokenManager.TokenError.expired {
            // Token expired -- attempt refresh
            let refreshedToken = try await performTokenRefresh()
            return try await fetchUsage(accessToken: refreshedToken)
        }

        // Token is valid -- try the API call
        do {
            return try await fetchUsage(accessToken: accessToken)
        } catch OAuthError.tokenExpired {
            // Server returned 401 despite our local check -- attempt refresh once
            let refreshedToken = try await performTokenRefresh()
            return try await fetchUsage(accessToken: refreshedToken)
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

    /// Perform the full token refresh cycle: get refresh token, refresh, update Keychain.
    /// - Returns: The new access token string.
    /// - Throws: Token or network errors if refresh fails.
    private static func performTokenRefresh() async throws -> String {
        let refreshToken = try TokenManager.getRefreshToken()
        let tokenResponse = try await TokenManager.refreshAccessToken(refreshToken: refreshToken)

        // Update the Keychain with new credentials
        try TokenManager.updateKeychainCredentials(response: tokenResponse)

        return tokenResponse.accessToken
    }
}
