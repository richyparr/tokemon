import SwiftUI

/// Main analytics container view for the Settings > Analytics tab.
/// Displays extended history chart, usage summaries, project breakdown, and export buttons.
struct AnalyticsDashboardView: View {
    @Environment(UsageMonitor.self) private var monitor

    @State private var isExporting = false
    @State private var isCopied = false
    @State private var pendingExportFormat: ExportFormat?

    var body: some View {
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
            .sheet(item: $pendingExportFormat) { format in
                ExportDialogView(
                    format: format,
                    onExport: { config, progress in
                        let success = await performConfiguredExport(config, progress: progress)
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
                    format: .pdf
                )

                // CSV Export Button
                exportButton(
                    title: "Export CSV Data",
                    icon: "tablecells",
                    format: .csv
                )

                // Share Card Button
                exportButton(
                    title: isCopied ? "Copied!" : "Share Usage Card",
                    icon: isCopied ? "checkmark" : "photo.fill",
                    format: .card
                )

                if isExporting {
                    ProgressView()
                        .controlSize(.small)
                }
            }
        }
    }

    /// A single export button.
    @ViewBuilder
    private func exportButton(title: String, icon: String, format: ExportFormat) -> some View {
        Button {
            pendingExportFormat = format
        } label: {
            Label(title, systemImage: icon)
        }
        .buttonStyle(.glass)
        .controlSize(.regular)
        .disabled(isExporting)
    }

    // MARK: - Export Actions

    private func performConfiguredExport(_ config: ExportConfig, progress: @escaping (ExportProgress) -> Void) async -> Bool {
        switch config.format {
        case .pdf:
            return await performPDFExport(config: config, progress: progress)
        case .csv:
            return await performCSVExport(config: config, progress: progress)
        case .card:
            return await performCardCopy(config: config, progress: progress)
        }
    }

    private func performPDFExport(config: ExportConfig, progress: @escaping (ExportProgress) -> Void) async -> Bool {
        isExporting = true
        defer { isExporting = false }

        let range = config.dateRange

        var adminUsageData: AdminUsageResponse? = nil
        var adminCostData: AdminCostResponse? = nil
        var localWeeklySummaries: [UsageSummary] = []
        var localMonthlySummaries: [UsageSummary] = []
        var localProjectBreakdown: [ProjectUsage] = []

        if config.source == .organization {
            let estPages = config.estimatedPages
            let totalSteps = estPages * 2 + 2

            do {
                progress(.fetching(step: "Fetching usage data...", current: 0, total: totalSteps))
                adminUsageData = try await AdminAPIClient.shared.fetchAllUsageData(
                    startingAt: range.start,
                    endingAt: range.end,
                    bucketWidth: "1d"
                ) { page in
                    progress(.fetching(
                        step: "Fetching usage data (page \(page))...",
                        current: page,
                        total: totalSteps
                    ))
                }

                progress(.fetching(step: "Fetching cost data...", current: estPages, total: totalSteps))
                adminCostData = try await AdminAPIClient.shared.fetchAllCostData(
                    startingAt: range.start,
                    endingAt: range.end,
                    bucketWidth: "1d"
                ) { page in
                    progress(.fetching(
                        step: "Fetching cost data (page \(page))...",
                        current: estPages + page,
                        total: totalSteps
                    ))
                }
            } catch {
                print("[Export] Failed to fetch Admin API data: \(error)")
                return false
            }
        } else {
            progress(.fetching(step: "Preparing local data...", current: 1, total: 3))
            let filteredHistory = monitor.usageHistory.filter { point in
                point.timestamp >= range.start && point.timestamp <= range.end
            }
            localWeeklySummaries = AnalyticsEngine.weeklySummaries(from: filteredHistory)
            localMonthlySummaries = AnalyticsEngine.monthlySummaries(from: filteredHistory)
            localProjectBreakdown = AnalyticsEngine.projectBreakdown(since: range.start)
        }

        progress(.generating("Generating PDF..."))

        let accountName = config.source == .organization ? "Organization" : NSUserName()
        let pages = PDFReportBuilder.buildPages(
            accountName: accountName,
            generatedDate: Date(),
            config: config,
            adminUsageData: adminUsageData,
            adminCostData: adminCostData,
            localWeeklySummaries: localWeeklySummaries,
            localMonthlySummaries: localMonthlySummaries,
            localProjectBreakdown: localProjectBreakdown
        )

        progress(.saving())

        return await ExportManager.exportMultiPagePDF(
            pages: pages,
            suggestedFilename: config.suggestedFilename
        )
    }

    private func performCSVExport(config: ExportConfig, progress: @escaping (ExportProgress) -> Void) async -> Bool {
        isExporting = true
        defer { isExporting = false }

        let range = config.dateRange

        if config.source == .organization {
            let estPages = config.estimatedPages
            let totalSteps = estPages * 2 + 1

            do {
                progress(.fetching(step: "Fetching usage data...", current: 0, total: totalSteps))
                let usageResponse = try await AdminAPIClient.shared.fetchAllUsageData(
                    startingAt: range.start,
                    endingAt: range.end,
                    bucketWidth: "1d"
                ) { page in
                    progress(.fetching(step: "Fetching usage data (page \(page))...", current: page, total: totalSteps))
                }

                progress(.fetching(step: "Fetching cost data...", current: estPages, total: totalSteps))
                let costResponse = try await AdminAPIClient.shared.fetchAllCostData(
                    startingAt: range.start,
                    endingAt: range.end,
                    bucketWidth: "1d"
                ) { page in
                    progress(.fetching(step: "Fetching cost data (page \(page))...", current: estPages + page, total: totalSteps))
                }

                progress(.saving())

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
            progress(.fetching(step: "Preparing local data...", current: 1, total: 2))
            let filteredHistory = monitor.usageHistory.filter { point in
                point.timestamp >= range.start && point.timestamp <= range.end
            }
            progress(.saving())
            return await ExportManager.exportCSV(
                from: filteredHistory,
                suggestedFilename: config.suggestedFilename
            )
        }
    }

    private func performCardCopy(config: ExportConfig, progress: @escaping (ExportProgress) -> Void) async -> Bool {
        let range = config.dateRange

        if config.source == .organization {
            do {
                progress(.fetching(step: "Fetching usage data...", current: 0, total: 2))
                let usageResponse = try await AdminAPIClient.shared.fetchAllUsageData(
                    startingAt: range.start,
                    endingAt: range.end,
                    bucketWidth: "1d"
                ) { page in
                    progress(.fetching(step: "Fetching usage data (page \(page))...", current: page, total: page + 1))
                }

                progress(.generating("Creating card..."))
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
