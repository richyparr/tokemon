import SwiftUI
import AppKit

/// Rows available in the floating window, each showing a different usage metric.
enum FloatingWindowRow: String, CaseIterable, Codable, Hashable {
    case fiveHour = "fiveHour"
    case sevenDay = "sevenDay"
    case sevenDaySonnet = "sevenDaySonnet"

    var label: String {
        switch self {
        case .fiveHour: return "5-hour usage"
        case .sevenDay: return "7-day usage"
        case .sevenDaySonnet: return "7-day Sonnet"
        }
    }

    /// UserDefaults key for this row's toggle state
    var defaultsKey: String {
        "tokemon.floatingRow.\(rawValue)"
    }

    /// Extract the relevant percentage from a UsageSnapshot.
    func percentage(from usage: UsageSnapshot) -> Double? {
        switch self {
        case .fiveHour:
            return usage.hasPercentage ? usage.primaryPercentage : nil
        case .sevenDay:
            return usage.sevenDayUtilization
        case .sevenDaySonnet:
            return usage.sevenDaySonnetUtilization
        }
    }
}

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
    private let frameAutosaveName = "TokemonFloatingWindow"

    private init() {}

    // MARK: - Row Configuration

    /// Toggle a row on/off. Recreates the window to reflect changes.
    /// Hides the window if all rows are disabled.
    func toggleRow(_ row: FloatingWindowRow) {
        let current = isRowActive(row)
        UserDefaults.standard.set(!current, forKey: row.defaultsKey)

        // Always destroy existing panel — it will be recreated with fresh content
        panel?.close()
        panel = nil

        if !activeRows.isEmpty {
            showFloatingWindow()
        }
    }

    /// Whether a specific row is currently active.
    /// Defaults to true for fiveHour so the floating window shows on first launch.
    func isRowActive(_ row: FloatingWindowRow) -> Bool {
        if UserDefaults.standard.object(forKey: row.defaultsKey) == nil {
            return row == .fiveHour
        }
        return UserDefaults.standard.bool(forKey: row.defaultsKey)
    }

    /// Currently active rows in display order
    var activeRows: [FloatingWindowRow] {
        FloatingWindowRow.allCases.filter { isRowActive($0) }
    }

    /// Height for the floating window based on active row count
    private func windowHeight(for rowCount: Int) -> CGFloat {
        switch rowCount {
        case 0: return 80
        case 1: return 80
        case 2: return 140
        default: return 200
        }
    }

    // MARK: - Dependency Injection

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

    // MARK: - Window Lifecycle

    /// Show the floating window, creating it if necessary.
    /// Position is restored from UserDefaults if previously saved.
    func showFloatingWindow() {
        // If panel already exists, just bring it forward
        if let existingPanel = panel {
            existingPanel.makeKeyAndOrderFront(nil)
            return
        }

        guard let monitor = monitor else {
            print("[Tokemon] Error: Monitor not set for floating window")
            return
        }

        guard let alertManager = alertManager else {
            print("[Tokemon] Error: AlertManager not set for floating window")
            return
        }

        guard let themeManager = themeManager else {
            print("[Tokemon] Error: ThemeManager not set for floating window")
            return
        }

        let rows = activeRows
        let height = windowHeight(for: rows.count)

        // Create panel with compact size
        let newPanel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 160, height: height),
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // Position persistence - MUST be set before showing window
        newPanel.setFrameAutosaveName(frameAutosaveName)

        // Set initial position if no saved position exists
        if newPanel.frame.origin == .zero {
            newPanel.setPosition(vertical: .top, horizontal: .right, padding: 20)
        }

        let contentView = FloatingWindowView(rows: rows)
            .environment(monitor)
            .environment(alertManager)
            .environment(themeManager)

        let hostingController = NSHostingController(rootView: contentView)
        newPanel.contentViewController = hostingController

        self.panel = newPanel
        newPanel.makeKeyAndOrderFront(nil)

        // Watch for close-button (X) clicks so we nil out our reference
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: newPanel,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.panel = nil
            }
        }
    }

    /// Hide the floating window and release the panel reference
    func hideFloatingWindow() {
        panel?.close()
        panel = nil
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

    /// Restore the floating window on app launch if rows were previously active
    func restoreIfNeeded() {
        if !activeRows.isEmpty {
            showFloatingWindow()
        }
    }
}
