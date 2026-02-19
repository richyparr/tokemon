import Foundation
@testable import tokemon

// MARK: - UsageSnapshot Test Factories

extension UsageSnapshot {

    /// OAuth snapshot at a given percentage with optional extras.
    ///
    /// - Parameters:
    ///   - percentage: The primary usage percentage (0-100+)
    ///   - fiveHour: 5-hour utilization. Defaults to same as percentage.
    ///   - sevenDay: 7-day all-models utilization (optional).
    ///   - sevenDayOpus: 7-day Opus utilization (optional).
    ///   - sevenDaySonnet: 7-day Sonnet utilization (optional).
    ///   - resetsAt: When the 5-hour window resets. Defaults to 1 hour from now.
    ///   - extraUsageEnabled: Whether extra usage billing is enabled.
    ///   - extraUsageSpentCents: Credits spent this month in cents.
    ///   - extraUsageLimitCents: Monthly spending limit in cents.
    ///   - extraUsageUtilization: Utilization percentage of monthly limit.
    /// - Returns: A configured UsageSnapshot for testing.
    static func mockOAuth(
        percentage: Double,
        fiveHour: Double? = nil,
        sevenDay: Double? = nil,
        sevenDayOpus: Double? = nil,
        sevenDaySonnet: Double? = nil,
        resetsAt: Date? = Date().addingTimeInterval(3600),
        extraUsageEnabled: Bool = false,
        extraUsageSpentCents: Double? = nil,
        extraUsageLimitCents: Int? = nil,
        extraUsageUtilization: Double? = nil
    ) -> UsageSnapshot {
        UsageSnapshot(
            primaryPercentage: percentage,
            fiveHourUtilization: fiveHour ?? percentage,
            sevenDayUtilization: sevenDay,
            sevenDayOpusUtilization: sevenDayOpus,
            sevenDaySonnetUtilization: sevenDaySonnet,
            resetsAt: resetsAt,
            sevenDayResetsAt: nil,
            sevenDaySonnetResetsAt: nil,
            source: .oauth,
            inputTokens: Int(percentage * 100),
            outputTokens: Int(percentage * 50),
            cacheCreationTokens: nil,
            cacheReadTokens: nil,
            model: nil,
            extraUsageEnabled: extraUsageEnabled,
            extraUsageMonthlyLimitCents: extraUsageLimitCents,
            extraUsageSpentCents: extraUsageSpentCents,
            extraUsageUtilization: extraUsageUtilization
        )
    }

    /// JSONL snapshot with token counts (no percentage available).
    ///
    /// - Parameters:
    ///   - inputTokens: Number of input tokens. Defaults to 5000.
    ///   - outputTokens: Number of output tokens. Defaults to 2000.
    ///   - cacheRead: Cache read tokens (optional).
    ///   - cacheCreation: Cache creation tokens (optional).
    ///   - model: Model name. Defaults to "claude-sonnet-4-20250514".
    /// - Returns: A JSONL-sourced UsageSnapshot for testing.
    static func mockJSONL(
        inputTokens: Int = 5000,
        outputTokens: Int = 2000,
        cacheRead: Int? = nil,
        cacheCreation: Int? = nil,
        model: String = "claude-sonnet-4-20250514"
    ) -> UsageSnapshot {
        UsageSnapshot(
            primaryPercentage: -1,
            fiveHourUtilization: nil,
            sevenDayUtilization: nil,
            sevenDayOpusUtilization: nil,
            sevenDaySonnetUtilization: nil,
            resetsAt: nil,
            sevenDayResetsAt: nil,
            sevenDaySonnetResetsAt: nil,
            source: .jsonl,
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            cacheCreationTokens: cacheCreation,
            cacheReadTokens: cacheRead,
            model: model,
            extraUsageEnabled: false,
            extraUsageMonthlyLimitCents: nil,
            extraUsageSpentCents: nil,
            extraUsageUtilization: nil
        )
    }

    /// OAuth snapshot with extra usage billing enabled.
    ///
    /// - Parameters:
    ///   - percentage: Primary usage percentage. Defaults to 60.
    ///   - spentCents: Credits spent in cents. Defaults to 1250 ($12.50).
    ///   - limitCents: Monthly limit in cents. Defaults to 5000 ($50).
    ///   - utilization: Utilization of monthly limit. Defaults to 25.0%.
    /// - Returns: An OAuth UsageSnapshot with extra usage enabled.
    static func mockWithExtraUsage(
        percentage: Double = 60,
        spentCents: Double = 1250,
        limitCents: Int = 5000,
        utilization: Double = 25.0
    ) -> UsageSnapshot {
        mockOAuth(
            percentage: percentage,
            extraUsageEnabled: true,
            extraUsageSpentCents: spentCents,
            extraUsageLimitCents: limitCents,
            extraUsageUtilization: utilization
        )
    }

    /// OAuth snapshot at critical level (100%+).
    static func mockCritical(
        percentage: Double = 100,
        resetsAt: Date? = Date().addingTimeInterval(1800)
    ) -> UsageSnapshot {
        mockOAuth(percentage: percentage, resetsAt: resetsAt)
    }

    /// OAuth snapshot at warning level (80-99%).
    static func mockWarning(
        percentage: Double = 85,
        resetsAt: Date? = Date().addingTimeInterval(3600)
    ) -> UsageSnapshot {
        mockOAuth(percentage: percentage, resetsAt: resetsAt)
    }

    /// OAuth snapshot with all 7-day metrics populated.
    static func mockWithSevenDay(
        percentage: Double = 50,
        sevenDay: Double = 30,
        sevenDayOpus: Double = 20,
        sevenDaySonnet: Double = 40
    ) -> UsageSnapshot {
        mockOAuth(
            percentage: percentage,
            sevenDay: sevenDay,
            sevenDayOpus: sevenDayOpus,
            sevenDaySonnet: sevenDaySonnet
        )
    }
}
