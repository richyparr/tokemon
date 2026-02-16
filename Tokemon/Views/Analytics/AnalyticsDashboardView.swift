import SwiftUI

/// Main analytics container view for the Settings > Analytics tab.
/// Pro-gated at the top level: shows a locked splash if not Pro,
/// otherwise displays extended history chart, usage summaries, project breakdown, and export buttons.
struct AnalyticsDashboardView: View {
    @Environment(FeatureAccessManager.self) private var featureAccess
    @Environment(UsageMonitor.self) private var monitor

    @State private var isExporting = false
    @State private var showingPurchasePrompt = false
    @State private var isCopied = false
    @State private var pendingExportFormat: ExportFormat?

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
                // Organization Usage (only if Admin API connected)
                if AdminAPIClient.shared.hasAdminKey() {
                    Section {
                        OrgUsageView()
                    }
                }

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
            .sheet(item: $pendingExportFormat) { format in
                ExportDialogView(
                    format: format,
                    onExport: { config in
                        let success = await performConfiguredExport(config)
                        if success {
                            pendingExportFormat = nil
                        }
                        return success
                    },
                    onCancel: {
                        pendingExportFormat = nil
                    }
                )
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
                    feature: .exportPDF,
                    format: .pdf
                )

                // CSV Export Button
                exportButton(
                    title: "Export CSV Data",
                    icon: "tablecells",
                    feature: .exportCSV,
                    format: .csv
                )

                // Share Card Button
                exportButton(
                    title: isCopied ? "Copied!" : "Share Usage Card",
                    icon: isCopied ? "checkmark" : "photo.fill",
                    feature: .usageCards,
                    format: .card
                )

                if isExporting {
                    ProgressView()
                        .controlSize(.small)
                }
            }
        }
    }

    /// A single export button with Pro gating.
    @ViewBuilder
    private func exportButton(title: String, icon: String, feature: ProFeature, format: ExportFormat) -> some View {
        if featureAccess.canAccess(feature) {
            Button {
                pendingExportFormat = format
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

    private func performConfiguredExport(_ config: ExportConfig) async -> Bool {
        switch config.format {
        case .pdf:
            return await performPDFExport(config: config)
        case .csv:
            return await performCSVExport(config: config)
        case .card:
            return await performCardCopy(config: config)
        }
    }

    private func performPDFExport(config: ExportConfig) async -> Bool {
        isExporting = true
        defer { isExporting = false }

        let range = config.dateRange

        if config.source == .organization {
            do {
                // Use paginated fetch for large date ranges
                let usageResponse = try await AdminAPIClient.shared.fetchAllUsageData(
                    startingAt: range.start,
                    endingAt: range.end,
                    bucketWidth: "1d"
                )
                let costResponse = try await AdminAPIClient.shared.fetchAllCostData(
                    startingAt: range.start,
                    endingAt: range.end,
                    bucketWidth: "1d"
                )

                let reportView = PDFReportView(
                    accountName: "Organization",
                    generatedDate: Date(),
                    adminUsageData: usageResponse,
                    adminCostData: costResponse
                )

                return await ExportManager.exportPDF(
                    reportView: reportView,
                    suggestedFilename: config.suggestedFilename
                )
            } catch {
                print("[Export] Failed to fetch Admin API data: \(error)")
                return false
            }
        } else {
            // Local data export - filter to date range
            let filteredHistory = monitor.usageHistory.filter { point in
                point.timestamp >= range.start && point.timestamp <= range.end
            }

            let weeklySummaries = AnalyticsEngine.weeklySummaries(from: filteredHistory)
            let monthlySummaries = AnalyticsEngine.monthlySummaries(from: filteredHistory)
            let projectBreakdown = AnalyticsEngine.projectBreakdown(since: range.start)

            let reportView = PDFReportView(
                accountName: NSUserName(),
                generatedDate: Date(),
                weeklySummaries: weeklySummaries,
                monthlySummaries: monthlySummaries,
                projectBreakdown: projectBreakdown,
                totalDataPoints: filteredHistory.count
            )

            return await ExportManager.exportPDF(
                reportView: reportView,
                suggestedFilename: config.suggestedFilename
            )
        }
    }

    private func performCSVExport(config: ExportConfig) async -> Bool {
        isExporting = true
        defer { isExporting = false }

        let range = config.dateRange

        if config.source == .organization {
            do {
                // Use paginated fetch for large date ranges
                let usageResponse = try await AdminAPIClient.shared.fetchAllUsageData(
                    startingAt: range.start,
                    endingAt: range.end,
                    bucketWidth: "1d"
                )
                let costResponse = try await AdminAPIClient.shared.fetchAllCostData(
                    startingAt: range.start,
                    endingAt: range.end,
                    bucketWidth: "1d"
                )

                return await ExportManager.exportAdminCSV(
                    from: usageResponse,
                    cost: costResponse,
                    config: config
                )
            } catch {
                print("[Export] Failed to fetch Admin API data: \(error)")
                return false
            }
        } else {
            // Local data export - filter to date range
            let filteredHistory = monitor.usageHistory.filter { point in
                point.timestamp >= range.start && point.timestamp <= range.end
            }
            return await ExportManager.exportCSV(
                from: filteredHistory,
                suggestedFilename: config.suggestedFilename
            )
        }
    }

    private func performCardCopy(config: ExportConfig) async -> Bool {
        let range = config.dateRange

        if config.source == .organization {
            do {
                let usageResponse = try await AdminAPIClient.shared.fetchAllUsageData(
                    startingAt: range.start,
                    endingAt: range.end,
                    bucketWidth: "1d"
                )

                let periodLabel = "\(config.datePreset.rawValue) (Org)"
                let card = ShareableCardView(
                    periodLabel: periodLabel,
                    totalTokens: usageResponse.totalTokens,
                    inputTokens: usageResponse.totalInputTokens,
                    outputTokens: usageResponse.totalOutputTokens,
                    generatedDate: Date()
                )

                let success = ExportManager.copyViewToClipboard(card)
                if success {
                    isCopied = true
                    try? await Task.sleep(for: .seconds(2))
                    isCopied = false
                }
                return success
            } catch {
                print("[Export] Failed to fetch Admin API data: \(error)")
                return false
            }
        } else {
            // Use insight-based cards for local data (auto-selects best card)
            let filteredHistory = monitor.usageHistory.filter { point in
                point.timestamp >= range.start && point.timestamp <= range.end
            }

            // Try to get the best insight card
            if let insight = InsightCalculator.bestInsight(from: filteredHistory) {
                let card = ShareableCardView(insight: insight)
                let success = ExportManager.copyViewToClipboard(card)
                if success {
                    isCopied = true
                    try? await Task.sleep(for: .seconds(2))
                    isCopied = false
                }
                return success
            } else {
                // Fallback to legacy card if no insights available (new user)
                let weeklySummaries = AnalyticsEngine.weeklySummaries(from: filteredHistory, weeks: 1)
                let avgUtilization = weeklySummaries.first?.averageUtilization ?? monitor.currentUsage.primaryPercentage
                let topProject = AnalyticsEngine.projectBreakdown(since: range.start).first

                let card = ShareableCardView(
                    periodLabel: config.datePreset.rawValue,
                    utilizationPercentage: avgUtilization,
                    topProjectName: topProject?.projectName,
                    totalTokensUsed: topProject?.totalTokens,
                    generatedDate: Date()
                )

                let success = ExportManager.copyViewToClipboard(card)
                if success {
                    isCopied = true
                    try? await Task.sleep(for: .seconds(2))
                    isCopied = false
                }
                return success
            }
        }
    }
}
