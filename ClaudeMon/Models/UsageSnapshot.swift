import Foundation

/// Central usage state model used by all views.
/// Represents a point-in-time snapshot of Claude usage data.
struct UsageSnapshot: Codable, Sendable {
    /// Primary usage percentage (0-100), from the 5-hour window
    var primaryPercentage: Double

    /// 5-hour utilization from OAuth endpoint
    var fiveHourUtilization: Double?

    /// 7-day utilization from OAuth endpoint
    var sevenDayUtilization: Double?

    /// 7-day Opus utilization from OAuth endpoint
    var sevenDayOpusUtilization: Double?

    /// 7-day Sonnet-only utilization from OAuth endpoint
    var sevenDaySonnetUtilization: Double?

    /// When the 5-hour usage window resets
    var resetsAt: Date?

    /// When the 7-day (all models) window resets
    var sevenDayResetsAt: Date?

    /// When the 7-day Sonnet window resets
    var sevenDaySonnetResetsAt: Date?

    /// Which data source produced this snapshot
    var source: DataSource

    // JSONL fallback fields
    var inputTokens: Int?
    var outputTokens: Int?
    var cacheCreationTokens: Int?
    var cacheReadTokens: Int?
    var model: String?

    // Extra usage (billing) fields
    /// Whether extra usage is enabled
    var extraUsageEnabled: Bool
    /// Monthly spending limit in cents (e.g., 5000 = $50)
    var extraUsageMonthlyLimitCents: Int?
    /// Credits spent this month in cents
    var extraUsageSpentCents: Double?
    /// Utilization percentage of monthly limit (0-100)
    var extraUsageUtilization: Double?

    /// Data source enum
    enum DataSource: String, Codable, Sendable {
        case oauth
        case jsonl
        case none
    }

    /// Empty snapshot with all zeros and no source
    static let empty = UsageSnapshot(
        primaryPercentage: 0,
        fiveHourUtilization: nil,
        sevenDayUtilization: nil,
        sevenDayOpusUtilization: nil,
        sevenDaySonnetUtilization: nil,
        resetsAt: nil,
        sevenDayResetsAt: nil,
        sevenDaySonnetResetsAt: nil,
        source: .none,
        inputTokens: nil,
        outputTokens: nil,
        cacheCreationTokens: nil,
        cacheReadTokens: nil,
        model: nil,
        extraUsageEnabled: false,
        extraUsageMonthlyLimitCents: nil,
        extraUsageSpentCents: nil,
        extraUsageUtilization: nil
    )

    /// Formatted extra usage spent amount (e.g., "$0.00", "$12.50")
    var formattedExtraUsageSpent: String {
        guard let cents = extraUsageSpentCents else { return "--" }
        let dollars = cents / 100.0
        return String(format: "$%.2f", dollars)
    }

    /// Formatted monthly limit (e.g., "$50")
    var formattedMonthlyLimit: String {
        guard let cents = extraUsageMonthlyLimitCents else { return "--" }
        let dollars = Double(cents) / 100.0
        return String(format: "$%.0f", dollars)
    }

    /// Whether a valid percentage is available (OAuth provides this, JSONL does not)
    var hasPercentage: Bool {
        primaryPercentage >= 0
    }

    /// Total token count across all categories
    var totalTokens: Int {
        (inputTokens ?? 0) + (outputTokens ?? 0) + (cacheCreationTokens ?? 0) + (cacheReadTokens ?? 0)
    }

    /// Formatted total token count with appropriate suffix (e.g., "12.4k", "1.2M")
    var formattedTokenCount: String {
        let total = totalTokens
        if total >= 1_000_000 {
            let millions = Double(total) / 1_000_000
            return String(format: "%.1fM", millions)
        } else if total >= 1_000 {
            let thousands = Double(total) / 1_000
            return String(format: "%.1fk", thousands)
        }
        return "\(total)"
    }

    /// Menu bar display text.
    /// Shows percentage when OAuth data is available, token count for JSONL fallback.
    var menuBarText: String {
        if source == .none {
            return "--"
        }
        if hasPercentage {
            return "\(Int(primaryPercentage))%"
        }
        // JSONL fallback: show token count
        return "\(formattedTokenCount) tok"
    }
}
