import SwiftUI
import AppKit

/// Custom NSPanel configured for floating, always-on-top behavior.
/// Stays visible when app loses focus, doesn't steal focus when clicked.
class FloatingPanel: NSPanel {
    override init(contentRect: NSRect,
                  styleMask style: NSWindow.StyleMask,
                  backing backingStoreType: NSWindow.BackingStoreType,
                  defer flag: Bool) {
        super.init(contentRect: contentRect,
                   styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
                   backing: backingStoreType,
                   defer: flag)

        // Core floating panel configuration
        self.isFloatingPanel = true
        self.level = .floating
        self.hidesOnDeactivate = false  // CRITICAL: Stay visible when app loses focus
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Visual configuration
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.isMovableByWindowBackground = true
        self.isReleasedWhenClosed = false  // Keep in memory for reuse

        // Animation
        self.animationBehavior = .utilityWindow
    }

    // Allow becoming key for any interactive elements
    override var canBecomeKey: Bool { true }
}

/// Manages the floating usage window lifecycle.
/// Singleton service following the SettingsWindowController pattern.
@MainActor
final class FloatingWindowController {
    static let shared = FloatingWindowController()

    private var panel: FloatingPanel?
    private var monitor: UsageMonitor?
    private var alertManager: AlertManager?
    private var themeManager: ThemeManager?

    /// Auto-save name for position persistence
    private let frameAutosaveName = "ClaudeMonFloatingWindow"

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

    /// Show the floating window, creating it if necessary.
    /// Position is restored from UserDefaults if previously saved.
    func showFloatingWindow() {
        if let existingPanel = panel {
            existingPanel.makeKeyAndOrderFront(nil)
            return
        }

        guard let monitor = monitor else {
            print("[ClaudeMon] Error: Monitor not set for floating window")
            return
        }

        guard let alertManager = alertManager else {
            print("[ClaudeMon] Error: AlertManager not set for floating window")
            return
        }

        guard let themeManager = themeManager else {
            print("[ClaudeMon] Error: ThemeManager not set for floating window")
            return
        }

        // Create panel with compact size
        let newPanel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 140, height: 80),
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // Position persistence - MUST be set before showing window
        // This stores/restores position automatically in UserDefaults
        newPanel.setFrameAutosaveName(frameAutosaveName)

        // Set initial position if no saved position exists
        // Check if frame is at origin (no saved position)
        if newPanel.frame.origin == .zero {
            newPanel.setPosition(vertical: .top, horizontal: .right, padding: 20)
        }

        // Real floating window content with live usage data
        let contentView = FloatingWindowView()
            .environment(monitor)
            .environment(alertManager)
            .environment(themeManager)

        let hostingController = NSHostingController(rootView: contentView)
        newPanel.contentViewController = hostingController

        self.panel = newPanel
        newPanel.makeKeyAndOrderFront(nil)
    }

    /// Hide the floating window (close it)
    func hideFloatingWindow() {
        panel?.close()
    }

    /// Toggle floating window visibility
    func toggleFloatingWindow() {
        if isVisible {
            hideFloatingWindow()
        } else {
            showFloatingWindow()
        }
    }

    /// Whether the floating window is currently visible
    var isVisible: Bool {
        panel?.isVisible ?? false
    }
}
