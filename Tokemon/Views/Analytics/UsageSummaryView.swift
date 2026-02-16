import SwiftUI

/// Displays weekly or monthly usage summaries with average and peak utilization.
/// Pro-gated: requires .weeklySummary access. Shows locked state if not Pro.
/// Uses Admin API data when available, falls back to local polling data.
struct UsageSummaryView: View {
    let weeklySummaries: [UsageSummary]
    let monthlySummaries: [UsageSummary]
    @State private var selectedPeriod: SummaryPeriod = .weekly
    @State private var adminWeeklySummaries: [AdminUsageSummary] = []
    @State private var adminMonthlySummaries: [AdminUsageSummary] = []
    @State private var isLoadingAdmin = false
    @State private var adminDataLoaded = false
    @Environment(FeatureAccessManager.self) private var featureAccess

    private var hasAdminAPI: Bool {
        AdminAPIClient.shared.hasAdminKey()
    }

    enum SummaryPeriod: String, CaseIterable {
        case weekly = "Weekly"
        case monthly = "Monthly"
    }

    /// Summary from Admin API with token counts instead of percentages
    struct AdminUsageSummary: Identifiable {
        let id = UUID()
        let periodLabel: String
        let totalTokens: Int
        let inputTokens: Int
        let outputTokens: Int
        let cacheReadTokens: Int
        let isCurrentPeriod: Bool
    }

    private var activeSummaries: [UsageSummary] {
        switch selectedPeriod {
        case .weekly: return weeklySummaries
        case .monthly: return monthlySummaries
        }
    }

