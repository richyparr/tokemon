import SwiftUI

/// Banner shown in popover when an update is available.
/// Displays version and button to download.
struct UpdateBannerView: View {
    @Environment(UpdateManager.self) private var updateManager

    var body: some View {
        if updateManager.updateAvailable {
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Update Available")
                        .font(.subheadline.weight(.medium))
                    if let version = updateManager.availableVersion {
                        Text("Version \(version)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button("Update") {
                    updateManager.downloadUpdate()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(12)
            .background(.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}
