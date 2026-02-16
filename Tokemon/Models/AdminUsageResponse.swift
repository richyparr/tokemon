import Foundation

/// Response from Anthropic Admin API /v1/organizations/usage_report/messages endpoint.
/// Provides organization-level usage data with token breakdowns.
struct AdminUsageResponse: Codable, Sendable {
    let data: [UsageBucket]
    let hasMore: Bool
    let nextPage: String?

    /// A single time bucket of usage data.
    struct UsageBucket: Codable, Sendable {
        let bucketStartTime: String
        let inputTokens: Int
        let outputTokens: Int
        let cacheCreationInputTokens: Int
        let cacheReadInputTokens: Int

        enum CodingKeys: String, CodingKey {
            case bucketStartTime = "bucket_start_time"
            case inputTokens = "input_tokens"
            case outputTokens = "output_tokens"
            case cacheCreationInputTokens = "cache_creation_input_tokens"
            case cacheReadInputTokens = "cache_read_input_tokens"
        }

        /// Total tokens in this bucket
        var totalTokens: Int {
            inputTokens + outputTokens + cacheCreationInputTokens + cacheReadInputTokens
        }
    }

    enum CodingKeys: String, CodingKey {
        case data
        case hasMore = "has_more"
        case nextPage = "next_page"
    }

    /// Calculate total tokens across all buckets
    var totalTokens: Int {
        data.reduce(0) { $0 + $1.totalTokens }
    }

    /// Calculate total input tokens
    var totalInputTokens: Int {
        data.reduce(0) { $0 + $1.inputTokens }
    }

    /// Calculate total output tokens
    var totalOutputTokens: Int {
        data.reduce(0) { $0 + $1.outputTokens }
    }
}