    private var activeAdminSummaries: [AdminUsageSummary] {
        switch selectedPeriod {
        case .weekly: return adminWeeklySummaries
        case .monthly: return adminMonthlySummaries
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("Usage Summaries")
                    .font(.headline)

                // Data source badge
                if featureAccess.canAccess(.weeklySummary) {
                    Text(hasAdminAPI && adminDataLoaded ? "Organization" : "This Machine")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.quaternary)
                        .cornerRadius(4)
                }

                Spacer()

                if featureAccess.canAccess(.weeklySummary) {
                    Picker("", selection: $selectedPeriod) {
                        ForEach(SummaryPeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                }
            }

            if !featureAccess.canAccess(.weeklySummary) {
                // Locked state
                VStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Usage summaries are a Pro feature")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Button("Upgrade to Pro") {
                        featureAccess.openPurchasePage()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else if isLoadingAdmin {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("Loading...")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else if hasAdminAPI && adminDataLoaded {
                // Admin API data view
                adminSummaryTable
            } else if activeSummaries.isEmpty {
                // Empty state for local data
                VStack(spacing: 4) {
                    Text("No data for this period")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Text("Usage data is collected while Tokemon runs")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else {
                // Local polling data view
                localSummaryTable
            }
        }
        .task {
            if hasAdminAPI {
                await loadAdminData()
            }
        }
    }

    // MARK: - Admin API Table

    @ViewBuilder
    private var adminSummaryTable: some View {
        if activeAdminSummaries.isEmpty {
            Text("No data for this period")
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        } else {
            // Header
            HStack {
                Text("Period")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Total")
                    .frame(width: 70, alignment: .trailing)
                Text("Input")
                    .frame(width: 60, alignment: .trailing)
                Text("Output")
                    .frame(width: 60, alignment: .trailing)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Divider()

            ForEach(activeAdminSummaries) { summary in
                HStack {
                    HStack(spacing: 4) {
                        Text(summary.periodLabel)
                        if summary.isCurrentPeriod {
                            Text("•")
                                .foregroundStyle(.blue)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text(formatTokens(summary.totalTokens))
                        .monospacedDigit()
                        .frame(width: 70, alignment: .trailing)
                    Text(formatTokens(summary.inputTokens))
                        .monospacedDigit()
                        .frame(width: 60, alignment: .trailing)
                    Text(formatTokens(summary.outputTokens))
                        .monospacedDigit()
                        .frame(width: 60, alignment: .trailing)
                }
                .font(.callout)
                .foregroundStyle(summary.isCurrentPeriod ? .primary : .secondary)
            }
        }
    }

    // MARK: - Local Data Table

    @ViewBuilder
    private var localSummaryTable: some View {
        // Header
        HStack {
            Text("Period")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Avg")
                .frame(width: 50, alignment: .trailing)
            Text("Peak")
                .frame(width: 50, alignment: .trailing)
            Text("Points")
                .frame(width: 50, alignment: .trailing)
        }
        .font(.caption)
        .foregroundStyle(.secondary)

        Divider()

        ForEach(activeSummaries) { summary in
            HStack {
                Text(summary.periodLabel)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("\(Int(summary.averageUtilization))%")
                    .monospacedDigit()
                    .frame(width: 50, alignment: .trailing)
                Text("\(Int(summary.peakUtilization))%")
                    .monospacedDigit()
                    .frame(width: 50, alignment: .trailing)
                Text("\(summary.dataPointCount)")
                    .monospacedDigit()
                    .frame(width: 50, alignment: .trailing)
            }
            .font(.callout)
        }

        // Note about local data
        Text("Based on \(activeSummaries.flatMap { _ in [1] }.count > 1 ? "local polling" : "limited local") data")
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .padding(.top, 4)
    }

    // MARK: - Data Loading

    private func loadAdminData() async {
        isLoadingAdmin = true
        defer { isLoadingAdmin = false }

        let calendar = Calendar.current
        let now = Date()

        // Fetch 12 weeks of data for weekly summaries
        if let weekStart = calendar.date(byAdding: .weekOfYear, value: -12, to: now) {
            do {
                let response = try await AdminAPIClient.shared.fetchUsageReport(
                    startingAt: weekStart,
                    endingAt: now,
                    bucketWidth: "1d"
                )
                adminWeeklySummaries = aggregateToWeekly(response, calendar: calendar, now: now)
            } catch {
                // Fall back to local data
            }
        }

        // Fetch 6 months of data for monthly summaries
        if let monthStart = calendar.date(byAdding: .month, value: -6, to: now) {
            do {
                let response = try await AdminAPIClient.shared.fetchUsageReport(
                    startingAt: monthStart,
                    endingAt: now,
                    bucketWidth: "1d"
                )
                adminMonthlySummaries = aggregateToMonthly(response, calendar: calendar, now: now)
            } catch {
                // Fall back to local data
            }
        }

        adminDataLoaded = !adminWeeklySummaries.isEmpty || !adminMonthlySummaries.isEmpty
    }

    private func aggregateToWeekly(_ response: AdminUsageResponse, calendar: Calendar, now: Date) -> [AdminUsageSummary] {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMM d"

        // Parse buckets into date -> tokens mapping
        var dailyData: [(date: Date, input: Int, output: Int, cacheRead: Int)] = []
        for bucket in response.data {
            if let date = dateFormatter.date(from: bucket.startingAt) {
                dailyData.append((date, bucket.inputTokens, bucket.outputTokens, bucket.cacheReadTokens))
            }
        }

        // Group by week
        var weekGroups: [DateInterval: [(input: Int, output: Int, cacheRead: Int)]] = [:]
        for day in dailyData {
            if let weekInterval = calendar.dateInterval(of: .weekOfYear, for: day.date) {
                weekGroups[weekInterval, default: []].append((day.input, day.output, day.cacheRead))
            }
        }

        // Build summaries
        var summaries: [AdminUsageSummary] = []
        let currentWeek = calendar.dateInterval(of: .weekOfYear, for: now)

        for (interval, days) in weekGroups {
            let totalInput = days.reduce(0) { $0 + $1.input }
            let totalOutput = days.reduce(0) { $0 + $1.output }
            let totalCacheRead = days.reduce(0) { $0 + $1.cacheRead }

            let startLabel = displayFormatter.string(from: interval.start)
            let endDate = calendar.date(byAdding: .day, value: 6, to: interval.start) ?? interval.start
            displayFormatter.dateFormat = "d"
            let endLabel = displayFormatter.string(from: endDate)
            displayFormatter.dateFormat = "MMM d"

            let isCurrentPeriod = currentWeek?.start == interval.start

            summaries.append(AdminUsageSummary(
                periodLabel: "\(startLabel)-\(endLabel)",
                totalTokens: totalInput + totalOutput + totalCacheRead,
                inputTokens: totalInput,
                outputTokens: totalOutput,
                cacheReadTokens: totalCacheRead,
                isCurrentPeriod: isCurrentPeriod
            ))
        }

        return summaries.sorted { $0.periodLabel > $1.periodLabel } // Most recent first
    }

    private func aggregateToMonthly(_ response: AdminUsageResponse, calendar: Calendar, now: Date) -> [AdminUsageSummary] {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMMM yyyy"

        // Parse buckets
        var dailyData: [(date: Date, input: Int, output: Int, cacheRead: Int)] = []
        for bucket in response.data {
            if let date = dateFormatter.date(from: bucket.startingAt) {
                dailyData.append((date, bucket.inputTokens, bucket.outputTokens, bucket.cacheReadTokens))
            }
        }

        // Group by month
        var monthGroups: [DateInterval: [(input: Int, output: Int, cacheRead: Int)]] = [:]
        for day in dailyData {
            if let monthInterval = calendar.dateInterval(of: .month, for: day.date) {
                monthGroups[monthInterval, default: []].append((day.input, day.output, day.cacheRead))
            }
        }

        // Build summaries
        var summaries: [AdminUsageSummary] = []
        let currentMonth = calendar.dateInterval(of: .month, for: now)

        for (interval, days) in monthGroups {
            let totalInput = days.reduce(0) { $0 + $1.input }
            let totalOutput = days.reduce(0) { $0 + $1.output }
            let totalCacheRead = days.reduce(0) { $0 + $1.cacheRead }

            let isCurrentPeriod = currentMonth?.start == interval.start

            summaries.append(AdminUsageSummary(
                periodLabel: displayFormatter.string(from: interval.start),
                totalTokens: totalInput + totalOutput + totalCacheRead,
                inputTokens: totalInput,
                outputTokens: totalOutput,
                cacheReadTokens: totalCacheRead,
                isCurrentPeriod: isCurrentPeriod
            ))
        }

        return summaries.sorted { $0.periodLabel > $1.periodLabel } // Most recent first
    }

    private func formatTokens(_ count: Int) -> String {
        if count >= 1_000_000_000 {
            return String(format: "%.1fB", Double(count) / 1_000_000_000)
        } else if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        }
        return "\(count)"
    }
}
