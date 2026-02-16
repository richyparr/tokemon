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
    private var licenseManager: LicenseManager?
    private var featureAccess: FeatureAccessManager?

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

    /// Set the license manager reference (call from app startup)
    func setLicenseManager(_ manager: LicenseManager) {
        self.licenseManager = manager
    }

    /// Set the feature access manager reference (call from app startup)
    func setFeatureAccessManager(_ manager: FeatureAccessManager) {
        self.featureAccess = manager
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
            print("[Tokemon] Error: Monitor not set for settings window")
            return
        }

        guard let alertManager = alertManager else {
            print("[Tokemon] Error: AlertManager not set for settings window")
            return
        }

        guard let themeManager = themeManager else {
            print("[Tokemon] Error: ThemeManager not set for settings window")
            return
        }

        guard let licenseManager = licenseManager else {
            print("[Tokemon] Error: LicenseManager not set for settings window")
            return
        }

        guard let featureAccess = featureAccess else {
            print("[Tokemon] Error: FeatureAccessManager not set for settings window")
            return
        }

        let settingsView = SettingsView()
            .environment(monitor)
            .environment(alertManager)
            .environment(themeManager)
            .environment(licenseManager)
            .environment(featureAccess)

        let hostingController = NSHostingController(rootView: settingsView)

        let newWindow = NSWindow(contentViewController: hostingController)
        newWindow.title = "Tokemon Settings"
        newWindow.styleMask = [.titled, .closable]
        newWindow.setContentSize(NSSize(width: 450, height: 400))
        newWindow.center()
        newWindow.isReleasedWhenClosed = false

        // Set window level to float above other windows
        newWindow.level = .floating

        self.window = newWindow

        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
