import Foundation
import KeychainAccess

/// Client for Anthropic Admin API.
/// Manages Admin API key storage and organization usage data fetching.
/// Note: Admin API is only available for organization accounts with admin role.
actor AdminAPIClient {
    static let shared = AdminAPIClient()

    private let keychain = Keychain(service: "ai.tokemon.admin-api")
    private let keychainKey = "admin_api_key"
    private let baseURL = "https://api.anthropic.com/v1/organizations"

    // MARK: - Key Management

    /// Store Admin API key securely after validation.
    func setAdminKey(_ key: String) throws {
        guard key.hasPrefix("sk-ant-admin") else {
            throw AdminAPIError.invalidKeyFormat
        }
        try keychain.set(key, key: keychainKey)
    }

    /// Check if Admin API is configured.
    nonisolated func hasAdminKey() -> Bool {
        // Keychain access is thread-safe, can check synchronously
        (try? Keychain(service: "ai.tokemon.admin-api").get("admin_api_key")) != nil
    }

    /// Get masked key for display (sk-ant-admin...xxxx).
    func getMaskedKey() -> String? {
        guard let key = try? keychain.get(keychainKey) else { return nil }
        guard key.count > 16 else { return "sk-ant-admin...****" }
        let suffix = String(key.suffix(4))
        return "sk-ant-admin...\(suffix)"
    }

    /// Clear stored Admin API key.
    func clearAdminKey() throws {
        try keychain.remove(keychainKey)
    }

    // MARK: - API Calls

    /// Fetch organization usage report.
    ///
    /// - Parameters:
    ///   - startingAt: Start of the reporting period
    ///   - endingAt: End of the reporting period
    ///   - bucketWidth: Aggregation bucket size ("1h", "1d", "1w", "1mo")
    /// - Returns: Usage report response
    func fetchUsageReport(
        startingAt: Date,
        endingAt: Date,
        bucketWidth: String = "1d"
    ) async throws -> AdminUsageResponse {
        guard let adminKey = try? keychain.get(keychainKey) else {
            throw AdminAPIError.notConfigured
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        guard var components = URLComponents(string: "\(baseURL)/usage_report/messages") else {
            throw AdminAPIError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "starting_at", value: formatter.string(from: startingAt)),
            URLQueryItem(name: "ending_at", value: formatter.string(from: endingAt)),
            URLQueryItem(name: "bucket_width", value: bucketWidth),
        ]

        guard let url = components.url else {
            throw AdminAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue(adminKey, forHTTPHeaderField: "x-api-key")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AdminAPIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            return try decoder.decode(AdminUsageResponse.self, from: data)
        case 401, 403:
            throw AdminAPIError.unauthorized
        case 404:
            throw AdminAPIError.notFound
        default:
            throw AdminAPIError.serverError(httpResponse.statusCode)
        }
    }

    /// Test if the stored Admin API key is valid by making a minimal API call.
    func validateKey() async throws {
        // Fetch 1 day of data to validate key
        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-24 * 3600)
        _ = try await fetchUsageReport(startingAt: startDate, endingAt: endDate, bucketWidth: "1d")
    }

    // MARK: - Errors

    enum AdminAPIError: LocalizedError, Sendable {
        case notConfigured
        case invalidKeyFormat
        case invalidURL
        case invalidResponse
        case unauthorized
        case notFound
        case serverError(Int)

        var errorDescription: String? {
            switch self {
            case .notConfigured:
                return "Admin API not configured"
            case .invalidKeyFormat:
                return "Invalid key format. Admin API keys start with 'sk-ant-admin'"
            case .invalidURL:
                return "Invalid API URL"
            case .invalidResponse:
                return "Invalid response from server"
            case .unauthorized:
                return "Unauthorized. Check your Admin API key."
            case .notFound:
                return "Organization not found. Admin API requires organization admin access."
            case .serverError(let code):
                return "Server error (\(code))"
            }
        }
    }
}
