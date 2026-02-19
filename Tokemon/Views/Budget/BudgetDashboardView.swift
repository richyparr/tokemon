import SwiftUI

/// Main budget dashboard with budget configuration form, gauge, and forecasting.
/// Shows budget gauge, cost breakdown by project, and usage forecasting.
/// Requires Admin API key for cost data.
struct BudgetDashboardView: View {
    @Environment(BudgetManager.self) private var budgetManager

    var body: some View {
        if !AdminAPIClient.shared.hasAdminKey() {
            // Admin API not configured
            VStack(spacing: 16) {
                Image(systemName: "building.2")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text("Admin API Required")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Connect your Anthropic Admin API key in the Admin tab to enable budget tracking and cost data.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            budgetContent
        }
    }

    // MARK: - Budget Content

    @ViewBuilder
    private var budgetContent: some View {
        @Bindable var budgetManager = budgetManager

        Form {
            // Section 1: Budget Settings
            Section {
                HStack {
                    Label("Budget Settings", systemImage: "dollarsign.gauge.chart.lefthalf.righthalf")
                        .font(.headline)
                    Spacer()
                    Button {
                        Task { await budgetManager.fetchCurrentMonthCost() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.borderless)
                    .disabled(budgetManager.isLoading)
                }

                Toggle("Enable Budget Tracking", isOn: $budgetManager.config.isEnabled)
                    .onChange(of: budgetManager.config.isEnabled) { _, _ in
                        budgetManager.saveConfig()
                    }

                if budgetManager.config.isEnabled {
                    LabeledContent("Monthly budget") {
                        HStack(spacing: 4) {
                            Text("$")
                                .foregroundStyle(.secondary)
                            TextField(
                                "",
                                value: $budgetManager.config.monthlyLimitDollars,
                                format: .number.precision(.fractionLength(2))
                            )
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                        }
                    }
                    .onChange(of: budgetManager.config.monthlyLimitDollars) { _, _ in
                        budgetManager.saveConfig()
                    }

                    Text("Alerts at 50%, 75%, 90% of budget")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Loading/Error States
            if budgetManager.isLoading {
                Section {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text("Loading cost data...")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            if let error = budgetManager.errorMessage {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                        Text(error)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Section 2: Current Month (gauge + stats)
            if budgetManager.config.isEnabled && !budgetManager.isLoading {
                Section("Current Month") {
                    VStack(spacing: 16) {
                        BudgetGaugeView()

                        // Stats row
                        HStack(spacing: 24) {
                            VStack(spacing: 2) {
                                Text(formatCurrency(budgetManager.currentMonthSpend))
                                    .font(.callout)
                                    .fontWeight(.semibold)
                                    .monospacedDigit()
                                Text("Spent")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            VStack(spacing: 2) {
                                Text(formatCurrency(max(0, budgetManager.config.monthlyLimitDollars - budgetManager.currentMonthSpend)))
                                    .font(.callout)
                                    .fontWeight(.semibold)
                                    .monospacedDigit()
                                Text("Remaining")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            VStack(spacing: 2) {
                                Text("\(daysLeftInMonth)")
                                    .font(.callout)
                                    .fontWeight(.semibold)
                                    .monospacedDigit()
                                Text("Days Left")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }

            // Section 3: Forecast
            if budgetManager.config.isEnabled && !budgetManager.dailyCostData.isEmpty {
                Section("Forecast") {
                    ForecastView()
                }
            }

            // Section 4: Cost by Project
            if budgetManager.config.isEnabled && !budgetManager.projectCosts.isEmpty {
                Section("Cost by Project") {
                    CostBreakdownView()
                }
            }
        }
        .formStyle(.grouped)
        .task {
            await budgetManager.fetchCurrentMonthCost()
        }
    }

    // MARK: - Helpers

    private var daysLeftInMonth: Int {
        let calendar = Calendar.current
        let now = Date()
        let dayOfMonth = calendar.component(.day, from: now)
        let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
        return daysInMonth - dayOfMonth
    }

    private func formatCurrency(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "$%.0f", value)
        }
        return String(format: "$%.2f", value)
    }
}
