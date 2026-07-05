import Foundation
import KeychainAccess
import Security

/// Stateless utility for reading, validating, and refreshing Claude Code OAuth credentials
/// stored in the macOS Keychain under the "Claude Code-credentials" service.
struct TokenManager {

    // MARK: - Types

    /// Errors that can occur during token operations
    enum TokenError: Error, LocalizedError {
        case noCredentials
        case expired
        case refreshFailed
        case insufficientScope
        case decodingError(Error)
        /// Keychain ACL excludes Tokemon. macOS would prompt the user, but we have
        /// disabled prompts (LSUIElement apps can't show them). User must add Tokemon
        /// to the credential's Access Control list via Keychain Access.app.
        case keychainAccessDenied
        /// Keychain access did not return within the deadline. Defense in depth in case
        /// `SecKeychainSetUserInteractionAllowed(false)` ever fails to take effect.
        case keychainAccessTimedOut

        var errorDescription: String? {
            switch self {
            case .noCredentials:
                return "No Claude Code credentials found in Keychain"
            case .expired:
                return "OAuth access token has expired"
            case .refreshFailed:
                return "Failed to refresh the OAuth access token"
            case .insufficientScope:
                return "OAuth token missing required 'user:profile' scope"
            case .decodingError(let error):
                return "Failed to decode credentials: \(error.localizedDescription)"
            case .keychainAccessDenied:
                return "Tokemon is not authorized to read the Claude Code credentials. Open Keychain Access, find 'Claude Code-credentials', and add Tokemon to its Access Control list."
            case .keychainAccessTimedOut:
                return "Reading Claude Code credentials timed out. Open Keychain Access, find 'Claude Code-credentials', and add Tokemon to its Access Control list."
            }
        }
    }

    // MARK: - Startup hardening

    /// Disable interactive keychain prompts process-wide. Tokemon is LSUIElement
    /// (no main window), so a queued SecurityAgent prompt would never display and
    /// `SecItemCopyMatching` would block the calling thread forever. With prompts
    /// disabled, denied ACLs return `errSecInteractionNotAllowed` immediately and
    /// we surface a re-authorize banner in the popover instead. Call once at app launch.
    static func disableInteractiveKeychainPrompts() {
        let status = SecKeychainSetUserInteractionAllowed(false)
        if status != errSecSuccess {
            print("[Tokemon] SecKeychainSetUserInteractionAllowed failed: \(status)")
        }
    }

    /// Top-level Keychain JSON structure.
    /// Claude Code stores credentials as `{ "claudeAiOauth": { ... } }` in Keychain.
    struct ClaudeCredentials: Codable {
        var claudeAiOauth: OAuthCredential
    }

    /// Nested OAuth credential fields matching the verified Keychain structure.
    struct OAuthCredential: Codable {
        var accessToken: String
        var refreshToken: String
        var expiresAt: Int64
        var scopes: [String]
        var subscriptionType: String?
        var rateLimitTier: String?
    }

