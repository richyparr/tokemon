import SwiftUI

/// Main analytics container view for the Settings > Analytics tab.
/// Pro-gated at the top level: shows a locked splash if not Pro,
/// otherwise displays extended history chart, usage summaries, and project breakdown.
struct AnalyticsDashboardView: View {
    @Environment(FeatureAccessManager.self) private var featureAccess
    @Environment(UsageMonitor.self) private var monitor

    var body: some View {
        if !featureAccess.canAccess(.extendedHistory) {
            // Locked splash for non-Pro users
            VStack(spacing: 16) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text("Analytics is a Pro feature")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("View extended usage history, weekly and monthly summaries, and per-project token breakdown.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)

                Button("Upgrade to Pro") {
                    featureAccess.openPurchasePage()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .frame(maxWidth: .infinity, minHeight: 400)
        } else {
            // Pro analytics dashboard
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 1. Extended History Chart
                    ExtendedHistoryChartView(dataPoints: monitor.usageHistory)

                    Divider()

                    // 2. Usage Summaries (weekly/monthly)
                    UsageSummaryView(
                        weeklySummaries: AnalyticsEngine.weeklySummaries(from: monitor.usageHistory),
                        monthlySummaries: AnalyticsEngine.monthlySummaries(from: monitor.usageHistory)
                    )

                    Divider()

                    // 3. Project Breakdown
                    ProjectBreakdownView()

                    // 4. Spacer for export buttons (Plan 03 will add these)
                    Spacer(minLength: 16)
                }
                .padding()
            }
            .frame(minHeight: 400)
        }
    }
}
