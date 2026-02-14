import SwiftUI
import AppKit

/// Manages a standalone settings window for LSUIElement apps where
/// SwiftUI's Settings scene doesn't work reliably.
@MainActor
final class SettingsWindowController {
    static let shared = SettingsWindowController()

    private var window: NSWindow?
    private var monitor: UsageMonitor?
    private var alertManager: AlertManager?
    private var themeManager: ThemeManager?

    private init() {}

    /// Set the monitor reference (call from app startup)
    func setMonitor(_ monitor: UsageMonitor) {
        self.monitor = monitor
    }

    /// Set the alert manager reference (call from app startup)
    func setAlertManager(_ manager: AlertManager) {
        self.alertManager = manager
    }

    /// Set the theme manager reference (call from app startup)
    func setThemeManager(_ manager: ThemeManager) {
        self.themeManager = manager
    }

    /// Show the settings window, creating it if necessary
    func showSettings() {
        if let existingWindow = window {
            // Window exists - just show and activate it
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Create new settings window
        guard let monitor = monitor else {
            print("[ClaudeMon] Error: Monitor not set for settings window")
            return
        }

        guard let alertManager = alertManager else {
            print("[ClaudeMon] Error: AlertManager not set for settings window")
            return
        }

        guard let themeManager = themeManager else {
            print("[ClaudeMon] Error: ThemeManager not set for settings window")
            return
        }

        let settingsView = SettingsView()
            .environment(monitor)
            .environment(alertManager)
            .environment(themeManager)

        let hostingController = NSHostingController(rootView: settingsView)

        let newWindow = NSWindow(contentViewController: hostingController)
        newWindow.title = "ClaudeMon Settings"
        newWindow.styleMask = [.titled, .closable]
        newWindow.setContentSize(NSSize(width: 450, height: 300))
        newWindow.center()
        newWindow.isReleasedWhenClosed = false

        // Set window level to float above other windows
        newWindow.level = .floating

        self.window = newWindow

        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
