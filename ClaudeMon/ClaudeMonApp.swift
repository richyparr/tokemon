import SwiftUI
import MenuBarExtraAccess
import AppKit

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
                    statusItemManager.update(with: monitor.currentUsage, error: monitor.error)
                }
        } label: {
            // Fallback label -- the real rendering is done via NSStatusItem
            Text(monitor.menuBarText)
        }
        .menuBarExtraStyle(.window)
        .menuBarExtraAccess(isPresented: $isPopoverPresented) { statusItem in
            // Called once during setup -- store the reference for future updates
            statusItemManager.statusItem = statusItem
            statusItemManager.update(with: monitor.currentUsage, error: monitor.error)

            // Initialize settings window controller with monitor reference
            SettingsWindowController.shared.setMonitor(monitor)

            // Enable right-click detection on the status item button
            statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])

            // Register for monitor changes to keep the status item text current
            monitor.onUsageChanged = { [statusItemManager] usage in
                Task { @MainActor in
                    statusItemManager.update(with: usage, error: monitor.error)
                }
            }

            // Install right-click event monitor
            statusItemManager.installRightClickMonitor(
                isPopoverPresented: $isPopoverPresented,
                monitor: monitor
            )
        }

        Settings {
            SettingsView()
                .environment(monitor)
        }
    }
}

/// Manages the NSStatusItem reference, handles appearance updates,
/// and provides right-click context menu support.
/// Stored as @State to persist across SwiftUI re-evaluations.
@MainActor
@Observable
final class StatusItemManager {
    var statusItem: NSStatusItem?

    @ObservationIgnored
    private var eventMonitor: Any?

    /// Update the status item button with the current usage data.
    /// Renders a colored percentage string for OAuth, or token count for JSONL fallback.
    /// Shows error indicator when both sources have failed.
    func update(with usage: UsageSnapshot, error: UsageMonitor.MonitorError?) {
        guard let button = statusItem?.button else { return }

        var text = usage.menuBarText
        let color: NSColor

        // Check for error indicator (both sources failed)
        if case .bothSourcesFailed = error {
            // Append a subtle warning indicator
            text = "\(text) !"
            color = NSColor(calibratedRed: 0.9, green: 0.5, blue: 0.2, alpha: 1.0) // Warm orange -- obvious but not alarming
        } else if usage.hasPercentage {
            color = GradientColors.color(for: usage.primaryPercentage)
        } else if usage.source == .jsonl {
            // JSONL fallback: use a neutral color since we have no percentage
            color = NSColor.secondaryLabelColor
        } else {
            color = NSColor.secondaryLabelColor
        }

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium),
            .foregroundColor: color,
        ]
        button.attributedTitle = NSAttributedString(string: text, attributes: attributes)
        statusItem?.length = NSStatusItem.variableLength
    }

    /// Install an event monitor for right-click on the status item.
    /// When a right-click is detected, shows a context menu instead of the popover.
    func installRightClickMonitor(
        isPopoverPresented: Binding<Bool>,
        monitor: UsageMonitor
    ) {
        // Remove any existing monitor
        if let existing = eventMonitor {
            NSEvent.removeMonitor(existing)
        }

        // Use global monitor to catch events in the menu bar area (system UI)
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.rightMouseDown, .rightMouseUp]) { [weak self] event in
            guard let self,
                  let button = self.statusItem?.button,
                  let buttonWindow = button.window else {
                return
            }

            // Get the button's frame in screen coordinates
            let buttonFrameInWindow = button.convert(button.bounds, to: nil)
            let buttonFrameOnScreen = buttonWindow.convertToScreen(buttonFrameInWindow)

            // Check if the click is within the status item's screen area
            let clickLocation = event.locationInWindow // For global events, this is screen coordinates

            // Add some tolerance for easier clicking
            let expandedFrame = buttonFrameOnScreen.insetBy(dx: -5, dy: -5)

            guard expandedFrame.contains(clickLocation) else {
                return
            }

            // Only act on mouseDown to show menu (more responsive)
            guard event.type == .rightMouseDown else { return }

            // Dismiss the popover if it's showing
            DispatchQueue.main.async {
                if isPopoverPresented.wrappedValue {
                    isPopoverPresented.wrappedValue = false
                }

                // Small delay to let popover dismiss
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.showContextMenu(monitor: monitor)
                }
            }
        }
    }

    /// Build and display the right-click context menu.
    private func showContextMenu(monitor: UsageMonitor) {
        guard let button = statusItem?.button else { return }

        let menu = NSMenu()

        // Refresh Now (Cmd+R)
        let refreshItem = NSMenuItem(title: "Refresh Now", action: #selector(ContextMenuActions.refreshNow), keyEquivalent: "r")
        let actions = ContextMenuActions(monitor: monitor)
        refreshItem.target = actions
        menu.addItem(refreshItem)

        menu.addItem(NSMenuItem.separator())

        // Open Floating Window (disabled -- Phase 4)
        let floatingItem = NSMenuItem(title: "Open Floating Window (Phase 4)", action: nil, keyEquivalent: "")
        floatingItem.isEnabled = false
        menu.addItem(floatingItem)

        // Settings... (Cmd+,)
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(ContextMenuActions.openSettings), keyEquivalent: ",")
        settingsItem.target = actions
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        // Quit ClaudeMon (Cmd+Q)
        let quitItem = NSMenuItem(title: "Quit ClaudeMon", action: #selector(ContextMenuActions.quitApp), keyEquivalent: "q")
        quitItem.target = actions
        menu.addItem(quitItem)

        // Keep the actions object alive until the menu closes
        objc_setAssociatedObject(menu, "contextMenuActions", actions, .OBJC_ASSOCIATION_RETAIN)

        // Use popUp to show the menu at the button's location
        // This properly displays the menu without needing to set statusItem.menu
        let buttonBounds = button.bounds
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: buttonBounds.height + 5), in: button)
    }
}

/// Helper class that provides @objc action targets for NSMenu items.
/// NSMenuItem requires @objc selectors, so we need this class-based helper.
@MainActor
final class ContextMenuActions: NSObject {
    private let monitor: UsageMonitor

    init(monitor: UsageMonitor) {
        self.monitor = monitor
        super.init()
    }

    @objc func refreshNow() {
        Task { @MainActor in
            await monitor.refresh()
        }
    }

    @objc func openSettings() {
        // Activate the app first (important for LSUIElement apps)
        NSApp.activate(ignoringOtherApps: true)

        // Try multiple approaches to open settings
        // Method 1: Modern macOS 14+ / Ventura+
        if #available(macOS 14.0, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }
        // Method 2: macOS 13 Ventura
        else if NSApp.responds(to: Selector(("showSettingsWindow:"))) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }
        // Method 3: Older macOS
        else if NSApp.responds(to: Selector(("showPreferencesWindow:"))) {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
        // Method 4: Keyboard shortcut simulation (Cmd+,)
        else {
            let event = NSEvent.keyEvent(
                with: .keyDown,
                location: .zero,
                modifierFlags: .command,
                timestamp: 0,
                windowNumber: 0,
                context: nil,
                characters: ",",
                charactersIgnoringModifiers: ",",
                isARepeat: false,
                keyCode: 43
            )
            if let event = event {
                NSApp.sendEvent(event)
            }
        }
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
