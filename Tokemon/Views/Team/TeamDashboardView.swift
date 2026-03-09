import SwiftUI

/// Main Team Dashboard for viewing organization-wide usage.
/// Requires Admin API key. Shows aggregated stats and member list with per-user cost.
struct TeamDashboardView: View {
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var members: [TeamMember] = []
    @State private var orgTotalTokens: Int = 0
    @State private var orgTotalCost: Double = 0
    @State private var costByEmail: [String: Double] = [:]
    @State private var selectedPeriod: Period = .week

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
        if !AdminAPIClient.shared.hasAdminKey() {
            VStack(spacing: 16) {
                Image(systemName: "building.2")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text("Admin API Required")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Connect your Anthropic Admin API key in the Admin tab to view team usage data.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Form {
                Section {
                    teamHeader
                }

                Section {
                    TeamUsageSummaryView(
                        totalTokens: orgTotalTokens,
                        totalCost: orgTotalCost,
                        memberCount: members.count,
                        period: selectedPeriod.rawValue
                    )
                }

                Section("Members (\(members.count))") {
                    membersList
                }
            }
            .formStyle(.grouped)
            .task {
                await loadTeamData()
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var teamHeader: some View {
        HStack {
            Label("Team Usage", systemImage: "person.3.fill")
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
                Task { await loadTeamData() }
            }

            Button {
                Task { await loadTeamData() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .disabled(isLoading)
        }
    }

    @ViewBuilder
    private var membersList: some View {
        if isLoading {
            HStack {
                ProgressView()
                    .controlSize(.small)
                Text("Loading team data...")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        } else if members.isEmpty && errorMessage != nil {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                Text(errorMessage!)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        } else if members.isEmpty {
            Text("No team members found")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
        } else {
            ForEach(sortedMembers) { member in
                MemberRow(
                    member: member,
                    cost: costByEmail[member.email] ?? 0
                )
            }
        }
    }

    // MARK: - Computed

    private var sortedMembers: [TeamMember] {
        members.sorted { (costByEmail[$0.email] ?? 0) > (costByEmail[$1.email] ?? 0) }
    }

    // MARK: - Data Loading

    private func loadTeamData() async {
        isLoading = true
        errorMessage = nil

        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-Double(selectedPeriod.days) * 24 * 3600)

        // Fetch members first — required for the view
        do {
            members = try await AdminAPIClient.shared.fetchOrganizationMembers()
        } catch {
            errorMessage = "Failed to load members: \(error.localizedDescription)"
            isLoading = false
            return
        }

        // Fetch org usage and cost — best effort, don't block member display
        do {
            async let usageTask = AdminAPIClient.shared.fetchUsageByMember(
                startingAt: startDate,
                endingAt: endDate
            )
            async let costTask = AdminAPIClient.shared.fetchCostReport(
                startingAt: startDate,
                endingAt: endDate
            )

            let usageResponse = try await usageTask
            orgTotalTokens = usageResponse.data.reduce(0) { $0 + $1.totalTokens }

            let costResponse = try await costTask
            orgTotalCost = costResponse.totalCost
        } catch {
            // Non-fatal: members still show
        }

        isLoading = false

        // Fetch per-user cost in background — doesn't block UI
        Task {
            do {
                let costs = try await AdminAPIClient.shared.fetchClaudeCodeCostByUser(
                    startingAt: startDate,
                    endingAt: endDate
                )
                costByEmail = costs
            } catch {
                // Non-fatal: members show without cost breakdown
            }
        }
    }
}

// MARK: - Member Row

/// Displays a team member with their name, email, role, and estimated cost.
private struct MemberRow: View {
    let member: TeamMember
    let cost: Double

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(member.name.isEmpty ? "Unknown" : member.name)
                        .font(.callout)
                        .fontWeight(.medium)

                    Text(roleBadgeText)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(roleBadgeColor.opacity(0.2))
                        .foregroundStyle(roleBadgeColor)
                        .cornerRadius(3)
                }

                Text(member.email)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Per-member cost
            Text(formatCost(cost))
                .font(.callout)
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(cost > 0 ? .primary : .secondary)
        }
        .padding(.vertical, 4)
    }

    private var roleBadgeText: String {
        switch member.role {
        case "admin": return "Admin"
        case "developer": return "Developer"
        case "billing": return "Billing"
        case "claude_code_user": return "Claude Code"
        default: return "User"
        }
    }

    private var roleBadgeColor: Color {
        switch member.role {
        case "admin": return .blue
        case "developer": return .green
        case "billing": return .orange
        case "claude_code_user": return .purple
        default: return .secondary
        }
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
