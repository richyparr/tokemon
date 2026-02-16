import Foundation
import UserNotifications

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

    // MARK: - Settings (stored properties that sync with UserDefaults)

    /// Alert threshold percentage (50-100). Warning fires at this level.
    var alertThreshold: Int {
        didSet {
            let clamped = min(100, max(50, alertThreshold))
            if alertThreshold != clamped { alertThreshold = clamped }
            UserDefaults.standard.set(clamped, forKey: "alertThreshold")
        }
    }

    /// Whether system notifications are enabled by user preference
    var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        }
    }

    // MARK: - Initialization

    init() {
        // Load from UserDefaults
        let stored = UserDefaults.standard.integer(forKey: "alertThreshold")
        self.alertThreshold = stored > 0 ? min(100, max(50, stored)) : Constants.defaultAlertThreshold
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
    }

    // MARK: - Private State

    /// Last level we notified about (prevents duplicate notifications)
    @ObservationIgnored
    private var lastNotifiedLevel: AlertLevel = .normal

    /// Tracks the window reset timestamp to detect new windows
    @ObservationIgnored
    private var lastResetsAt: Date?

    /// Whether we're running as a proper app bundle (required for notifications)
    @ObservationIgnored
    private let hasAppBundle: Bool = Bundle.main.bundleIdentifier != nil

    /// Reference to AccountManager for per-account threshold lookups
    @ObservationIgnored
    private var accountManager: AccountManager?

    /// Set account manager reference for per-account thresholds
    func setAccountManager(_ manager: AccountManager) {
        self.accountManager = manager
    }

    // MARK: - Public Methods

    /// Check usage and update alert level. Called by UsageMonitor on each refresh.
    /// If account is provided, uses per-account threshold. Otherwise falls back to global.
    ///
    /// - Parameters:
    ///   - usage: Current usage snapshot from OAuth or JSONL
    ///   - account: Optional account for per-account threshold lookup
    ///
    /// Behavior:
    /// - Only processes snapshots with valid percentage
    /// - Detects window reset (resetsAt changed) and resets notification state
    /// - Updates currentAlertLevel for UI binding
    /// - Only fires notifications when crossing INTO a higher level
    func checkUsage(_ usage: UsageSnapshot, for account: Account? = nil) {
        // Guard: only process OAuth snapshots with percentage
        guard usage.hasPercentage else { return }

        // Detect window reset
        if let resetsAt = usage.resetsAt, resetsAt != lastResetsAt {
            resetNotificationState()
            lastResetsAt = resetsAt
        }

        // Get threshold: per-account if available, otherwise global
        let threshold: Int
        let effectiveNotificationsEnabled: Bool

        if let account = account {
            threshold = account.settings.alertThreshold
            effectiveNotificationsEnabled = account.settings.notificationsEnabled
        } else if let activeAccount = accountManager?.activeAccount {
            threshold = activeAccount.settings.alertThreshold
            effectiveNotificationsEnabled = activeAccount.settings.notificationsEnabled
        } else {
            threshold = alertThreshold  // Global fallback
            effectiveNotificationsEnabled = self.notificationsEnabled
        }

        let percentage = Int(usage.primaryPercentage)
        let newLevel = alertLevel(for: percentage, threshold: threshold)

        // Update current level for UI (always)
        if newLevel != currentAlertLevel {
            currentAlertLevel = newLevel
        }

        // Only notify when crossing INTO a higher level
        if newLevel > lastNotifiedLevel && effectiveNotificationsEnabled {
            lastNotifiedLevel = newLevel
            sendNotification(level: newLevel, percentage: percentage, accountName: account?.displayName)
        }
    }

    /// Reset notification state (called when window resets or manually)
    func resetNotificationState() {
        lastNotifiedLevel = .normal
        currentAlertLevel = .normal
    }

    // MARK: - Private Methods

    /// Calculate alert level for a given percentage
    private func alertLevel(for percentage: Int, threshold: Int? = nil) -> AlertLevel {
        let effectiveThreshold = threshold ?? alertThreshold
        if percentage >= 100 {
            return .critical
        } else if percentage >= effectiveThreshold {
            return .warning
        }
        return .normal
    }

    /// Request notification permission from the system.
    /// Called when user enables notifications - prompts for permission if needed.
    /// Requires a proper app bundle - no-op when running as SPM executable.
    nonisolated func requestNotificationPermission() {
        guard Bundle.main.bundleIdentifier != nil else {
            print("[AlertManager] Notifications unavailable: no app bundle")
            return
        }

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("[AlertManager] Permission error: \(error.localizedDescription)")
            } else {
                print("[AlertManager] Permission granted: \(granted)")
            }
        }
    }

    /// Send macOS system notification for usage alerts.
    ///
    /// - Parameters:
    ///   - level: The alert level (warning or critical)
    ///   - percentage: Current usage percentage
    ///   - accountName: Optional account name to include in notification
    ///
    /// Uses identifier per level and account to allow per-account notifications.
    /// Requires a proper app bundle - no-op when running as SPM executable.
    /// If permission not granted, notification silently fails (system behavior).
    private func sendNotification(level: AlertLevel, percentage: Int, accountName: String? = nil) {
        guard hasAppBundle else { return }
        guard level != .normal else { return }

        let content = UNMutableNotificationContent()
        let accountPrefix = accountName.map { "[\($0)] " } ?? ""

        switch level {
        case .warning:
            content.title = "\(accountPrefix)Claude Usage Warning"
            content.body = "You've used \(percentage)% of your 5-hour limit."
            content.sound = .default
        case .critical:
            content.title = "\(accountPrefix)Claude Usage Limit Reached"
            content.body = "You've reached your 5-hour usage limit."
            content.sound = UNNotificationSound.defaultCritical
        case .normal:
            return
        }

        // Include account in identifier to allow per-account notifications
        let accountSuffix = accountName ?? "default"
        let request = UNNotificationRequest(
            identifier: "tokemon.alert.\(level).\(accountSuffix)",
            content: content,
            trigger: nil  // Immediate delivery
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[AlertManager] Notification error: \(error.localizedDescription)")
            }
        }
    }
}
