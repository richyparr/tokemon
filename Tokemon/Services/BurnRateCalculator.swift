import Foundation

/// Calculates usage burn rate and projects time-to-limit.
/// Uses a rolling window approach for stable estimates (avoids volatility pitfall from research).
struct BurnRateCalculator {

    /// Calculate burn rate (percentage per hour) from recent data points.
    /// Uses a 2-hour rolling window for stability.
    ///
    /// - Parameter points: Historical usage data points (should be sorted by timestamp)
    /// - Parameter windowHours: Rolling window size (default 2 hours per research recommendation)
    /// - Returns: Burn rate as percentage per hour, or nil if insufficient data
    static func calculateBurnRate(
        from points: [UsageDataPoint],
        windowHours: Double = 2.0
    ) -> Double? {
        let cutoff = Date().addingTimeInterval(-windowHours * 3600)
        let recentPoints = points.filter { $0.timestamp > cutoff }

        // Need at least 2 points to calculate a rate
        guard recentPoints.count >= 2,
              let first = recentPoints.first,
              let last = recentPoints.last else {
            return nil
        }

        let usageDelta = last.primaryPercentage - first.primaryPercentage
        let timeDeltaHours = last.timestamp.timeIntervalSince(first.timestamp) / 3600

        // Avoid division by zero
        guard timeDeltaHours > 0.01 else { return nil }  // At least ~36 seconds

        return usageDelta / timeDeltaHours  // % per hour
    }

    /// Project time until 100% limit at current burn rate.
    ///
    /// - Parameter currentUsage: Current usage percentage (0-100)
    /// - Parameter burnRate: Burn rate in percentage per hour
    /// - Returns: Time interval until limit, or nil if not approaching limit
    static func projectTimeToLimit(
        currentUsage: Double,
        burnRate: Double
    ) -> TimeInterval? {
        // If not burning (idle or decreasing), no limit ETA
        guard burnRate > 0.01 else { return nil }

        let remainingPercentage = 100.0 - currentUsage
        guard remainingPercentage > 0 else { return nil }  // Already at limit

        let hoursRemaining = remainingPercentage / burnRate
        return hoursRemaining * 3600  // Convert to seconds
    }

    /// Format time interval for display (e.g., "2h 30m", "45m", ">24h").
    static func formatTimeRemaining(_ seconds: TimeInterval) -> String {
        guard seconds > 0 else { return "--" }

        if seconds > 24 * 3600 {
            return ">24h"
        }

        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    /// Determine color for burn rate indicator.
    static func burnRateColor(rate: Double?) -> BurnRateLevel {
        guard let rate = rate else { return .unknown }
        if rate > 20 { return .critical }   // >20%/hr = hitting limit fast
        if rate > 10 { return .elevated }   // 10-20%/hr = moderate pace
        return .normal                       // <10%/hr = sustainable
    }

    enum BurnRateLevel {
        case normal, elevated, critical, unknown
    }
}
