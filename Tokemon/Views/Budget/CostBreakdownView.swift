import SwiftUI

/// Displays workspace/project cost attribution as a sorted list with proportion bars.
/// Shows each workspace's cost relative to the highest-cost workspace.
struct CostBreakdownView: View {
    @Environment(BudgetManager.self) private var budgetManager

    /// Maximum cost for proportion bar calculation
    private var maxCost: Double {
        budgetManager.projectCosts.first?.cost ?? 1
    }

    /// Total cost across all workspaces
    private var totalCost: Double {
        budgetManager.projectCosts.reduce(0) { $0 + $1.cost }
    }

    var body: some View {
        if budgetManager.projectCosts.isEmpty {
            Text("No project cost data")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        } else {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Cost by Project")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("Total: \(formatCurrency(totalCost))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 4)

                ForEach(Array(budgetManager.projectCosts.enumerated()), id: \.offset) { _, entry in
                    CostRow(
                        workspaceId: entry.workspaceId,
                        cost: entry.cost,
                        maxCost: maxCost
                    )
                }
            }
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "$%.0f", value)
        }
        return String(format: "$%.2f", value)
    }
}

/// A single row in the cost breakdown list showing workspace name, cost, and proportion bar.
private struct CostRow: View {
    let workspaceId: String
    let cost: Double
    let maxCost: Double

    private var proportion: Double {
        guard maxCost > 0 else { return 0 }
        return cost / maxCost
    }

    private var displayName: String {
        workspaceId.isEmpty || workspaceId == "unknown" ? "Default" : workspaceId
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(displayName)
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Text(formatCurrency(cost))
                    .font(.callout)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            // Relative proportion bar
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.accentColor.opacity(0.3))
                    .frame(width: geometry.size.width * proportion, height: 4)
            }
            .frame(height: 4)
        }
        .padding(.vertical, 2)
    }

    private func formatCurrency(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "$%.0f", value)
        }
        return String(format: "$%.2f", value)
    }
}
