import SwiftUI
import AppKit

/// Main popover layout displayed when clicking the menu bar icon.
/// Composes UsageHeaderView, UsageDetailView, ErrorBannerView, and RefreshStatusView
/// into a cohesive popover with comfortable density.
struct PopoverContentView: View {
    @Environment(UsageMonitor.self) private var monitor

    var body: some View {
        VStack(spacing: 16) {
            // Big percentage number (dominant, first thing user sees)
            UsageHeaderView(usage: monitor.currentUsage)

            Divider()

            // Detail breakdown: reset time, usage windows (OAuth) or token counts (JSONL)
            UsageDetailView(usage: monitor.currentUsage, showExtraUsage: monitor.showExtraUsage)

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

            // Footer: refresh status + actions
            HStack {
                RefreshStatusView(
                    isRefreshing: monitor.isRefreshing,
                    lastUpdated: monitor.lastUpdated
                )

                Spacer()

                // Refresh button
                Button {
                    Task { await monitor.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Refresh Now")

                // Settings/More menu - combines settings and quit
                Menu {
                    Button("Settings...") {
                        openSettingsWindow()
                    }
                    .keyboardShortcut(",", modifiers: .command)

                    Divider()

                    Button("Quit ClaudeMon") {
                        NSApplication.shared.terminate(nil)
                    }
                    .keyboardShortcut("q", modifiers: .command)
                } label: {
                    Image(systemName: "gear")
                        .foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 20)
                .help("Settings & Options")
            }
        }
        .padding(16)
        .frame(width: 320)
    }

    /// Open settings window using our custom controller
    private func openSettingsWindow() {
        SettingsWindowController.shared.showSettings()
    }
}
