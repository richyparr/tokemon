import SwiftUI

/// Displays organization-wide usage and cost data from the Admin API.
/// Only visible when Admin API key is configured.
struct OrgUsageView: View {
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var usageData: AdminUsageResponse?
    @State private var costData: AdminCostResponse?
    @State private var selectedPeriod: Period = .week
    @State private var showingCostInfo = false

    enum Period: String, CaseIterable {
        case week = "7 Days"
        case month = "30 Days"
        case quarter = "90 Days"

        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with period picker
            HStack {
                Label("Organization Usage", systemImage: "building.2")
                    .font(.headline)

                Spacer()

                Picker("Period", selection: $selectedPeriod) {
                    ForEach(Period.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                .onChange(of: selectedPeriod) { _, _ in
                    Task { await loadData() }
                }

                Button {
                    Task { await loadData() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .disabled(isLoading)
            }

            if isLoading {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("Loading organization data...")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else if let error = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                    Text(error)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else if let data = usageData {
                usageGrid(data, cost: costData)
            } else {
                Text("No data available")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }
        }
        .task {
            await loadData()
        }
    }

    @ViewBuilder
    private func usageGrid(_ data: AdminUsageResponse, cost: AdminCostResponse?) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            costCard(value: formatCost(cost?.totalCost))
            statCard(title: "Total Tokens", value: formatTokens(data.totalTokens), icon: "number")
            statCard(title: "Input", value: formatTokens(data.totalInputTokens), icon: "arrow.right.circle")
            statCard(title: "Output", value: formatTokens(data.totalOutputTokens), icon: "arrow.left.circle")
            statCard(title: "Cache Read", value: formatTokens(data.totalCacheReadTokens), icon: "bolt.circle")
        }
    }

    @ViewBuilder
    private func costCard(value: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 2) {
                Spacer()
                Image(systemName: "dollarsign.circle")
                    .font(.title2)
                    .foregroundStyle(.green)
                Button {
                    showingCostInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showingCostInfo, arrowEdge: .bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About Total Cost")
                            .font(.headline)
                        Text("This reflects your organization's total Anthropic billing for the selected period, including API usage and any subscription fees.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .frame(width: 280)
                }
                Spacer()
            }

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .monospacedDigit()

            Text("Total Cost")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background {
            Color.green.opacity(0.1)
        }
        .cornerRadius(8)
    }

    @ViewBuilder
    private func statCard(title: String, value: String, icon: String, highlight: Bool = false) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(highlight ? .green : .secondary)

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(highlight ? .primary : .primary)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background {
            if highlight {
                Color.green.opacity(0.1)
            } else {
                Color.secondary.opacity(0.1)
            }
        }
        .cornerRadius(8)
    }

    private func loadData() async {
        isLoading = true
        errorMessage = nil

        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-Double(selectedPeriod.days) * 24 * 3600)

        do {
            // Fetch usage and cost data in parallel
            async let usageTask = AdminAPIClient.shared.fetchUsageReport(
                startingAt: startDate,
                endingAt: endDate,
                bucketWidth: "1d"
            )
            async let costTask = AdminAPIClient.shared.fetchCostReport(
                startingAt: startDate,
                endingAt: endDate,
                bucketWidth: "1d"
            )

            usageData = try await usageTask
            costData = try await costTask
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
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

    private func formatCost(_ amount: Double?) -> String {
        guard let amount = amount else { return "—" }
        if amount >= 1000 {
            return String(format: "$%.0f", amount)
        } else if amount >= 100 {
            return String(format: "$%.1f", amount)
        }
        return String(format: "$%.2f", amount)
    }
}
