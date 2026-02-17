import SwiftUI

/// Banner showing upgrade prompt for free users.
struct UpgradeBannerView: View {
    let onPurchase: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "star.fill")
                .foregroundStyle(.yellow)

            Text("Upgrade to Pro for extended analytics & export")
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
}
