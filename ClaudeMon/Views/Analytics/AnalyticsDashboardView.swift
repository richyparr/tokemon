import SwiftUI

/// Main analytics container view for the Settings > Analytics tab.
/// Pro-gated at the top level: shows a locked splash if not Pro,
/// otherwise displays extended history chart, usage summaries, project breakdown, and export buttons.
struct AnalyticsDashboardView: View {
    @Environment(FeatureAccessManager.self) private var featureAccess
    @Environment(UsageMonitor.self) private var monitor
    @Environment(AccountManager.self) private var accountManager

    @State private var isExporting = false
    @State private var showingPurchasePrompt = false
    @State private var isCopied = false

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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            // Pro analytics dashboard - use Form for consistent styling with other tabs
            Form {
                Section {
                    // 1. Extended History Chart
                    ExtendedHistoryChartView(dataPoints: monitor.usageHistory)
                }

                Section {
                    // 2. Usage Summaries (weekly/monthly)
                    UsageSummaryView(
                        weeklySummaries: AnalyticsEngine.weeklySummaries(from: monitor.usageHistory),
                        monthlySummaries: AnalyticsEngine.monthlySummaries(from: monitor.usageHistory)
                    )
                }

                Section {
                    // 3. Project Breakdown
                    ProjectBreakdownView()
                }

                Section {
                    // 4. Export section
                    exportSection
                }
            }
            .formStyle(.grouped)
            .scrollIndicators(.visible, axes: .vertical)
            .sheet(isPresented: $showingPurchasePrompt) {
                PurchasePromptView()
            }
        }
    }

    // MARK: - Export Section

    @ViewBuilder
    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Export", systemImage: "square.and.arrow.up")
                .font(.headline)

            HStack(spacing: 12) {
                // PDF Export Button
                exportButton(
                    title: "Export PDF Report",
                    icon: "doc.richtext",
                    feature: .exportPDF
                ) {
                    await performPDFExport()
                }

                // CSV Export Button
                exportButton(
                    title: "Export CSV Data",
                    icon: "tablecells",
                    feature: .exportCSV
                ) {
                    await performCSVExport()
                }

                // Share Card Button
                exportButton(
                    title: isCopied ? "Copied!" : "Share Usage Card",
                    icon: isCopied ? "checkmark" : "photo.fill",
                    feature: .usageCards
                ) {
                    await performCardCopy()
                }

                if isExporting {
                    ProgressView()
                        .controlSize(.small)
                }
            }
        }
    }

    /// A single export button with Pro gating.
    @ViewBuilder
    private func exportButton(title: String, icon: String, feature: ProFeature, action: @escaping () async -> Void) -> some View {
        if featureAccess.canAccess(feature) {
            Button {
                Task { await action() }
            } label: {
                Label(title, systemImage: icon)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .disabled(isExporting)
        } else {
            Button {
                showingPurchasePrompt = true
            } label: {
                Label(title, systemImage: icon)
                    .overlay(alignment: .topTrailing) {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .offset(x: 8, y: -6)
                    }
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .disabled(true)
        }
    }

    // MARK: - Export Actions

    private func performPDFExport() async {
        isExporting = true
        defer { isExporting = false }

        let weeklySummaries = AnalyticsEngine.weeklySummaries(from: monitor.usageHistory)
        let monthlySummaries = AnalyticsEngine.monthlySummaries(from: monitor.usageHistory)
        let projectBreakdown = AnalyticsEngine.projectBreakdown(since: Date().addingTimeInterval(-30 * 24 * 3600))

        let reportView = PDFReportView(
            accountName: accountManager.activeAccount?.username ?? "Default",
            generatedDate: Date(),
            weeklySummaries: weeklySummaries,
            monthlySummaries: monthlySummaries,
            projectBreakdown: projectBreakdown,
            totalDataPoints: monitor.usageHistory.count
        )

        _ = await ExportManager.exportPDF(reportView: reportView)
    }

    private func performCSVExport() async {
        isExporting = true
        defer { isExporting = false }

        _ = await ExportManager.exportCSV(from: monitor.usageHistory)
    }

    private func performCardCopy() async {
        // Get weekly summary for average utilization
        let weeklySummaries = AnalyticsEngine.weeklySummaries(from: monitor.usageHistory, weeks: 1)
        let avgUtilization = weeklySummaries.first?.averageUtilization ?? monitor.currentUsage.primaryPercentage

        // Get top project from last 7 days
        let topProject = AnalyticsEngine.projectBreakdown(since: Date().addingTimeInterval(-7 * 24 * 3600)).first

        // Build card with computed data
        let card = ShareableCardView(
            periodLabel: "This Week",
            utilizationPercentage: avgUtilization,
            topProjectName: topProject?.projectName,
            totalTokensUsed: topProject?.totalTokens,
            generatedDate: Date()
        )

        // Copy to clipboard
        if ExportManager.copyViewToClipboard(card) {
            isCopied = true
            // Reset after 2 seconds
            try? await Task.sleep(for: .seconds(2))
            isCopied = false
        }
    }
}
