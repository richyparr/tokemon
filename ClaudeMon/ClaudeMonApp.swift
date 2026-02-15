import SwiftUI
import MenuBarExtraAccess
import AppKit
import UserNotifications

/// ClaudeMon - macOS menu bar app for monitoring Claude usage.
/// Runs as a background process (LSUIElement) with no Dock icon.
@main
struct ClaudeMonApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @State private var monitor = UsageMonitor()
    @State private var alertManager = AlertManager()
    @State private var themeManager = ThemeManager()
    @State private var licenseManager: LicenseManager
    @State private var featureAccess: FeatureAccessManager
    @State private var accountManager = AccountManager()
    @State private var isPopoverPresented = false
    @State private var statusItemManager = StatusItemManager()

    // Track whether chart is shown to adjust popover height
    @AppStorage("showUsageTrend") private var showUsageTrend: Bool = false

    init() {
        // Initialize license and feature managers together (shared dependency)
        let license = LicenseManager()
        _licenseManager = State(initialValue: license)
        _featureAccess = State(initialValue: FeatureAccessManager(licenseManager: license))

        // Set notification delegate to handle notifications while app is "active"
        // (Menu bar apps are always considered active)
        // Note: UNUserNotificationCenter requires a proper app bundle - skip when running as SPM executable
        if Bundle.main.bundleIdentifier != nil {
            UNUserNotificationCenter.current().delegate = AppDelegate.shared
        }
    }

    var body: some Scene {
        MenuBarExtra {
            PopoverContentView()
                .environment(monitor)
                .environment(alertManager)
                .environment(themeManager)
                .environment(licenseManager)
                .environment(featureAccess)
                .environment(accountManager)
                .frame(width: 320, height: showUsageTrend ? 720 : 420)
                .onAppear {
                    // Ensure status item is updated when popover appears
                    statusItemManager.update(with: monitor.currentUsage, error: monitor.error, alertLevel: alertManager.currentAlertLevel, licenseState: licenseManager.state)
                }
        } label: {
            // Fallback label -- the real rendering is done via NSStatusItem
            Text(monitor.menuBarText)
        }
        .menuBarExtraStyle(.window)
        .menuBarExtraAccess(isPresented: $isPopoverPresented) { statusItem in
            // Called once during setup -- store the reference for future updates
            statusItemManager.statusItem = statusItem
            statusItemManager.update(with: monitor.currentUsage, error: monitor.error, alertLevel: alertManager.currentAlertLevel, licenseState: licenseManager.state)

            // Initialize settings window controller with monitor, alertManager, themeManager, and licenseManager references
            SettingsWindowController.shared.setMonitor(monitor)
            SettingsWindowController.shared.setAlertManager(alertManager)
            SettingsWindowController.shared.setThemeManager(themeManager)
            SettingsWindowController.shared.setLicenseManager(licenseManager)
            SettingsWindowController.shared.setFeatureAccessManager(featureAccess)
            SettingsWindowController.shared.setAccountManager(accountManager)

            // Wire account changes to trigger UsageMonitor refresh
            accountManager.onActiveAccountChanged = { [monitor] account in
                Task { @MainActor in
                    monitor.currentAccount = account
                    await monitor.refresh()
                }
            }

            // Initialize floating window controller with references
            FloatingWindowController.shared.setMonitor(monitor)
            FloatingWindowController.shared.setAlertManager(alertManager)
            FloatingWindowController.shared.setThemeManager(themeManager)

            // Enable right-click detection on the status item button
            statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])

            // Register for monitor changes to keep the status item text current
            monitor.onUsageChanged = { [statusItemManager, alertManager, licenseManager] usage in
                Task { @MainActor in
                    statusItemManager.update(with: usage, error: monitor.error, alertLevel: alertManager.currentAlertLevel, licenseState: licenseManager.state)
                }
            }

            // Register for license state changes to update status item
            licenseManager.onStateChanged = { [statusItemManager, alertManager] state in
                Task { @MainActor in
                    statusItemManager.update(
                        with: monitor.currentUsage,
                        error: monitor.error,
                        alertLevel: alertManager.currentAlertLevel,
                        licenseState: state
                    )
                }
            }

            // Wire AlertManager to AccountManager for per-account thresholds
            alertManager.setAccountManager(accountManager)

            // Register for alert threshold checks (pass active account)
            monitor.onAlertCheck = { [alertManager, accountManager] usage in
                Task { @MainActor in
                    alertManager.checkUsage(usage, for: accountManager.activeAccount)
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
                .environment(alertManager)
                .environment(themeManager)
                .environment(licenseManager)
                .environment(featureAccess)
                .environment(accountManager)
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
    /// Shows error indicator when both sources have failed, or alert indicator for critical usage.
    /// Optionally appends license state suffix (trial days, expired badge).
    func update(with usage: UsageSnapshot, error: UsageMonitor.MonitorError?, alertLevel: AlertManager.AlertLevel = .normal, licenseState: LicenseState? = nil) {
        guard let button = statusItem?.button else { return }

        var text = usage.menuBarText

        // Append license state suffix if relevant (e.g., [3d] for trial, [!] for expired)
        if let suffix = licenseState?.menuBarSuffix {
            text = "\(text) \(suffix)"
        }

        let color: NSColor

        // Priority 1: Error indicator (both sources failed) - orange with "!"
        if case .bothSourcesFailed = error {
            text = "\(text) !"
            color = NSColor(calibratedRed: 0.9, green: 0.5, blue: 0.2, alpha: 1.0) // Warm orange -- obvious but not alarming
        }
        // Priority 2: Critical alert level (usage >= 100%) - red with "!"
        else if alertLevel == .critical {
            text = "\(text) !"
            color = NSColor(calibratedRed: 0.85, green: 0.25, blue: 0.2, alpha: 1.0) // Red -- critical warning
        }
        // Priority 3: Warning alert level (usage >= threshold) - use gradient color, no extra indicator
        else if alertLevel == .warning, usage.hasPercentage {
            color = GradientColors.color(for: usage.primaryPercentage)
        }
        // Priority 4: Normal OAuth percentage - gradient color
        else if usage.hasPercentage {
            color = GradientColors.color(for: usage.primaryPercentage)
        }
        // Priority 5: JSONL fallback - neutral color
        else if usage.source == .jsonl {
            color = NSColor.secondaryLabelColor
        }
        // Priority 6: No data - neutral color
        else {
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

        // Toggle Floating Window (Cmd+F)
        let floatingItem = NSMenuItem(
            title: FloatingWindowController.shared.isVisible ? "Hide Floating Window" : "Show Floating Window",
            action: #selector(ContextMenuActions.toggleFloatingWindow),
            keyEquivalent: "f"
        )
        floatingItem.target = actions
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

    @objc func toggleFloatingWindow() {
        FloatingWindowController.shared.toggleFloatingWindow()
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

// MARK: - App Delegate

/// NSApplicationDelegate and UNUserNotificationCenterDelegate for handling
/// notifications while the app is "active" (menu bar apps are always active).
/// Uses a shared static instance because UNUserNotificationCenter.delegate is weak.
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    static let shared = AppDelegate()

    override init() {
        super.init()
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Show notification banner even when app is "active".
    /// Menu bar apps are always considered active, so this is required.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    /// Handle notification tap - activate the app.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            NSApp.activate(ignoringOtherApps: true)
        }
        completionHandler()
    }
}
