import Foundation

/// Manages alert thresholds and notification state for usage warnings.
/// Tracks alert level (normal/warning/critical) based on usage percentage.
/// Integrates with UsageMonitor via callback pattern.
@Observable
@MainActor
final class AlertManager {

    // MARK: - Alert Level

    /// Usage alert levels based on threshold and limit
    enum AlertLevel: Int, Comparable, Sendable {
        case normal = 0
        case warning = 1
        case critical = 2

        static func < (lhs: AlertLevel, rhs: AlertLevel) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    // MARK: - Published State

    /// Current alert level for UI binding (menu bar indicator, warning banner)
    var currentAlertLevel: AlertLevel = .normal

    // MARK: - Settings (UserDefaults-backed)

    /// Alert threshold percentage (50-100). Warning fires at this level.
    var alertThreshold: Int {
        get {
            let stored = UserDefaults.standard.integer(forKey: "alertThreshold")
            return stored > 0 ? min(100, max(50, stored)) : Constants.defaultAlertThreshold
        }
        set {
            let clamped = min(100, max(50, newValue))
            UserDefaults.standard.set(clamped, forKey: "alertThreshold")
        }
    }

    /// Whether system notifications are enabled (default false until permission granted)
    var notificationsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "notificationsEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "notificationsEnabled") }
    }

    /// Whether we have notification permission (set after permission request)
    private(set) var notificationPermissionGranted: Bool = false

    // MARK: - Private State

    /// Last level we notified about (prevents duplicate notifications)
    @ObservationIgnored
    private var lastNotifiedLevel: AlertLevel = .normal

    /// Tracks the window reset timestamp to detect new windows
    @ObservationIgnored
    private var lastResetsAt: Date?

    // MARK: - Public Methods

    /// Check usage and update alert level. Called by UsageMonitor on each refresh.
    ///
    /// - Parameter usage: Current usage snapshot from OAuth or JSONL
    ///
    /// Behavior:
    /// - Only processes snapshots with valid percentage
    /// - Detects window reset (resetsAt changed) and resets notification state
    /// - Updates currentAlertLevel for UI binding
    /// - Only fires notifications when crossing INTO a higher level
    func checkUsage(_ usage: UsageSnapshot) {
        // Guard: only process OAuth snapshots with percentage
        guard usage.hasPercentage else { return }

        // Detect window reset
        if let resetsAt = usage.resetsAt, resetsAt != lastResetsAt {
            resetNotificationState()
            lastResetsAt = resetsAt
        }

        let percentage = Int(usage.primaryPercentage)
        let newLevel = alertLevel(for: percentage)

        // Update current level for UI (always)
        if newLevel != currentAlertLevel {
            currentAlertLevel = newLevel
        }

        // Only notify when crossing INTO a higher level
        // (and not re-notifying for same level on subsequent checks)
        if newLevel > lastNotifiedLevel {
            lastNotifiedLevel = newLevel
            sendNotification(level: newLevel, percentage: percentage)
        }
    }

    /// Reset notification state (called when window resets or manually)
    func resetNotificationState() {
        lastNotifiedLevel = .normal
        currentAlertLevel = .normal
    }

    // MARK: - Private Methods

    /// Calculate alert level for a given percentage
    private func alertLevel(for percentage: Int) -> AlertLevel {
        if percentage >= 100 {
            return .critical
        } else if percentage >= alertThreshold {
            return .warning
        }
        return .normal
    }

    /// Send system notification (stub - implemented in Plan 02)
    private func sendNotification(level: AlertLevel, percentage: Int) {
        // Notification implementation deferred to 02-02-PLAN.md
        // This stub exists to show where notifications will be triggered
        print("[AlertManager] Level changed to \(level) at \(percentage)%")
    }
}
