import SwiftUI

/// Visual arc gauge showing current spend vs budget limit.
/// Color changes based on utilization thresholds: green (<50%), orange (50-75%), red (>75%).
struct BudgetGaugeView: View {
    @Environment(BudgetManager.self) private var budgetManager

    /// Utilization clamped to 0-100 for the arc
    private var clampedUtilization: Double {
        min(budgetManager.budgetUtilization, 100)
    }

    /// Color based on budget utilization level
    private var gaugeColor: Color {
        let util = budgetManager.budgetUtilization
        if util >= 75 {
            return .red
        } else if util >= 50 {
            return .orange
        } else {
            return .green
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background arc (gray track)
                ArcShape(progress: 1.0)
                    .stroke(Color.secondary.opacity(0.2), style: StrokeStyle(lineWidth: 10, lineCap: .round))

                // Foreground arc (colored by utilization)
                ArcShape(progress: clampedUtilization / 100)
                    .stroke(gaugeColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .animation(.easeInOut(duration: 0.5), value: clampedUtilization)

                // Center percentage text
                VStack(spacing: 2) {
                    Text("\(Int(budgetManager.budgetUtilization))%")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(gaugeColor)

                    Text("used")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 120, height: 120)

            // Spend summary text
            Text("\(formatCurrency(budgetManager.currentMonthSpend)) spent of \(formatCurrency(budgetManager.config.monthlyLimitDollars))")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "$%.0f", value)
        }
        return String(format: "$%.2f", value)
    }
}

/// Custom arc shape for the budget gauge.
/// Draws a 270-degree sweep arc starting from the bottom-left.
private struct ArcShape: Shape {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - 5
        let startAngle = Angle(degrees: 135)
        let endAngle = Angle(degrees: 135 + 270 * progress)

        var path = Path()
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        return path
    }
}
