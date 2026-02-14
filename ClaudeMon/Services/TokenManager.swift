import Foundation
import KeychainAccess

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
            }
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
    /// - Returns: Decoded `ClaudeCredentials` containing OAuth tokens and metadata.
    /// - Throws: `TokenError.noCredentials` if no entry found, `.decodingError` if JSON is malformed.
    static func getCredentials() throws -> ClaudeCredentials {
        let keychain = Keychain(service: Constants.keychainService)

        // Claude Code stores credentials under the current user's username as account
        let username = NSUserName()

        let credentialsJSON: String?
        do {
            credentialsJSON = try keychain.getString(username)
        } catch {
            throw TokenError.decodingError(error)
        }

        guard let json = credentialsJSON else {
            throw TokenError.noCredentials
        }

        guard let data = json.data(using: .utf8) else {
            throw TokenError.noCredentials
        }

        do {
            let credentials = try JSONDecoder().decode(ClaudeCredentials.self, from: data)
            return credentials
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
            "client_id": Constants.oauthClientId,
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
    /// - Note: Writing back to the Keychain may conflict with Claude Code's own token management.
    ///   This is implemented but should be monitored for issues. If conflicts arise, disable
    ///   the write-back and notify users to re-authenticate Claude Code instead.
    static func updateKeychainCredentials(response: OAuthTokenResponse) throws {
        let keychain = Keychain(service: Constants.keychainService)

        // Read current credentials
        var credentials = try getCredentials()

        // Update with refreshed values
        credentials.claudeAiOauth.accessToken = response.accessToken
        credentials.claudeAiOauth.refreshToken = response.refreshToken

        // Compute new expiresAt from expiresIn (convert seconds to milliseconds)
        let newExpiresAt = Int64(Date().timeIntervalSince1970 * 1000) + Int64(response.expiresIn) * 1000
        credentials.claudeAiOauth.expiresAt = newExpiresAt

        // Encode back to JSON
        let encoder = JSONEncoder()
        let updatedData = try encoder.encode(credentials)
        guard let jsonString = String(data: updatedData, encoding: .utf8) else {
            throw TokenError.decodingError(
                NSError(domain: "TokenManager", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to encode credentials to JSON string"
                ])
            )
        }

        // Write back to Keychain using the current username as account
        // WARNING: This may conflict with Claude Code's own Keychain access
        let username = NSUserName()
        print("[ClaudeMon] Writing refreshed credentials back to Keychain (potential conflict with Claude Code)")
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

        guard let data = json.data(using: .utf8) else {
            throw TokenError.noCredentials
        }

        return try JSONDecoder().decode(ClaudeCredentials.self, from: data)
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
    /// - Parameters:
    ///   - response: The token refresh response containing new tokens.
    ///   - username: The Keychain account key for the target account.
    /// - Throws: `TokenError` if reading or writing the Keychain fails.
    static func updateKeychainCredentials(response: OAuthTokenResponse, for username: String) throws {
        let keychain = Keychain(service: Constants.keychainService)
        var credentials = try getCredentials(username: username)

        credentials.claudeAiOauth.accessToken = response.accessToken
        credentials.claudeAiOauth.refreshToken = response.refreshToken

        let newExpiresAt = Int64(Date().timeIntervalSince1970 * 1000) + Int64(response.expiresIn) * 1000
        credentials.claudeAiOauth.expiresAt = newExpiresAt

        let encoder = JSONEncoder()
        let updatedData = try encoder.encode(credentials)
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
