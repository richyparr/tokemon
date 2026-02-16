import SwiftUI

/// Banner showing trial status in popover.
/// Appears for onTrial, trialExpired, and gracePeriod states.
struct TrialBannerView: View {
    let state: LicenseState
    let onPurchase: () -> Void

    var body: some View {
        switch state {
        case .onTrial(let days, _, _):
            trialBanner(days: days)

        case .trialExpired:
            expiredBanner

        case .gracePeriod(let days, _):
            graceBanner(days: days)

        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func trialBanner(days: Int) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "clock")
                .foregroundStyle(.blue)

            Text("Trial: \(days) day\(days == 1 ? "" : "s") remaining")
                .font(.callout)

            Spacer()

            Button("Upgrade") {
                onPurchase()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.1))
        )
    }

    private var expiredBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Trial expired")
                    .font(.callout)
                    .fontWeight(.medium)
                Text("Some features are limited")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Unlock Pro") {
                onPurchase()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.1))
        )
    }

    @ViewBuilder
    private func graceBanner(days: Int) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.yellow)

            VStack(alignment: .leading, spacing: 2) {
                Text("Subscription lapsed")
                    .font(.callout)
                    .fontWeight(.medium)
                Text("Renew within \(days) day\(days == 1 ? "" : "s") to keep Pro features")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Renew") {
                onPurchase()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.yellow.opacity(0.1))
        )
    }
}
