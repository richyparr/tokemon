import SwiftUI

/// Main Team Dashboard for viewing organization-wide usage by member.
/// Requires Admin API key. Shows aggregated stats and per-member breakdown.
struct TeamDashboardView: View {
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var members: [TeamMember] = []
    @State private var usageByMember: [String: Int] = [:]
    @State private var orgTotalTokens: Int = 0
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
            // Admin API not configured
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
            // Team Dashboard content
            Form {
                Section {
                    teamHeader
                }

                Section {
                    TeamUsageSummaryView(
                        totalTokens: orgTotalTokens,
                        memberCount: activeMemberCount,
                        period: selectedPeriod.rawValue
                    )
                }

                Section("Members (\(activeMemberCount))") {
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
        } else if let error = errorMessage {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                Text(error)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        } else if sortedMembers.isEmpty {
            Text("No team members found")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
        } else {
            ForEach(Array(sortedMembers.enumerated()), id: \.element.id) { index, member in
                MemberUsageRow(
                    member: member,
                    tokenCount: usageByMember[member.id] ?? 0,
                    orgTotal: orgTotalTokens,
                    rank: index + 1
                )
            }
        }
    }

    // MARK: - Computed

    private var sortedMembers: [TeamMember] {
        members.sorted { (usageByMember[$0.id] ?? 0) > (usageByMember[$1.id] ?? 0) }
    }

    private var activeMemberCount: Int {
        usageByMember.values.filter { $0 > 0 }.count
    }

    // MARK: - Data Loading

    private func loadTeamData() async {
        isLoading = true
        errorMessage = nil

        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-Double(selectedPeriod.days) * 24 * 3600)

        do {
            // Fetch members and usage in parallel
            async let membersTask = AdminAPIClient.shared.fetchOrganizationMembers()
            async let usageTask = AdminAPIClient.shared.fetchUsageByMember(
                startingAt: startDate,
                endingAt: endDate
            )

            let fetchedMembers = try await membersTask
            let usageResponse = try await usageTask

            // Aggregate usage by user
            var usageMap: [String: Int] = [:]
            var totalTokens = 0

            for bucket in usageResponse.data {
                for result in bucket.results {
                    if let userId = result.userId {
                        usageMap[userId, default: 0] += result.totalTokens
                        totalTokens += result.totalTokens
                    }
                }
            }

            members = fetchedMembers
            usageByMember = usageMap
            orgTotalTokens = totalTokens

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
