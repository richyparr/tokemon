import SwiftUI
import AppKit

/// Error banner with user-friendly message and "Show details" expander.
/// Appears in the popover when an error state is active.
struct ErrorBannerView: View {
    let error: UsageMonitor.MonitorError
    let onRetry: () -> Void
    let requiresManualRetry: Bool

    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingDetails = false

    private var themeColors: ThemeColors {
        themeManager.colors(for: colorScheme)
    }

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
                .buttonStyle(.glassProminent)
                .controlSize(.small)
            }

            // Direct recovery action for the keychain ACL case.
            if case .keychainAccessDenied = error {
                HStack(spacing: 8) {
                    Button("Show Me How") {
                        startKeychainAccessRecovery(onRetry: onRetry)
                    }
                    .buttonStyle(.glassProminent)
                    .controlSize(.small)

                    Button("Retry") { onRetry() }
                        .buttonStyle(.glass)
                        .controlSize(.small)
                }
            }
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.1))
        }
    }

    // MARK: - Error Messages

    private var userFriendlyMessage: String {
        switch error {
        case .oauthFailed:
            return "Using local session logs"
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
        case .keychainAccessDenied:
            return "Tokemon needs Keychain access"
        }
    }

    private var technicalDescription: String {
        switch error {
        case .oauthFailed:
            return "The usage API is unavailable. Showing token counts from local session logs (percentages and cost data are not available). To restore full data, run /exit then /login in Claude Code to refresh credentials."
        case .oauthRateLimited:
            return "The usage API is rate limited during active Claude Code sessions. Showing live token counts from session logs. Percentages will resume when the session ends."
        case .jsonlFailed(let msg):
            return msg
        case .bothSourcesFailed(let msg):
            return msg
        case .tokenExpired:
            return "OAuth access token has expired. Run /exit then /login in Claude Code to refresh credentials."
        case .insufficientScope:
            return "Claude Code needs to be re-authenticated with /login to grant usage data access."
        case .keychainAccessDenied:
            return "Tokemon is not on the Access Control list for the 'Claude Code-credentials' keychain item. Open Keychain Access, find the entry, and add Tokemon. This usually happens after Claude Code rewrites the entry on /login."
        }
    }

    private var errorIcon: String {
        switch error {
        case .bothSourcesFailed:
            return "exclamationmark.triangle.fill"
        case .tokenExpired, .insufficientScope:
            return "key.fill"
        case .keychainAccessDenied:
            return "lock.shield.fill"
        case .oauthRateLimited:
            return "bolt.fill"
        default:
            return "info.circle.fill"
        }
    }

    private var errorIconColor: Color {
        switch error {
        case .bothSourcesFailed, .keychainAccessDenied:
            return .orange
        case .tokenExpired, .insufficientScope:
            return .yellow
        case .oauthRateLimited:
            return .green
        default:
            return .blue
        }
    }

    /// Guided keychain ACL recovery. Copies the item name to the clipboard so the
    /// user can paste it into Keychain Access search, opens Keychain Access, then
    /// shows a numbered step-by-step alert that stays on screen while they work.
    /// When they click "I've added Tokemon", we trigger Tokemon's retry path.
    private func startKeychainAccessRecovery(onRetry: @escaping () -> Void) {
        // Copy the keychain item name so step 1 is paste, not type.
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString("Claude Code-credentials", forType: .string)

        // Launch Keychain Access (resolved via LaunchServices so we don't hardcode
        // a path that moves between macOS versions).
        openKeychainAccess()

        // Bring our process forward so the alert isn't lost behind Keychain Access.
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = "Add Tokemon to Keychain Access"
        alert.informativeText = """
        Tokemon needs permission to read the 'Claude Code-credentials' keychain item. \
        This is a one-time setup — Claude Code recreates the entry on each /login and \
        you'll only need to redo this if that happens.

        I've copied 'Claude Code-credentials' to your clipboard. In the Keychain Access \
        window that just opened:

        1.  Click 'login' under Default Keychains in the sidebar.
        2.  Click the 'All Items' tab at the top (not 'My Certificates').
        3.  Paste into the search box (top right) — Cmd+V.
        4.  Right-click the entry that appears → Get Info.
        5.  Click the 'Access Control' tab.
        6.  Click the + button at the bottom of the access list.
        7.  In the picker, press Cmd+Shift+G, paste:  /Applications/Tokemon.app
        8.  Press Return, then click 'Add'.
        9.  Click 'Save Changes'. Enter your login password if asked.
        10. Click 'I've added Tokemon' below.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "I've added Tokemon — Retry")
        alert.addButton(withTitle: "Open Help Online")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        switch response {
        case .alertFirstButtonReturn:
            onRetry()
        case .alertSecondButtonReturn:
            if let helpURL = URL(string: "https://tokemon.ai/keychain-access") {
                NSWorkspace.shared.open(helpURL)
            }
        default:
            break
        }
    }

    /// Resolve and launch Keychain Access. The system path moved between macOS
    /// versions (12-14: /Applications/Utilities; 15-25: /System/Applications/Utilities;
    /// 26+: /System/Library/CoreServices/Applications), so resolve via LaunchServices
    /// using the bundle identifier and fall back to a shell `open -b` if needed.
    private func openKeychainAccess() {
        let bundleId = "com.apple.keychainaccess"
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
            return
        }
        // Fallback: spawn `open -b com.apple.keychainaccess`
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = ["-b", bundleId]
        try? task.run()
    }
}
