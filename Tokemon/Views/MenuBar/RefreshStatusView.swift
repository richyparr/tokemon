import SwiftUI

/// Subtle refresh status indicator showing spinner during refresh
/// and always-visible "last updated" timestamp.
struct RefreshStatusView: View {
    let isRefreshing: Bool
    let lastUpdated: Date?

    var body: some View {
        HStack(spacing: 6) {
            if isRefreshing {
                ProgressView()
                    .controlSize(.small)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Text(timestampText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var timestampText: String {
        guard let lastUpdated else {
            return "Not yet updated"
        }
        return "Updated \(lastUpdated.relativeTimeString())"
    }
}
