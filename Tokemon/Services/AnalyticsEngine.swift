import Foundation

/// Pure computation engine for analytics aggregation.
/// All methods are static -- no state, no side effects.
/// Produces UsageSummary and ProjectUsage from raw data sources.
struct AnalyticsEngine {

    // MARK: - Weekly Summaries

    /// Aggregate usage data points into weekly summaries.
    /// - Parameters:
    ///   - points: Raw usage data points (from UsageMonitor.usageHistory)
    ///   - weeks: Number of weeks to include (default 4)
    /// - Returns: Weekly summaries sorted by period start ascending. Empty array if no data.
    static func weeklySummaries(from points: [UsageDataPoint], weeks: Int = 4) -> [UsageSummary] {
        let calendar = Calendar.current
        guard let cutoff = calendar.date(byAdding: .weekOfYear, value: -weeks, to: Date()) else {
            return []
        }

        let filtered = points.filter { $0.timestamp > cutoff }
        guard !filtered.isEmpty else { return [] }

        // Group by week interval (locale-aware week starts)
        var weekGroups: [DateInterval: [UsageDataPoint]] = [:]
        for point in filtered {
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: point.timestamp) else {
                continue
            }
            weekGroups[weekInterval, default: []].append(point)
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"

        var summaries: [UsageSummary] = []
        for (interval, groupPoints) in weekGroups {
            let percentages = groupPoints.map(\.primaryPercentage)
            let average = percentages.reduce(0, +) / Double(percentages.count)
            let peak = percentages.max() ?? 0

            let startLabel = dateFormatter.string(from: interval.start)
            let endDate = calendar.date(byAdding: .day, value: -1, to: interval.end) ?? interval.end
            let endLabel = DateFormatter().apply {
                $0.dateFormat = "d"
            }.string(from: endDate)

            let label = "\(startLabel)-\(endLabel)"

            summaries.append(UsageSummary(
                id: UUID(),
                period: interval,
                periodLabel: label,
                averageUtilization: average,
                peakUtilization: peak,
                dataPointCount: groupPoints.count
            ))
        }

        return summaries.sorted { $0.period.start < $1.period.start }
    }

    // MARK: - Monthly Summaries

    /// Aggregate usage data points into monthly summaries.
    /// - Parameters:
    ///   - points: Raw usage data points (from UsageMonitor.usageHistory)
    ///   - months: Number of months to include (default 3)
    /// - Returns: Monthly summaries sorted by period start ascending. Empty array if no data.
    static func monthlySummaries(from points: [UsageDataPoint], months: Int = 3) -> [UsageSummary] {
        let calendar = Calendar.current
        guard let cutoff = calendar.date(byAdding: .month, value: -months, to: Date()) else {
            return []
        }

        let filtered = points.filter { $0.timestamp > cutoff }
        guard !filtered.isEmpty else { return [] }

        // Group by month interval
        var monthGroups: [DateInterval: [UsageDataPoint]] = [:]
        for point in filtered {
            guard let monthInterval = calendar.dateInterval(of: .month, for: point.timestamp) else {
                continue
            }
            monthGroups[monthInterval, default: []].append(point)
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"

        var summaries: [UsageSummary] = []
        for (interval, groupPoints) in monthGroups {
            let percentages = groupPoints.map(\.primaryPercentage)
            let average = percentages.reduce(0, +) / Double(percentages.count)
            let peak = percentages.max() ?? 0

            let label = dateFormatter.string(from: interval.start)

            summaries.append(UsageSummary(
                id: UUID(),
                period: interval,
                periodLabel: label,
                averageUtilization: average,
                peakUtilization: peak,
                dataPointCount: groupPoints.count
            ))
        }

        return summaries.sorted { $0.period.start < $1.period.start }
    }

    // MARK: - Project Breakdown

    /// Compute per-project token usage from JSONL session files.
    /// Cross-account: all JSONL data on the machine is aggregated.
    /// - Parameter since: Only include sessions modified after this date.
    /// - Returns: Project usages sorted by total tokens descending. Empty array on error.
    static func projectBreakdown(since: Date) -> [ProjectUsage] {
        let projectDirs: [URL]
        do {
            projectDirs = try JSONLParser.findProjectDirectories()
        } catch {
            return []
        }

        var projects: [ProjectUsage] = []

        for projectDir in projectDirs {
            let sessionFiles = JSONLParser.findSessionFiles(in: projectDir, since: since)
            guard !sessionFiles.isEmpty else { continue }

            var totalInput = 0
            var totalOutput = 0
            var totalCacheCreation = 0
            var totalCacheRead = 0
            var sessionCount = 0

            for sessionFile in sessionFiles {
                let usage = JSONLParser.parseSession(at: sessionFile)
                totalInput += usage.inputTokens
                totalOutput += usage.outputTokens
                totalCacheCreation += usage.cacheCreationTokens
                totalCacheRead += usage.cacheReadTokens
                sessionCount += 1
            }

            let dirName = projectDir.lastPathComponent
            let decodedPath = decodeProjectPath(dirName)
            let projectName = URL(fileURLWithPath: decodedPath).lastPathComponent

            projects.append(ProjectUsage(
                id: UUID(),
                projectPath: decodedPath,
                projectName: projectName,
                inputTokens: totalInput,
                outputTokens: totalOutput,
                cacheCreationTokens: totalCacheCreation,
                cacheReadTokens: totalCacheRead,
                sessionCount: sessionCount
            ))
        }

        return projects.sorted { $0.totalTokens > $1.totalTokens }
    }

    // MARK: - Helpers

    /// Decode a Claude Code project directory name to a filesystem path.
    /// Example: "-Users-richardparr-Tokemon" -> "/Users/richardparr/Tokemon"
    static func decodeProjectPath(_ dirName: String) -> String {
        guard dirName.hasPrefix("-") else { return dirName }
        // Replace leading "-" with "/", then replace all remaining "-" with "/"
        let withoutLeading = String(dirName.dropFirst())
        return "/" + withoutLeading.replacingOccurrences(of: "-", with: "/")
    }

    /// Format a token count for display.
    /// 1,000,000+ -> "1.2M", 1,000+ -> "1.2K", else raw number.
    static func formatTokenCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            let millions = Double(count) / 1_000_000.0
            return String(format: "%.1fM", millions)
        } else if count >= 1_000 {
            let thousands = Double(count) / 1_000.0
            return String(format: "%.1fK", thousands)
        } else {
            return "\(count)"
        }
    }
}

// MARK: - DateFormatter Helper

private extension DateFormatter {
    /// Convenience for configuring a DateFormatter inline.
    func apply(_ configure: (DateFormatter) -> Void) -> DateFormatter {
        configure(self)
        return self
    }
}
