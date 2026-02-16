import SwiftUI

/// Displays weekly or monthly usage summaries with average and peak utilization.
/// Pro-gated: requires .weeklySummary access. Shows locked state if not Pro.
struct UsageSummaryView: View {
    let weeklySummaries: [UsageSummary]
    let monthlySummaries: [UsageSummary]
    @State private var selectedPeriod: SummaryPeriod = .weekly
    @Environment(FeatureAccessManager.self) private var featureAccess

    enum SummaryPeriod: String, CaseIterable {
        case weekly = "Weekly"
        case monthly = "Monthly"
    }

    private var activeSummaries: [UsageSummary] {
        switch selectedPeriod {
        case .weekly: return weeklySummaries
        case .monthly: return monthlySummaries
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Usage Summaries")
                    .font(.headline)
                Spacer()
                if featureAccess.canAccess(.weeklySummary) {
                    Picker("", selection: $selectedPeriod) {
                        ForEach(SummaryPeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                }
            }

            if !featureAccess.canAccess(.weeklySummary) {
                // Locked state
                VStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Usage summaries are a Pro feature")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Button("Upgrade to Pro") {
                        featureAccess.openPurchasePage()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else if activeSummaries.isEmpty {
                // Empty state
                VStack(spacing: 4) {
                    Text("No data for this period")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else {
                // Summary table header
                HStack {
                    Text("Period")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Avg")
                        .frame(width: 50, alignment: .trailing)
                    Text("Peak")
                        .frame(width: 50, alignment: .trailing)
                    Text("Points")
                        .frame(width: 50, alignment: .trailing)
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Divider()

                // Summary rows
                ForEach(activeSummaries) { summary in
                    HStack {
                        Text(summary.periodLabel)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(Int(summary.averageUtilization))%")
                            .monospacedDigit()
                            .frame(width: 50, alignment: .trailing)
                        Text("\(Int(summary.peakUtilization))%")
                            .monospacedDigit()
                            .frame(width: 50, alignment: .trailing)
                        Text("\(summary.dataPointCount)")
                            .monospacedDigit()
                            .frame(width: 50, alignment: .trailing)
                    }
                    .font(.callout)
                }
            }
        }
    }
}
