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
            // Reset notification state when threshold changes so user gets notified at new level
            hasNotifiedWarning = false
            hasNotifiedCritical = false
        }
    }

    /// Whether system notifications are enabled by user preference
    var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        }
    }

    /// Whether auto-start session notification is enabled
    var autoStartEnabled: Bool {
        didSet {
            UserDefaults.standard.set(autoStartEnabled, forKey: Constants.autoStartSessionKey)
        }
    }

    // MARK: - Initialization

    init() {
        // Load from UserDefaults
        let stored = UserDefaults.standard.integer(forKey: "alertThreshold")
        self.alertThreshold = stored > 0 ? min(100, max(50, stored)) : Constants.defaultAlertThreshold
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        self.autoStartEnabled = UserDefaults.standard.bool(forKey: Constants.autoStartSessionKey)
    }

    // MARK: - Private State

    /// Whether we've notified about warning level this usage window
    @ObservationIgnored
    private var hasNotifiedWarning: Bool = false

    /// Whether we've notified about critical level this usage window
    @ObservationIgnored
    private var hasNotifiedCritical: Bool = false

    /// Previous usage percentage (to detect 0% transition)
    @ObservationIgnored
    private var previousPercentage: Double = -1

    /// Whether we've notified about session reset this cycle
    @ObservationIgnored
    private var hasNotifiedSessionReset: Bool = false

    /// Tracks the window reset timestamp (rounded to minute) to detect new windows
    @ObservationIgnored
    private var lastResetsAtMinute: Int = 0

    /// Whether we're running as a proper app bundle (required for notifications)
    @ObservationIgnored
    private let hasAppBundle: Bool = Bundle.main.bundleIdentifier != nil

    // MARK: - Public Methods

    /// Check usage and update alert level. Called by UsageMonitor on each refresh.
    ///
    /// - Parameter usage: Current usage snapshot from OAuth or JSONL
    ///
    /// Behavior:
    /// - Only processes snapshots with valid percentage
    /// - Detects window reset (resetsAt changed significantly) and resets notification state
    /// - Updates currentAlertLevel for UI binding
    /// - Fires notifications ONCE per level per usage window
    func checkUsage(_ usage: UsageSnapshot) {
        // Guard: only process OAuth snapshots with percentage
        guard usage.hasPercentage else { return }

        // Detect window reset by comparing reset time rounded to minutes
        // This prevents false resets from sub-second timestamp differences
        if let resetsAt = usage.resetsAt {
            let resetsAtMinute = Int(resetsAt.timeIntervalSince1970 / 60)
            if resetsAtMinute != lastResetsAtMinute {
                print("[AlertManager] Usage window reset detected, clearing notification state")
                resetNotificationState()
                lastResetsAtMinute = resetsAtMinute
            }
        }

        let percentage = Int(usage.primaryPercentage)
        let newLevel = alertLevel(for: percentage)

        // Update current level for UI (always)
        if newLevel != currentAlertLevel {
            currentAlertLevel = newLevel
        }

        // Only notify ONCE per level per usage window
        guard notificationsEnabled else { return }

        if newLevel == .critical && !hasNotifiedCritical {
            hasNotifiedCritical = true
            sendNotification(level: .critical, percentage: percentage)
        } else if newLevel == .warning && !hasNotifiedWarning {
            hasNotifiedWarning = true
            sendNotification(level: .warning, percentage: percentage)
        }

        // Check for session reset (auto-start notification)
        checkForSessionReset(usage)
    }

    /// Reset notification state (called when window resets or manually)
    func resetNotificationState() {
        hasNotifiedWarning = false
        hasNotifiedCritical = false
        hasNotifiedSessionReset = false
        currentAlertLevel = .normal
    }

    // MARK: - Session Reset Detection

    /// Check if usage has reset to 0% and send notification if enabled.
    /// Called by checkUsage after each successful refresh.
    ///
    /// - Parameter usage: Current usage snapshot
    ///
    /// Logic:
    /// - If previous percentage was > 0 and current is 0%, session has reset
    /// - Send notification ONCE per reset cycle
    /// - Reset the notification flag when usage goes back above 0%
    func checkForSessionReset(_ usage: UsageSnapshot) {
        guard usage.hasPercentage else { return }
        guard autoStartEnabled else {
            previousPercentage = usage.primaryPercentage
            return
        }

        let current = usage.primaryPercentage

        // Detect reset: was > 0, now is 0
        if previousPercentage > 0 && current == 0 && !hasNotifiedSessionReset {
            hasNotifiedSessionReset = true
            sendSessionResetNotification()
        }

        // Reset notification flag when usage goes back above 0
        if current > 0 {
            hasNotifiedSessionReset = false
        }

        previousPercentage = current
    }

    /// Send notification that session has reset
    private func sendSessionResetNotification() {
        guard hasAppBundle else {
            print("[AlertManager] No app bundle, skipping session reset notification")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Session Available"
        content.subtitle = "Claude Code"
        content.body = "Your usage has reset to 0%. A fresh session is ready."
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let uniqueId = "tokemon.session-reset.\(Date().timeIntervalSince1970)"

        let request = UNNotificationRequest(
            identifier: uniqueId,
            content: content,
            trigger: nil
        )

        print("[AlertManager] Sending session reset notification")

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[AlertManager] Session reset notification error: \(error.localizedDescription)")
            }
        }
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

    /// Request notification permission from the system.
    /// Called when user enables notifications - prompts for permission if needed.
    /// Requires a proper app bundle - no-op when running as SPM executable.
    nonisolated func requestNotificationPermission() {
        guard Bundle.main.bundleIdentifier != nil else {
            print("[AlertManager] Notifications unavailable: no app bundle")
            return
        }

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
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
    ///
    /// Requires a proper app bundle - no-op when running as SPM executable.
    /// If permission not granted, notification silently fails (system behavior).
    private func sendNotification(level: AlertLevel, percentage: Int) {
        guard hasAppBundle else {
            print("[AlertManager] No app bundle, skipping notification")
            return
        }
        guard level != .normal else { return }

        let content = UNMutableNotificationContent()

        switch level {
        case .warning:
            content.title = "Usage Warning"
            content.subtitle = "Claude Code"
            content.body = "You've used \(percentage)% of your 5-hour limit. Consider pacing yourself."
            content.sound = .default
            content.interruptionLevel = .timeSensitive
        case .critical:
            content.title = "Usage Limit Reached"
            content.subtitle = "Claude Code"
            content.body = "You've hit 100% of your 5-hour usage limit. Wait for reset or use a different account."
            content.sound = UNNotificationSound.defaultCritical
            content.interruptionLevel = .critical
        case .normal:
            return
        }

        // Use unique identifier to prevent notification replacement issues
        let uniqueId = "tokemon.alert.\(level).\(Date().timeIntervalSince1970)"

        let request = UNNotificationRequest(
            identifier: uniqueId,
            content: content,
            trigger: nil  // Immediate delivery
        )

        print("[AlertManager] Sending notification: \(content.title) - \(content.body)")

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[AlertManager] Notification error: \(error.localizedDescription)")
            } else {
                print("[AlertManager] Notification sent successfully")
            }
        }
    }
}
