import SwiftUI

/// Displays a single team member's usage in the Team Dashboard.
/// Shows avatar, name, email, role badge, usage bar, and token count.
struct MemberUsageRow: View {
    let member: TeamMember
    let tokenCount: Int
    let orgTotal: Int
    let rank: Int

    private var usageFraction: Double {
        guard orgTotal > 0 else { return 0 }
        return Double(tokenCount) / Double(orgTotal)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Rank medal
            rankBadge

            // Avatar placeholder
            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundStyle(.secondary)

            // Name and email
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(member.name.isEmpty ? "Unknown" : member.name)
                        .font(.callout)
                        .fontWeight(.medium)

                    // Role badge
                    if member.role == "admin" {
                        Text("Admin")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.blue.opacity(0.2))
                            .foregroundStyle(.blue)
                            .cornerRadius(3)
                    }
                }

                Text(member.email)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Usage bar and count
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatTokens(tokenCount))
                    .font(.callout)
                    .fontWeight(.semibold)
                    .monospacedDigit()

                // Proportion bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.2))
                            .frame(width: geo.size.width, height: 4)
                            .cornerRadius(2)

                        Rectangle()
                            .fill(usageColor)
                            .frame(width: geo.size.width * usageFraction, height: 4)
                            .cornerRadius(2)
                    }
                }
                .frame(width: 80, height: 4)

                Text(String(format: "%.1f%%", usageFraction * 100))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var rankBadge: some View {
        switch rank {
        case 1:
            Image(systemName: "medal.fill")
                .foregroundStyle(.yellow)
                .font(.caption)
        case 2:
            Image(systemName: "medal.fill")
                .foregroundStyle(Color(white: 0.75))
                .font(.caption)
        case 3:
            Image(systemName: "medal.fill")
                .foregroundStyle(.orange)
                .font(.caption)
        default:
            Text("\(rank)")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .frame(width: 14)
        }
    }

    private var usageColor: Color {
        if usageFraction >= 0.5 {
            return .red
        } else if usageFraction >= 0.25 {
            return .orange
        }
        return .green
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
}
