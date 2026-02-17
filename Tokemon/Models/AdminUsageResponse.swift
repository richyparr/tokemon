import Foundation

/// Response from Anthropic Admin API /v1/organizations/usage_report/messages endpoint.
/// Provides organization-level usage data with token breakdowns.
struct AdminUsageResponse: Codable, Sendable {
    let data: [UsageBucket]
    let hasMore: Bool
    let nextPage: String?

    /// A single time bucket of usage data.
    struct UsageBucket: Codable, Sendable {
        let startingAt: String
        let endingAt: String
        let results: [UsageResult]

        enum CodingKeys: String, CodingKey {
            case startingAt = "starting_at"
            case endingAt = "ending_at"
            case results
        }

        /// Total tokens in this bucket across all results
        var totalTokens: Int {
            results.reduce(0) { $0 + $1.totalTokens }
        }

        /// Input tokens (uncached + cache creation combined for backward compatibility)
        var inputTokens: Int {
            results.reduce(0) { $0 + $1.uncachedInputTokens + $1.cacheCreationTokens }
        }

        /// Pure uncached input tokens only (excludes cache creation)
        var uncachedInputTokens: Int {
            results.reduce(0) { $0 + $1.uncachedInputTokens }
        }

        var outputTokens: Int {
            results.reduce(0) { $0 + $1.outputTokens }
        }

        var cacheReadTokens: Int {
            results.reduce(0) { $0 + $1.cacheReadInputTokens }
        }

        /// Cache creation tokens in this bucket
        var cacheCreationTokens: Int {
            results.reduce(0) { $0 + $1.cacheCreationTokens }
        }
    }

    /// A single usage result within a bucket
    struct UsageResult: Codable, Sendable {
        let uncachedInputTokens: Int
        let cacheCreation: CacheCreation?
        let cacheReadInputTokens: Int
        let outputTokens: Int
        /// User ID when grouped by user_id (only present in team usage queries)
        let userId: String?

        enum CodingKeys: String, CodingKey {
            case uncachedInputTokens = "uncached_input_tokens"
            case cacheCreation = "cache_creation"
            case cacheReadInputTokens = "cache_read_input_tokens"
            case outputTokens = "output_tokens"
            case userId = "user_id"
        }

        var cacheCreationTokens: Int {
            (cacheCreation?.ephemeral1hInputTokens ?? 0) + (cacheCreation?.ephemeral5mInputTokens ?? 0)
        }

        var totalTokens: Int {
            uncachedInputTokens + cacheCreationTokens + cacheReadInputTokens + outputTokens
        }
    }

    struct CacheCreation: Codable, Sendable {
        let ephemeral1hInputTokens: Int
        let ephemeral5mInputTokens: Int

        enum CodingKeys: String, CodingKey {
            case ephemeral1hInputTokens = "ephemeral_1h_input_tokens"
            case ephemeral5mInputTokens = "ephemeral_5m_input_tokens"
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

    /// Calculate total input tokens (uncached + cache creation)
    var totalInputTokens: Int {
        data.reduce(0) { $0 + $1.inputTokens }
    }

    /// Calculate total output tokens
    var totalOutputTokens: Int {
        data.reduce(0) { $0 + $1.outputTokens }
    }

    /// Calculate total cache read tokens
    var totalCacheReadTokens: Int {
        data.reduce(0) { $0 + $1.cacheReadTokens }
    }

    /// Calculate total cache creation tokens
    var totalCacheCreationTokens: Int {
        data.reduce(0) { $0 + $1.cacheCreationTokens }
    }

    /// Calculate total uncached input tokens only
    var totalUncachedInputTokens: Int {
        data.reduce(0) { $0 + $1.uncachedInputTokens }
    }
}

// MARK: - Cost Response

/// Response from Anthropic Admin API /v1/organizations/cost_report endpoint.
/// Provides organization-level cost data in USD.
struct AdminCostResponse: Codable, Sendable {
    let data: [CostBucket]
    let hasMore: Bool
    let nextPage: String?

    /// A single time bucket of cost data.
    struct CostBucket: Codable, Sendable {
        let startingAt: String
        let endingAt: String
        let results: [CostResult]

        enum CodingKeys: String, CodingKey {
            case startingAt = "starting_at"
            case endingAt = "ending_at"
            case results
        }

        /// Total cost in this bucket (converted from cents to dollars)
        var totalCost: Double {
            results.reduce(0) { $0 + ((Double($1.amount) ?? 0) / 100.0) }
        }
    }

    /// A single cost result within a bucket
    struct CostResult: Codable, Sendable {
        let currency: String
        let amount: String
        /// Workspace ID when grouped by workspace (only present with group_by=workspace)
        let workspaceId: String?

        enum CodingKeys: String, CodingKey {
            case currency
            case amount
            case workspaceId = "workspace_id"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            currency = try container.decode(String.self, forKey: .currency)
            amount = try container.decode(String.self, forKey: .amount)
            workspaceId = try container.decodeIfPresent(String.self, forKey: .workspaceId)
        }
    }

    enum CodingKeys: String, CodingKey {
        case data
        case hasMore = "has_more"
        case nextPage = "next_page"
    }

    /// Calculate total cost across all buckets
    var totalCost: Double {
        data.reduce(0) { $0 + $1.totalCost }
    }

    /// Currency (assumes all results use same currency)
    var currency: String {
        data.first?.results.first?.currency ?? "USD"
    }
}
