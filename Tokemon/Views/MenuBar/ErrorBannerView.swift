import SwiftUI

/// Error banner with user-friendly message and "Show details" expander.
/// Appears in the popover when an error state is active.
struct ErrorBannerView: View {
    let error: UsageMonitor.MonitorError
    let onRetry: () -> Void
    let requiresManualRetry: Bool

    @State private var showingDetails = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Primary user-friendly message
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: errorIcon)
                    .font(.body)
                    .foregroundStyle(errorIconColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(userFriendlyMessage)
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    // "Show details" toggle
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showingDetails.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(showingDetails ? "Hide details" : "Show details")
                                .font(.caption)
                            Image(systemName: showingDetails ? "chevron.up" : "chevron.down")
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)

                    // Technical details (expanded)
                    if showingDetails {
                        Text(technicalDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                Spacer()
            }

            // Retry button when manual retry is required
            if requiresManualRetry {
                Button("Retry") {
                    onRetry()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.1))
        )
    }

    // MARK: - Error Messages

    private var userFriendlyMessage: String {
        switch error {
        case .oauthFailed:
            return "Using backup data source"
        case .oauthRateLimited:
            return "Reading from local session logs"
        case .jsonlFailed:
            return "Could not read local session logs"
        case .bothSourcesFailed:
            return "Unable to fetch usage data"
        case .tokenExpired:
            return "Authentication expired"
        case .insufficientScope:
            return "Re-authentication needed"
        }
    }

    private var technicalDescription: String {
        switch error {
        case .oauthFailed(let msg):
            return msg
        case .oauthRateLimited:
            return "The usage API is rate limited during active Claude Code sessions. Showing live token counts from session logs. Percentages will resume when the session ends."
        case .jsonlFailed(let msg):
            return msg
        case .bothSourcesFailed(let msg):
            return msg
        case .tokenExpired:
            return "OAuth access token has expired. Please re-open Claude Code to refresh credentials."
        case .insufficientScope:
            return "Claude Code needs to be re-authenticated with /login to grant usage data access."
        }
    }

    private var errorIcon: String {
        switch error {
        case .bothSourcesFailed:
            return "exclamationmark.triangle.fill"
        case .tokenExpired, .insufficientScope:
            return "key.fill"
        case .oauthRateLimited:
            return "bolt.fill"
        default:
            return "info.circle.fill"
        }
    }

    private var errorIconColor: Color {
        switch error {
        case .bothSourcesFailed:
            return .orange
        case .tokenExpired, .insufficientScope:
            return .yellow
        case .oauthRateLimited:
            return .green
        default:
            return .blue
        }
    }
}
