import SwiftUI
import MenuBarExtraAccess
import SettingsAccess

/// ClaudeMon - macOS menu bar app for monitoring Claude usage.
/// Runs as a background process (LSUIElement) with no Dock icon.
@main
struct ClaudeMonApp: App {
    @State private var monitor = UsageMonitor()
    @State private var isPopoverPresented = false

    var body: some Scene {
        MenuBarExtra {
            PopoverContentView()
                .environment(monitor)
                .frame(width: 320, height: 400)
        } label: {
            // Fallback label -- the real rendering is done via NSStatusItem
            Text(monitor.menuBarText)
        }
        .menuBarExtraStyle(.window)
        .menuBarExtraAccess(isPresented: $isPopoverPresented) { statusItem in
            updateStatusItemAppearance(statusItem, usage: monitor.currentUsage)
        }

        Settings {
            SettingsView()
                .environment(monitor)
        }
    }

    /// Updates the NSStatusItem button with a colored percentage string.
    /// Uses monospaced digit font for stable width as numbers change.
    private func updateStatusItemAppearance(
        _ statusItem: NSStatusItem,
        usage: UsageSnapshot
    ) {
        guard let button = statusItem.button else { return }

        let percentage = Int(usage.primaryPercentage)
        let text = usage.source == .none ? "--%" : "\(percentage)%"
        let color = GradientColors.color(for: usage.primaryPercentage)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium),
            .foregroundColor: color,
        ]
        button.attributedTitle = NSAttributedString(string: text, attributes: attributes)
        statusItem.length = NSStatusItem.variableLength
    }
}
