import SwiftUI

/// Displays organization-level aggregates for Team Dashboard.
/// Shows total tokens, total cost, active members count, and average per member.
struct TeamUsageSummaryView: View {
    let totalTokens: Int
    let totalCost: Double
    let memberCount: Int
    let period: String

    private var avgPerMember: Int {
        guard memberCount > 0 else { return 0 }
        return totalTokens / memberCount
    }

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            statCard(
                title: "Total Tokens",
                value: formatTokens(totalTokens),
                icon: "number",
                color: .blue
            )

            statCard(
                title: "Total Spent",
                value: formatCost(totalCost),
                icon: "dollarsign.circle.fill",
                color: .pink
            )

            statCard(
                title: "Active Members",
                value: "\(memberCount)",
                icon: "person.3.fill",
                color: .green
            )

            statCard(
                title: "Avg per Member",
                value: formatTokens(avgPerMember),
                icon: "chart.bar.fill",
                color: .orange
            )
        }
    }

    @ViewBuilder
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .monospacedDigit()

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.quaternary)
        .cornerRadius(8)
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

    private func formatCost(_ cost: Double) -> String {
        if cost >= 1000 {
            return String(format: "$%.0f", cost)
        } else if cost >= 1 {
            return String(format: "$%.2f", cost)
        } else if cost > 0 {
            return String(format: "$%.3f", cost)
        }
        return "$0.00"
    }
}
