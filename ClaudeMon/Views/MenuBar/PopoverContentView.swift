import SwiftUI
import SettingsAccess

/// Main popover layout displayed when clicking the menu bar icon.
/// Composes UsageHeaderView, UsageDetailView, ErrorBannerView, and RefreshStatusView
/// into a cohesive popover with comfortable density.
struct PopoverContentView: View {
    @Environment(UsageMonitor.self) private var monitor
    @Environment(\.openSettingsLegacy) private var openSettingsLegacy

    var body: some View {
        VStack(spacing: 16) {
            // Big percentage number (dominant, first thing user sees)
            UsageHeaderView(usage: monitor.currentUsage)

            Divider()

            // Detail breakdown: reset time, usage windows (OAuth) or token counts (JSONL)
            UsageDetailView(usage: monitor.currentUsage)

            Spacer(minLength: 0)

            // Error banner (if error exists)
            if let error = monitor.error {
                ErrorBannerView(
                    error: error,
                    onRetry: { monitor.manualRefresh() },
                    requiresManualRetry: monitor.requiresManualRetry
                )
            }

            Divider()

            // Footer: refresh status + settings gear
            HStack {
                RefreshStatusView(
                    isRefreshing: monitor.isRefreshing,
                    lastUpdated: monitor.lastUpdated
                )

                Spacer()

                Button {
                    try? openSettingsLegacy()
                } label: {
                    Image(systemName: "gear")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(width: 320)
    }
}
