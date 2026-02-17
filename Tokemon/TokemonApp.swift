import SwiftUI
import MenuBarExtraAccess
import AppKit
import UserNotifications
import ServiceManagement

/// Tokemon - macOS menu bar app for monitoring Claude usage.
/// Runs as a background process (LSUIElement) with no Dock icon.
@main
struct TokemonApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @State private var monitor = UsageMonitor()
    @State private var alertManager = AlertManager()
    @State private var themeManager = ThemeManager()
    @State private var licenseManager: LicenseManager
    @State private var featureAccess: FeatureAccessManager
    @State private var isPopoverPresented = false
    @State private var profileManager = ProfileManager()
    @State private var statusItemManager = StatusItemManager()
    @State private var statuslineExporter = StatuslineExporter()

    // Track whether chart is shown to adjust popover height
    @AppStorage("showUsageTrend") private var showUsageTrend: Bool = false

    /// Compute popover height based on content visibility
    private var popoverHeight: CGFloat {
        // Base heights measured from actual content:
        // - Account switcher: ~24px
        // - Usage header (percentage + reset): ~90px
        // - Divider + spacing: ~24px
        // - Usage detail section (basic): ~80px
        // - Divider + spacing: ~24px
        // - Footer row: ~24px
        // - Padding: 32px (16 top + 16 bottom)
        // Total base: ~298px, round to 300
        let baseHeight: CGFloat = 300
        let trialBannerHeight: CGFloat = 56   // Trial banner actual height
        let chartHeight: CGFloat = 230        // Chart + burn rate section
        let extraUsageHeight: CGFloat = 75    // Extra usage section (divider + title + 3 rows)

        var height = baseHeight

        // Add height for profile switcher and multi-profile summary when multiple profiles exist
        if profileManager.profiles.count > 1 {
            let profileSwitcherHeight: CGFloat = 28   // Switcher dropdown
            let profileSummaryHeader: CGFloat = 32    // "All Profiles" header + divider
            let profileRowHeight: CGFloat = 24        // Per profile row
            height += profileSwitcherHeight + profileSummaryHeader + (CGFloat(profileManager.profiles.count) * profileRowHeight)
        }

        // Add height for extra usage section if shown
        if monitor.showExtraUsage && monitor.currentUsage.extraUsageEnabled {
            height += extraUsageHeight
        }

        // Add height for trial banner if needed
        if shouldShowTrialBanner {
            height += trialBannerHeight
        }

        // Add height for chart if enabled
        if showUsageTrend {
            height += chartHeight
        }

        return height
    }

    /// Whether trial banner should be shown (matches PopoverContentView logic)
    private var shouldShowTrialBanner: Bool {
        switch licenseManager.state {
        case .onTrial, .trialExpired, .gracePeriod:
            return true
        default:
            return false
        }
    }

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

        // Auto-register for launch at login on first run
        Self.setupLaunchAtLoginIfNeeded()
    }

    /// On first launch, automatically register for launch at login.
    private static func setupLaunchAtLoginIfNeeded() {
        let key = "didSetupLaunchAtLogin"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)

        do {
            try SMAppService.mainApp.register()
            print("[TokemonApp] Auto-registered for launch at login")
        } catch {
            print("[TokemonApp] Failed to auto-register for launch at login: \(error)")
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
                .environment(profileManager)
                .frame(width: 320, height: popoverHeight)
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
            statusItemManager.registerForStyleChanges()
            statusItemManager.update(with: monitor.currentUsage, error: monitor.error, alertLevel: alertManager.currentAlertLevel, licenseState: licenseManager.state)

            // Initialize settings window controller with monitor, alertManager, themeManager, and licenseManager references
            SettingsWindowController.shared.setMonitor(monitor)
            SettingsWindowController.shared.setAlertManager(alertManager)
            SettingsWindowController.shared.setThemeManager(themeManager)
            SettingsWindowController.shared.setLicenseManager(licenseManager)
            SettingsWindowController.shared.setFeatureAccessManager(featureAccess)
            SettingsWindowController.shared.setProfileManager(profileManager)

            // Wire ProfileManager to UsageMonitor for multi-profile polling
            monitor.profileManager = profileManager

            // Wire profile change callback to trigger a UsageMonitor refresh
            profileManager.onActiveProfileChanged = { [monitor] _ in
                Task { @MainActor in
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

            // Register for alert threshold checks
            monitor.onAlertCheck = { [alertManager] usage in
                Task { @MainActor in
                    alertManager.checkUsage(usage)
                }
            }

            // Wire statusline export to refresh cycle
            monitor.onStatuslineExport = { [statuslineExporter] usage in
                statuslineExporter.export(usage)
            }

            // Listen for statusline config changes to reload exporter settings
            NotificationCenter.default.addObserver(
                forName: StatuslineExporter.configChangedNotification,
                object: nil,
                queue: .main
            ) { _ in
                Task { @MainActor in
                    statuslineExporter.reloadConfig()
                    // Re-export with current data to immediately reflect format changes
                    statuslineExporter.export(monitor.currentUsage)
                }
            }

            // Copy shell helper script to ~/.tokemon/ for user access
            statuslineExporter.installShellHelper()

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
                .environment(profileManager)
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

    /// Current icon style -- read from UserDefaults
    @ObservationIgnored
    private var currentStyle: MenuBarIconStyle = {
        if let raw = UserDefaults.standard.string(forKey: "menuBarIconStyle"),
           let style = MenuBarIconStyle(rawValue: raw) {
            return style
        }
        return .percentage
    }()

    /// Whether monochrome mode is enabled -- read from UserDefaults
    @ObservationIgnored
    private var isMonochrome: Bool = UserDefaults.standard.bool(forKey: "menuBarMonochrome")

    /// Last update parameters for re-rendering when settings change
    @ObservationIgnored
    private var lastUsage: UsageSnapshot = .empty
    @ObservationIgnored
    private var lastError: UsageMonitor.MonitorError?
    @ObservationIgnored
    private var lastAlertLevel: AlertManager.AlertLevel = .normal
    @ObservationIgnored
    private var lastLicenseState: LicenseState?

    /// Style change notification observer
    @ObservationIgnored
    private var styleChangeObserver: NSObjectProtocol?

    /// Notification posted when menu bar style or monochrome setting changes
    static let styleChangedNotification = Notification.Name("MenuBarStyleChanged")

    /// Re-read style and monochrome settings from UserDefaults
    func reloadSettings() {
        if let raw = UserDefaults.standard.string(forKey: "menuBarIconStyle"),
           let style = MenuBarIconStyle(rawValue: raw) {
            currentStyle = style
        } else {
            currentStyle = .percentage
        }
        isMonochrome = UserDefaults.standard.bool(forKey: "menuBarMonochrome")
    }

    /// Register for style change notifications so the menu bar re-renders when settings change
    func registerForStyleChanges() {
        guard styleChangeObserver == nil else { return }
        styleChangeObserver = NotificationCenter.default.addObserver(
            forName: Self.styleChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.reloadSettings()
                self.update(with: self.lastUsage, error: self.lastError, alertLevel: self.lastAlertLevel, licenseState: self.lastLicenseState)
            }
        }
    }

    /// Update the status item button with the current usage data.
    /// Uses MenuBarIconRenderer to produce the appropriate visual output for the selected style.
    /// Shows error indicator when both sources have failed, or alert indicator for critical usage.
    /// Optionally appends license state suffix (trial days, expired badge).
    func update(with usage: UsageSnapshot, error: UsageMonitor.MonitorError?, alertLevel: AlertManager.AlertLevel = .normal, licenseState: LicenseState? = nil) {
        guard let button = statusItem?.button else { return }

        // Store last parameters for re-rendering on settings change
        lastUsage = usage
        lastError = error
        lastAlertLevel = alertLevel
        lastLicenseState = licenseState

        // Determine suffix from license state
        var suffix = licenseState?.menuBarSuffix

        // Determine if we need error/alert indicators
        var isErrorState = false
        var isCriticalState = false

        if case .bothSourcesFailed = error {
            isErrorState = true
        } else if alertLevel == .critical {
            isCriticalState = true
        }

        // For error/critical states, append "!" to suffix
        if isErrorState || isCriticalState {
            if let existing = suffix {
                suffix = "\(existing) !"
            } else {
                suffix = "!"
            }
        }

        // Use the renderer
        let hasData = usage.source != .none
        let result = MenuBarIconRenderer.render(
            style: currentStyle,
            percentage: usage.hasPercentage ? usage.primaryPercentage : 0,
            isMonochrome: isMonochrome,
            hasData: hasData && usage.hasPercentage,
            suffix: suffix
        )

        if let image = result.image {
            // Image-based style
            button.image = image
            button.imagePosition = .imageOnly
            button.attributedTitle = NSAttributedString(string: "")

            // For error/critical states on image styles, show "!" text after the icon
            if isErrorState || isCriticalState {
                let errorColor: NSColor
                if isErrorState {
                    errorColor = NSColor(calibratedRed: 0.9, green: 0.5, blue: 0.2, alpha: 1.0)
                } else {
                    errorColor = NSColor(calibratedRed: 0.85, green: 0.25, blue: 0.2, alpha: 1.0)
                }
                let errorAttrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .bold),
                    .foregroundColor: errorColor,
                ]
                button.attributedTitle = NSAttributedString(string: "!", attributes: errorAttrs)
                button.imagePosition = .imageLeft
            }
        } else if let title = result.title {
            // Text-based style
            button.image = nil
            button.imagePosition = .noImage

            // For error/critical states on text styles, override color
            if isErrorState {
                let mutable = NSMutableAttributedString(attributedString: title)
                mutable.addAttribute(.foregroundColor, value: NSColor(calibratedRed: 0.9, green: 0.5, blue: 0.2, alpha: 1.0), range: NSRange(location: 0, length: mutable.length))
                button.attributedTitle = mutable
            } else if isCriticalState {
                let mutable = NSMutableAttributedString(attributedString: title)
                mutable.addAttribute(.foregroundColor, value: NSColor(calibratedRed: 0.85, green: 0.25, blue: 0.2, alpha: 1.0), range: NSRange(location: 0, length: mutable.length))
                button.attributedTitle = mutable
            } else {
                button.attributedTitle = title
            }
        }

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

        // Quit tokemon (Cmd+Q)
        let quitItem = NSMenuItem(title: "Quit tokemon", action: #selector(ContextMenuActions.quitApp), keyEquivalent: "q")
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
