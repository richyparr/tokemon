import Foundation

/// A single point in the usage history time series.
/// Captures the essential usage metrics at a specific moment for trend visualization.
struct UsageDataPoint: Codable, Identifiable, Sendable {
    let id: UUID
    let timestamp: Date
    let primaryPercentage: Double      // 5-hour utilization (0-100)
    let sevenDayPercentage: Double?    // 7-day utilization (optional)
    let source: String                  // "oauth" or "jsonl"

    /// Create from a UsageSnapshot
    init(from snapshot: UsageSnapshot) {
        self.id = UUID()
        self.timestamp = Date()
        self.primaryPercentage = snapshot.primaryPercentage
        self.sevenDayPercentage = snapshot.sevenDayUtilization
        self.source = snapshot.source.rawValue
    }

    /// For testing/preview
    init(id: UUID = UUID(), timestamp: Date, primaryPercentage: Double, sevenDayPercentage: Double? = nil, source: String = "oauth") {
        self.id = id
        self.timestamp = timestamp
        self.primaryPercentage = primaryPercentage
        self.sevenDayPercentage = sevenDayPercentage
        self.source = source
    }
}
