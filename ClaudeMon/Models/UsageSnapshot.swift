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

    /// When the current usage window resets
    var resetsAt: Date?

    /// Which data source produced this snapshot
    var source: DataSource

    // JSONL fallback fields
    var inputTokens: Int?
    var outputTokens: Int?
    var cacheCreationTokens: Int?
    var cacheReadTokens: Int?
    var model: String?

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
        resetsAt: nil,
        source: .none,
        inputTokens: nil,
        outputTokens: nil,
        cacheCreationTokens: nil,
        cacheReadTokens: nil,
        model: nil
    )

    /// Menu bar display text
    var menuBarText: String {
        if source == .none {
            return "--%"
        }
        return "\(Int(primaryPercentage))%"
    }
}
