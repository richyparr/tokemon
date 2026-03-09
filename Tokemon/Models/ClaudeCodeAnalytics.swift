import Foundation

/// Response from Anthropic Admin API /v1/organizations/usage_report/claude_code endpoint.
/// Provides per-user Claude Code usage analytics with estimated costs.
struct ClaudeCodeAnalyticsResponse: Codable, Sendable {
    let data: [UserDayRecord]
    let hasMore: Bool
    let nextPage: String?

    enum CodingKeys: String, CodingKey {
        case data
        case hasMore = "has_more"
        case nextPage = "next_page"
    }

    /// A single user's analytics for one day.
    struct UserDayRecord: Codable, Sendable {
        let date: String
        let actor: Actor
        let modelBreakdown: [ModelUsage]?

        enum CodingKeys: String, CodingKey {
            case date
            case actor
            case modelBreakdown = "model_breakdown"
        }

        /// Total estimated cost in dollars across all models for this record.
        var totalEstimatedCost: Double {
            guard let breakdown = modelBreakdown else { return 0 }
            return breakdown.reduce(0) { $0 + $1.estimatedCostDollars }
        }
    }

    struct Actor: Codable, Sendable {
        let type: String
        let emailAddress: String?

        enum CodingKeys: String, CodingKey {
            case type
            case emailAddress = "email_address"
        }
    }

    struct ModelUsage: Codable, Sendable {
        let model: String
        let estimatedCost: EstimatedCost?

        enum CodingKeys: String, CodingKey {
            case model
            case estimatedCost = "estimated_cost"
        }

        /// Cost in dollars (API returns cents as a string).
        var estimatedCostDollars: Double {
            guard let cost = estimatedCost else { return 0 }
            return (Double(cost.amount) ?? 0) / 100.0
        }
    }

    struct EstimatedCost: Codable, Sendable {
        let currency: String
        let amount: String
    }
}
