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

    /// Fetch organization usage report (single page).
    ///
    /// - Parameters:
    ///   - startingAt: Start of the reporting period
    ///   - endingAt: End of the reporting period
    ///   - bucketWidth: Aggregation bucket size ("1h", "1d", "1w", "1mo")
    ///   - page: Optional pagination token for fetching next page
    /// - Returns: Usage report response (may have hasMore=true)
    func fetchUsageReport(
        startingAt: Date,
        endingAt: Date,
        bucketWidth: String = "1d",
        page: String? = nil
    ) async throws -> AdminUsageResponse {
        guard let adminKey = try? keychain.get(keychainKey) else {
            throw AdminAPIError.notConfigured
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        guard var components = URLComponents(string: "\(baseURL)/usage_report/messages") else {
            throw AdminAPIError.invalidURL
        }

        var queryItems = [
            URLQueryItem(name: "starting_at", value: formatter.string(from: startingAt)),
            URLQueryItem(name: "ending_at", value: formatter.string(from: endingAt)),
            URLQueryItem(name: "bucket_width", value: bucketWidth),
            URLQueryItem(name: "limit", value: "31"), // Max daily buckets per request
        ]

        if let page = page {
            queryItems.append(URLQueryItem(name: "next_page", value: page))
        }

        components.queryItems = queryItems

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

    /// Fetch all usage data for a date range, handling pagination automatically.
    /// The Admin API returns at most 31 daily buckets per request, so this method
    /// loops through all pages and returns a combined response.
    ///
    /// - Parameters:
    ///   - startingAt: Start of the reporting period
    ///   - endingAt: End of the reporting period
    ///   - bucketWidth: Aggregation bucket size (default "1d")
    /// - Returns: Combined usage response with all buckets
    func fetchAllUsageData(
        startingAt: Date,
        endingAt: Date,
        bucketWidth: String = "1d"
    ) async throws -> AdminUsageResponse {
        var allBuckets: [AdminUsageResponse.UsageBucket] = []
        var nextPage: String? = nil

        repeat {
            let response = try await fetchUsageReport(
                startingAt: startingAt,
                endingAt: endingAt,
                bucketWidth: bucketWidth,
                page: nextPage
            )

            allBuckets.append(contentsOf: response.data)

            // Continue if there's more data and we have a page token
            if response.hasMore, let page = response.nextPage {
                nextPage = page
            } else {
                // No more pages or no token (defensive)
                break
            }
        } while nextPage != nil

        // Return combined response with hasMore=false
        return AdminUsageResponse(
            data: allBuckets,
            hasMore: false,
            nextPage: nil
        )
    }

    /// Test if the stored Admin API key is valid by making a minimal API call.
    func validateKey() async throws {
        // Fetch 1 day of data to validate key
        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-24 * 3600)
        _ = try await fetchUsageReport(startingAt: startDate, endingAt: endDate, bucketWidth: "1d")
    }

    /// Fetch organization cost report (single page).
    ///
    /// - Parameters:
    ///   - startingAt: Start of the reporting period
    ///   - endingAt: End of the reporting period
    ///   - bucketWidth: Aggregation bucket size ("1h", "1d", "1w", "1mo")
    ///   - page: Optional pagination token for fetching next page
    /// - Returns: Cost report response (may have hasMore=true)
    func fetchCostReport(
        startingAt: Date,
        endingAt: Date,
        bucketWidth: String = "1d",
        page: String? = nil
    ) async throws -> AdminCostResponse {
        guard let adminKey = try? keychain.get(keychainKey) else {
            throw AdminAPIError.notConfigured
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        guard var components = URLComponents(string: "\(baseURL)/cost_report") else {
            throw AdminAPIError.invalidURL
        }

        var queryItems = [
            URLQueryItem(name: "starting_at", value: formatter.string(from: startingAt)),
            URLQueryItem(name: "ending_at", value: formatter.string(from: endingAt)),
            URLQueryItem(name: "bucket_width", value: bucketWidth),
            URLQueryItem(name: "limit", value: "31"), // Max daily buckets per request
        ]

        if let page = page {
            queryItems.append(URLQueryItem(name: "next_page", value: page))
        }

        components.queryItems = queryItems

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
            return try decoder.decode(AdminCostResponse.self, from: data)
        case 401, 403:
            throw AdminAPIError.unauthorized
        case 404:
            throw AdminAPIError.notFound
        default:
            throw AdminAPIError.serverError(httpResponse.statusCode)
        }
    }

    /// Fetch all cost data for a date range, handling pagination automatically.
    /// The Admin API returns at most 31 daily buckets per request, so this method
    /// loops through all pages and returns a combined response.
    ///
    /// - Parameters:
    ///   - startingAt: Start of the reporting period
    ///   - endingAt: End of the reporting period
    ///   - bucketWidth: Aggregation bucket size (default "1d")
    /// - Returns: Combined cost response with all buckets
    func fetchAllCostData(
        startingAt: Date,
        endingAt: Date,
        bucketWidth: String = "1d"
    ) async throws -> AdminCostResponse {
        var allBuckets: [AdminCostResponse.CostBucket] = []
        var nextPage: String? = nil

        repeat {
            let response = try await fetchCostReport(
                startingAt: startingAt,
                endingAt: endingAt,
                bucketWidth: bucketWidth,
                page: nextPage
            )

            allBuckets.append(contentsOf: response.data)

            // Continue if there's more data and we have a page token
            if response.hasMore, let page = response.nextPage {
                nextPage = page
            } else {
                // No more pages or no token (defensive)
                break
            }
        } while nextPage != nil

        // Return combined response with hasMore=false
        return AdminCostResponse(
            data: allBuckets,
            hasMore: false,
            nextPage: nil
        )
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
