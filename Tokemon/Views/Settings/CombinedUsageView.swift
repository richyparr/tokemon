import SwiftUI

/// Displays aggregated usage across all accounts.
/// Shows per-account breakdown with parallel data fetching.
struct CombinedUsageView: View {
    @Environment(AccountManager.self) private var accountManager

    @State private var accountUsages: [UUID: UsageSnapshot] = [:]
    @State private var isLoading = false
    @State private var fetchError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Combined Usage")
                    .font(.headline)
                Spacer()
                Button {
                    Task { await fetchAllUsage() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .disabled(isLoading)
            }

            if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Loading...")
                        .foregroundStyle(.secondary)
                }
            } else if let error = fetchError {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            } else if accountUsages.isEmpty {
                Text("No usage data available")
                    .foregroundStyle(.secondary)
            } else {
                // Per-account breakdown
                ForEach(accountManager.accounts) { account in
                    if let usage = accountUsages[account.id] {
                        HStack {
                            Circle()
                                .fill(Color(nsColor: GradientColors.color(for: usage.primaryPercentage)))
                                .frame(width: 8, height: 8)

                            Text(account.displayName)
                                .lineLimit(1)

                            Spacer()

                            Text("\(Int(usage.primaryPercentage))%")
                                .monospacedDigit()
                                .foregroundStyle(Color(nsColor: GradientColors.color(for: usage.primaryPercentage)))
                        }
                    }
                }

                Divider()

                // Summary row
                HStack {
                    Text(summaryLabel)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(Int(summaryValue))%")
                        .fontWeight(.medium)
                        .monospacedDigit()
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .task {
            await fetchAllUsage()
        }
    }

    private var summaryLabel: String {
        accountUsages.count > 1 ? "Highest" : "Usage"
    }

    private var summaryValue: Double {
        // Show highest usage as the headline metric
        accountUsages.values.map { $0.primaryPercentage }.max() ?? 0
    }

    private func fetchAllUsage() async {
        isLoading = true
        fetchError = nil
        defer { isLoading = false }

        await withTaskGroup(of: (UUID, UsageSnapshot?).self) { group in
            for account in accountManager.accounts {
                group.addTask {
                    do {
                        let response = try await OAuthClient.fetchUsageWithTokenRefresh(for: account)
                        return (account.id, response.toSnapshot())
                    } catch {
                        print("[CombinedUsageView] Failed to fetch for \(account.username): \(error)")
                        return (account.id, nil)
                    }
                }
            }

            var results: [UUID: UsageSnapshot] = [:]
            for await (accountId, snapshot) in group {
                if let snapshot = snapshot {
                    results[accountId] = snapshot
                }
            }
            accountUsages = results
        }

        if accountUsages.isEmpty && !accountManager.accounts.isEmpty {
            fetchError = "Failed to load usage data"
        }
    }
}
