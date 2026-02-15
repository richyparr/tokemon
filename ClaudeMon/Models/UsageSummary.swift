import Foundation

/// A summary of usage over a period (week or month).
/// Used by AnalyticsEngine to aggregate UsageDataPoint arrays into human-readable summaries.
struct UsageSummary: Identifiable, Sendable {
    let id: UUID
    let period: DateInterval
    let periodLabel: String        // "Feb 10-16" or "February 2026"
    let averageUtilization: Double // Average 5-hour utilization %
    let peakUtilization: Double    // Highest recorded utilization %
    let dataPointCount: Int        // Number of data points in period
}