    /// Response from the OAuth token refresh endpoint.
    struct OAuthTokenResponse: Codable {
        let accessToken: String
        let refreshToken: String
        let expiresIn: Int
        let tokenType: String

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresIn = "expires_in"
            case tokenType = "token_type"
        }
    }

    // MARK: - Credential Access

    /// Read and decode Claude Code credentials from the macOS Keychain.
    ///
    /// The keychain query runs on a background queue with a 5-second deadline. If the
    /// underlying `SecItemCopyMatching` ever blocks (e.g. an interactive prompt slipped
    /// past `SecKeychainSetUserInteractionAllowed(false)`), we throw
    /// `TokenError.keychainAccessTimedOut` instead of hanging the polling Task.
    /// `errSecInteractionNotAllowed` and `errSecAuthFailed` are mapped to
    /// `TokenError.keychainAccessDenied` so the popover can show a re-authorize banner.
    /// - Returns: Decoded `ClaudeCredentials` containing OAuth tokens and metadata.
    /// - Throws: See `TokenError`.
    static func getCredentials() throws -> ClaudeCredentials {
        let keychain = Keychain(service: Constants.keychainService)
        let username = NSUserName()

        // Run the synchronous keychain call on a background queue with a deadline so a
        // hung Mach call can't freeze the MainActor that owns UsageMonitor.refresh().
        let semaphore = DispatchSemaphore(value: 0)
        var result: Result<String?, Error>?
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                result = .success(try keychain.getString(username))
            } catch {
                result = .failure(error)
            }
            semaphore.signal()
        }

        switch semaphore.wait(timeout: .now() + 5.0) {
        case .timedOut:
            throw TokenError.keychainAccessTimedOut
        case .success:
            break
        }

        guard let result else { throw TokenError.keychainAccessTimedOut }

        let credentialsJSON: String?
        switch result {
        case .success(let value):
            credentialsJSON = value
        case .failure(let error):
            // Map ACL/auth denials so the UI can show the re-authorize banner.
            // KeychainAccess wraps the OSStatus; check the NSError code path first.
            let nsError = error as NSError
            if nsError.code == Int(errSecInteractionNotAllowed)
                || nsError.code == Int(errSecAuthFailed)
                || nsError.code == Int(errSecMissingEntitlement) {
                throw TokenError.keychainAccessDenied
            }
            throw TokenError.decodingError(error)
        }

        guard let json = credentialsJSON else {
            throw TokenError.noCredentials
        }

        return try decodeCredentials(from: json)
    }

    /// Decode credentials from a JSON string, tolerating a leading length-prefix byte
    /// that Claude Code may prepend to the Keychain value.
    private static func decodeCredentials(from json: String) throws -> ClaudeCredentials {
        guard let data = json.data(using: .utf8), !data.isEmpty else {
            throw TokenError.noCredentials
        }

        // Claude Code may store credentials with a leading non-JSON byte (e.g. 0x07).
        // Find the opening brace and decode from there.
        guard let braceIndex = data.firstIndex(of: UInt8(ascii: "{")) else {
            throw TokenError.noCredentials
        }

        do {
            return try JSONDecoder().decode(ClaudeCredentials.self, from: data[braceIndex...])
        } catch {
            throw TokenError.decodingError(error)
        }
    }

    /// Get a valid access token, checking expiry with a 10-minute proactive buffer.
    /// - Returns: The OAuth access token string.
    /// - Throws: `TokenError.expired` if token is expired or within 10 minutes of expiry,
    ///           `TokenError.insufficientScope` if `user:profile` scope is missing.
    static func getAccessToken() throws -> String {
        let credentials = try getCredentials()
        let oauth = credentials.claudeAiOauth

        // expiresAt is in milliseconds since epoch
        let expiresAtDate = Date(timeIntervalSince1970: Double(oauth.expiresAt) / 1000.0)
        let bufferDate = Date().addingTimeInterval(10 * 60) // 10-minute proactive buffer

        if expiresAtDate < bufferDate {
            throw TokenError.expired
        }

        // Validate required scope
        if !oauth.scopes.contains("user:profile") {
            throw TokenError.insufficientScope
        }

        return oauth.accessToken
    }

    /// Get a valid access token using ACTUAL expiry (no proactive buffer).
    /// Used as a fallback when token refresh fails — the token written by Claude Code
    /// may still be valid even though it's within the 10-minute buffer window.
    /// - Returns: The OAuth access token string.
    /// - Throws: `TokenError.expired` if the token is truly expired,
    ///           `TokenError.insufficientScope` if `user:profile` scope is missing.
    static func getAccessTokenIgnoringBuffer() throws -> String {
        let credentials = try getCredentials()
        let oauth = credentials.claudeAiOauth

        // Check ACTUAL expiry -- no proactive buffer
        let expiresAtDate = Date(timeIntervalSince1970: Double(oauth.expiresAt) / 1000.0)
        if expiresAtDate < Date() {
            throw TokenError.expired
        }

        if !oauth.scopes.contains("user:profile") {
            throw TokenError.insufficientScope
        }

        return oauth.accessToken
    }

    /// Get the refresh token for token renewal.
    /// - Returns: The OAuth refresh token string.
    /// - Throws: `TokenError.noCredentials` if credentials not found.
    static func getRefreshToken() throws -> String {
        let credentials = try getCredentials()
        return credentials.claudeAiOauth.refreshToken
    }

    /// Refresh an expired access token using the refresh token.
    /// - Parameter refreshToken: The OAuth refresh token.
    /// - Returns: An `OAuthTokenResponse` containing the new access and refresh tokens.
    /// - Throws: `TokenError.refreshFailed` on network or server errors.
    static func refreshAccessToken(refreshToken: String) async throws -> OAuthTokenResponse {
        guard let url = URL(string: Constants.oauthTokenRefreshURL) else {
            throw TokenError.refreshFailed
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": Constants.oauthClientId
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw TokenError.refreshFailed
        }

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw TokenError.refreshFailed
        }

        do {
            return try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
        } catch {
            throw TokenError.refreshFailed
        }
    }

    /// Update the Keychain entry with refreshed token data.
    /// - Parameter response: The token refresh response containing new tokens.
    /// - Throws: `TokenError` if reading or writing the Keychain fails.
    ///
    /// Uses dictionary-based merging to preserve ALL fields Claude Code stores in the
    /// Keychain entry. Previous implementation used Codable encode which stripped unknown
    /// fields, potentially corrupting Claude Code's credentials during active sessions.
    static func updateKeychainCredentials(response: OAuthTokenResponse) throws {
        let keychain = Keychain(service: Constants.keychainService)
        let username = NSUserName()

        // Read raw JSON from keychain to preserve all fields
        guard let rawJSON = try keychain.getString(username),
              let rawData = rawJSON.data(using: .utf8), !rawData.isEmpty else {
            throw TokenError.noCredentials
        }

        // Handle leading non-JSON byte that Claude Code may prepend
        guard let braceIndex = rawData.firstIndex(of: UInt8(ascii: "{")) else {
            throw TokenError.noCredentials
        }

        // Parse as mutable dictionaries to preserve ALL original fields
        guard var root = try JSONSerialization.jsonObject(with: rawData[braceIndex...]) as? [String: Any],
              var oauth = root["claudeAiOauth"] as? [String: Any] else {
            throw TokenError.noCredentials
        }

        // Update ONLY the refreshed fields, preserving everything else
        oauth["accessToken"] = response.accessToken
        oauth["refreshToken"] = response.refreshToken
        let newExpiresAt = Int64(Date().timeIntervalSince1970 * 1000) + Int64(response.expiresIn) * 1000
        oauth["expiresAt"] = newExpiresAt

        root["claudeAiOauth"] = oauth

        // Encode back preserving all original fields
        let updatedData = try JSONSerialization.data(withJSONObject: root)
        guard let jsonString = String(data: updatedData, encoding: .utf8) else {
            throw TokenError.decodingError(
                NSError(domain: "TokenManager", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to encode credentials to JSON string"
                ])
            )
        }

        try keychain.set(jsonString, key: username)
    }

    // MARK: - Multi-Account Credential Access

    /// Read credentials for a specific account by username.
    /// - Parameter username: The Keychain account key for the target account.
    /// - Returns: Decoded `ClaudeCredentials` for the specified account.
    /// - Throws: `TokenError.noCredentials` if no entry found.
    static func getCredentials(username: String) throws -> ClaudeCredentials {
        let keychain = Keychain(service: Constants.keychainService)

        guard let json = try keychain.getString(username) else {
            throw TokenError.noCredentials
        }

        return try decodeCredentials(from: json)
    }

    /// Get valid access token for a specific account, checking expiry with a 10-minute buffer.
    /// - Parameter username: The Keychain account key for the target account.
    /// - Returns: The OAuth access token string.
    /// - Throws: `TokenError.expired` or `TokenError.insufficientScope`.
    static func getAccessToken(for username: String) throws -> String {
        let credentials = try getCredentials(username: username)
        let oauth = credentials.claudeAiOauth

        let expiresAtDate = Date(timeIntervalSince1970: Double(oauth.expiresAt) / 1000.0)
        let bufferDate = Date().addingTimeInterval(10 * 60)

        if expiresAtDate < bufferDate {
            throw TokenError.expired
        }

        if !oauth.scopes.contains("user:profile") {
            throw TokenError.insufficientScope
        }

        return oauth.accessToken
    }

    /// Get the refresh token for a specific account.
    /// - Parameter username: The Keychain account key for the target account.
    /// - Returns: The OAuth refresh token string.
    /// - Throws: `TokenError.noCredentials` if credentials not found.
    static func getRefreshToken(for username: String) throws -> String {
        let credentials = try getCredentials(username: username)
        return credentials.claudeAiOauth.refreshToken
    }

    /// Update Keychain credentials for a specific account after token refresh.
    /// Uses dictionary-based merging to preserve all fields Claude Code stores.
    /// - Parameters:
    ///   - response: The token refresh response containing new tokens.
    ///   - username: The Keychain account key for the target account.
    /// - Throws: `TokenError` if reading or writing the Keychain fails.
    static func updateKeychainCredentials(response: OAuthTokenResponse, for username: String) throws {
        let keychain = Keychain(service: Constants.keychainService)

        // Read raw JSON to preserve all fields
        guard let rawJSON = try keychain.getString(username),
              let rawData = rawJSON.data(using: .utf8), !rawData.isEmpty else {
            throw TokenError.noCredentials
        }

        guard let braceIndex = rawData.firstIndex(of: UInt8(ascii: "{")) else {
            throw TokenError.noCredentials
        }

        guard var root = try JSONSerialization.jsonObject(with: rawData[braceIndex...]) as? [String: Any],
              var oauth = root["claudeAiOauth"] as? [String: Any] else {
            throw TokenError.noCredentials
        }

        // Update ONLY the refreshed fields
        oauth["accessToken"] = response.accessToken
        oauth["refreshToken"] = response.refreshToken
        let newExpiresAt = Int64(Date().timeIntervalSince1970 * 1000) + Int64(response.expiresIn) * 1000
        oauth["expiresAt"] = newExpiresAt

        root["claudeAiOauth"] = oauth

        let updatedData = try JSONSerialization.data(withJSONObject: root)
        guard let jsonString = String(data: updatedData, encoding: .utf8) else {
            throw TokenError.decodingError(
                NSError(domain: "TokenManager", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to encode credentials to JSON string"
                ])
            )
        }

        try keychain.set(jsonString, key: username)
    }
}
