import SwiftUI
import MenuBarExtraAccess
import SettingsAccess

/// ClaudeMon - macOS menu bar app for monitoring Claude usage.
/// Runs as a background process (LSUIElement) with no Dock icon.
@main
struct ClaudeMonApp: App {
    @State private var monitor = UsageMonitor()
    @State private var isPopoverPresented = false
    @State private var statusItemManager = StatusItemManager()

    var body: some Scene {
        MenuBarExtra {
            PopoverContentView()
                .environment(monitor)
                .frame(width: 320, height: 400)
                .onAppear {
                    // Ensure status item is updated when popover appears
                    statusItemManager.update(with: monitor.currentUsage)
                }
        } label: {
            // Fallback label -- the real rendering is done via NSStatusItem
            Text(monitor.menuBarText)
        }
        .menuBarExtraStyle(.window)
        .menuBarExtraAccess(isPresented: $isPopoverPresented) { statusItem in
            // Called once during setup -- store the reference for future updates
            statusItemManager.statusItem = statusItem
            statusItemManager.update(with: monitor.currentUsage)
            // Register for monitor changes to keep the status item text current
            monitor.onUsageChanged = { [statusItemManager] usage in
                statusItemManager.update(with: usage)
            }
        }

        Settings {
            SettingsView()
                .environment(monitor)
        }
    }
}

/// Manages the NSStatusItem reference and handles appearance updates.
/// Stored as @State to persist across SwiftUI re-evaluations.
@MainActor
@Observable
final class StatusItemManager {
    var statusItem: NSStatusItem?

    /// Update the status item button with the current usage data.
    /// Renders a colored percentage string using monospaced digit font.
    func update(with usage: UsageSnapshot) {
        guard let button = statusItem?.button else { return }

        let percentage = Int(usage.primaryPercentage)
        let text = usage.source == .none ? "--%" : "\(percentage)%"
        let color = GradientColors.color(for: usage.primaryPercentage)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium),
            .foregroundColor: color,
        ]
        button.attributedTitle = NSAttributedString(string: text, attributes: attributes)
        statusItem?.length = NSStatusItem.variableLength
    }
}
