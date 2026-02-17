import SwiftUI

/// Displays usage prediction metrics: pace indicator, time-to-limit, and projected monthly spend.
/// All values are computed from BudgetManager's observed properties and update automatically on refresh.
struct ForecastView: View {
    @Environment(BudgetManager.self) private var budgetManager

    // MARK: - Computed Forecast Values

    private var dailyRate: Double? {
        ForecastingEngine.calculateDailySpendRate(from: budgetManager.dailyCostData)
    }

    private var pace: ForecastingEngine.PaceIndicator {
        let calendar = Calendar.current
        let now = Date()
        let dayOfMonth = calendar.component(.day, from: now)
        let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30

        return ForecastingEngine.paceIndicator(
            currentSpend: budgetManager.currentMonthSpend,
            monthlyBudget: budgetManager.config.monthlyLimitDollars,
            dayOfMonth: dayOfMonth,
            daysInMonth: daysInMonth
        )
    }

    private var timeToLimitFormatted: String {
        guard let rate = dailyRate else { return "--" }
        if let seconds = ForecastingEngine.timeToLimit(
            currentSpend: budgetManager.currentMonthSpend,
            monthlyBudget: budgetManager.config.monthlyLimitDollars,
            dailyRate: rate
        ) {
            return ForecastingEngine.formatTimeToLimit(seconds)
        }
        return "--"
    }

    private var projectedMonthly: Double? {
        guard let rate = dailyRate else { return nil }
        let calendar = Calendar.current
        let now = Date()
        let dayOfMonth = calendar.component(.day, from: now)
        let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30

        return ForecastingEngine.predictedMonthlySpend(
            currentSpend: budgetManager.currentMonthSpend,
            dailyRate: rate,
            dayOfMonth: dayOfMonth,
            daysInMonth: daysInMonth
        )
    }

    private var isOverBudget: Bool {
        guard let projected = projectedMonthly else { return false }
        return projected > budgetManager.config.monthlyLimitDollars
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 3-column forecast grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                // Card 1: Pace Indicator
                forecastCard(
                    title: "Pace",
                    icon: pace.icon,
                    value: pace.rawValue,
                    color: pace.color
                )

                // Card 2: Time to Limit
                forecastCard(
                    title: "Time to Limit",
                    icon: "clock.fill",
                    value: timeToLimitFormatted,
                    color: .primary
                )

                // Card 3: Projected Monthly Spend
                forecastCard(
                    title: "Projected",
                    icon: "chart.line.uptrend.xyaxis",
                    value: projectedMonthly.map { formatCurrency($0) } ?? "--",
                    color: isOverBudget ? .red : .green
                )
            }

            // Daily rate caption
            if let rate = dailyRate {
                Text("Avg. \(formatCurrency(rate))/day")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Card View

    @ViewBuilder
    private func forecastCard(title: String, icon: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(color)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background {
            Color.secondary.opacity(0.1)
        }
        .cornerRadius(8)
    }

    // MARK: - Formatting

    private func formatCurrency(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "$%.0f", value)
        }
        return String(format: "$%.2f", value)
    }
}
