# Phase 2: Alerts & Notifications - Research

**Researched:** 2026-02-13
**Domain:** macOS notifications, visual alerts, threshold configuration, launch-at-login
**Confidence:** HIGH

## Summary

Phase 2 adds user alerts when Claude usage approaches configurable thresholds. The implementation spans four key areas: (1) visual warning indicators in the menu bar and popover when usage crosses a threshold, (2) macOS system notifications via UNUserNotificationCenter, (3) settings UI for threshold configuration and notification preferences, and (4) launch-at-login support via SMAppService.

The existing Phase 1 foundation provides the `UsageMonitor` which already tracks `primaryPercentage` and has an `onUsageChanged` callback that updates the status item. The alert system will integrate as a new service (`AlertManager`) that observes usage changes and fires alerts when thresholds are crossed, with state tracking to prevent duplicate notifications.

**Primary recommendation:** Create an `AlertManager` service that observes `UsageMonitor.currentUsage`, compares against user-configured thresholds stored in UserDefaults, and triggers visual/notification alerts. Use UNUserNotificationCenter for system notifications with fixed identifiers to prevent duplicates. Use SMAppService.mainApp for launch-at-login. Add an "Alerts" tab to SettingsView for threshold and notification configuration.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| UserNotifications | macOS 14 SDK | Local notifications via UNUserNotificationCenter | Native Apple framework for all notification types |
| ServiceManagement | macOS 14 SDK | Launch-at-login via SMAppService.mainApp | Modern API replacing deprecated SMLoginItemSetEnabled |
| SwiftUI | macOS 14 SDK | Settings UI for threshold and notification configuration | Consistent with Phase 1 UI patterns |
| AppKit | macOS 14 SDK | Visual indicators via NSStatusItem (already integrated) | Extends existing menu bar rendering |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| (none new) | - | - | Phase 2 uses only Apple frameworks |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| SMAppService | LaunchAtLogin library (sindresorhus) | Extra dependency; SMAppService is simpler for basic login item |
| UNUserNotificationCenter | NSUserNotificationCenter | Deprecated since macOS 10.14; UNUserNotificationCenter is the modern standard |
| UserDefaults for thresholds | SwiftData | Overkill for simple settings; UserDefaults with @AppStorage is sufficient |

**No new SPM dependencies required** - all functionality comes from Apple frameworks.

## Architecture Patterns

### Recommended Project Structure (Phase 2 Additions)
```
ClaudeMon/
├── Services/
│   ├── AlertManager.swift          # NEW: Threshold checking, notification firing
│   └── UsageMonitor.swift          # MODIFY: Add alert callback integration
│
├── Views/
│   ├── Settings/
│   │   ├── SettingsView.swift      # MODIFY: Add "Alerts" tab
│   │   └── AlertSettings.swift     # NEW: Threshold and notification configuration
│   └── MenuBar/
│       ├── UsageHeaderView.swift   # MODIFY: Add visual warning indicator
│       └── PopoverContentView.swift # MODIFY: Show alert status if at threshold
│
└── Utilities/
    └── Constants.swift             # MODIFY: Add alert threshold defaults
```

### Pattern 1: AlertManager Service
**What:** Dedicated service that observes usage changes and manages alert state.
**When to use:** Central point for all alert logic -- threshold checking, notification firing, duplicate prevention.
**Example:**
```swift
import UserNotifications

@Observable
@MainActor
final class AlertManager {
    // MARK: - Settings (UserDefaults-backed)

    var alertThreshold: Int {
        get { UserDefaults.standard.integer(forKey: "alertThreshold").clamped(to: 50...100) }
        set { UserDefaults.standard.set(newValue, forKey: "alertThreshold") }
    }

    var criticalThreshold: Int {
        get { UserDefaults.standard.integer(forKey: "criticalThreshold").clamped(to: 90...100) }
        set { UserDefaults.standard.set(newValue, forKey: "criticalThreshold") }
    }

    var notificationsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "notificationsEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "notificationsEnabled") }
    }

    // MARK: - Alert State

    enum AlertLevel: Comparable {
        case normal
        case warning    // Crossed alertThreshold
        case critical   // Crossed criticalThreshold (100%)
    }

    private(set) var currentAlertLevel: AlertLevel = .normal
    private var lastNotifiedLevel: AlertLevel = .normal

    // MARK: - Usage Observation

    /// Called by UsageMonitor.onUsageChanged callback
    func checkUsage(_ usage: UsageSnapshot) {
        guard usage.hasPercentage else { return }

        let percentage = Int(usage.primaryPercentage)
        let newLevel = alertLevel(for: percentage)

        // Only trigger when crossing INTO a higher alert level
        if newLevel > currentAlertLevel && newLevel > lastNotifiedLevel {
            currentAlertLevel = newLevel
            lastNotifiedLevel = newLevel
            triggerAlert(level: newLevel, percentage: percentage)
        } else if newLevel < currentAlertLevel {
            // Usage dropped -- reset for next rise
            currentAlertLevel = newLevel
        }
    }

    private func alertLevel(for percentage: Int) -> AlertLevel {
        if percentage >= criticalThreshold {
            return .critical
        } else if percentage >= alertThreshold {
            return .warning
        }
        return .normal
    }

    /// Reset notification tracking (e.g., when 5-hour window resets)
    func resetNotificationState() {
        lastNotifiedLevel = .normal
        currentAlertLevel = .normal
    }
}
```

### Pattern 2: macOS System Notifications
**What:** Fire local notifications when crossing thresholds using UNUserNotificationCenter.
**When to use:** When `notificationsEnabled` is true and user has granted notification permission.
**Example:**
```swift
import UserNotifications

extension AlertManager {
    /// Request notification permission at app startup
    func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("[AlertManager] Notification permission error: \(error.localizedDescription)")
            }
            // Store permission state for UI feedback
            Task { @MainActor in
                self.notificationPermissionGranted = granted
            }
        }
    }

    private func triggerAlert(level: AlertLevel, percentage: Int) {
        // Always update visual state
        // Notification only if enabled and permitted
        guard notificationsEnabled && notificationPermissionGranted else { return }

        let content = UNMutableNotificationContent()

        switch level {
        case .warning:
            content.title = "Claude Usage Warning"
            content.body = "You've used \(percentage)% of your 5-hour limit."
            content.sound = .default
        case .critical:
            content.title = "Claude Usage Limit Reached"
            content.body = "You've reached \(percentage)% of your 5-hour limit."
            content.sound = UNNotificationSound.defaultCritical
        case .normal:
            return
        }

        // Use fixed identifier to prevent duplicate notifications
        // Same identifier = replaces previous notification instead of stacking
        let identifier = "claudemon.alert.\(level)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil  // Deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[AlertManager] Failed to send notification: \(error.localizedDescription)")
            }
        }
    }
}
```

### Pattern 3: Visual Warning Indicator
**What:** Show visual warning state in menu bar and popover header when at threshold.
**When to use:** Always when `alertLevel >= .warning`.
**Example:**
```swift
// In StatusItemManager.update() - menu bar indicator
func update(with usage: UsageSnapshot, error: UsageMonitor.MonitorError?, alertLevel: AlertManager.AlertLevel) {
    guard let button = statusItem?.button else { return }

    var text = usage.menuBarText
    let color: NSColor

    // Check for error first
    if case .bothSourcesFailed = error {
        text = "\(text) !"
        color = NSColor(calibratedRed: 0.9, green: 0.5, blue: 0.2, alpha: 1.0)
    }
    // Alert state takes precedence for color
    else if alertLevel == .critical {
        // Pulsing or exclamation indicator for critical
        text = "\(text) !"
        color = NSColor(calibratedRed: 0.85, green: 0.25, blue: 0.2, alpha: 1.0)
    } else if alertLevel == .warning {
        // Standard gradient color but could add subtle indicator
        color = GradientColors.color(for: usage.primaryPercentage)
    } else if usage.hasPercentage {
        color = GradientColors.color(for: usage.primaryPercentage)
    } else {
        color = NSColor.secondaryLabelColor
    }

    // ... rest of attributedTitle setup
}

// In UsageHeaderView - popover warning banner
struct UsageHeaderView: View {
    let usage: UsageSnapshot
    let alertLevel: AlertManager.AlertLevel

    var body: some View {
        VStack(spacing: 4) {
            // Warning banner for critical state
            if alertLevel == .critical {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("Usage limit reached")
                }
                .font(.caption)
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.9), in: Capsule())
            }

            // Existing percentage display...
        }
    }
}
```

### Pattern 4: Launch at Login with SMAppService
**What:** Register/unregister app as login item using modern ServiceManagement API.
**When to use:** User toggles "Launch at Login" in settings.
**Example:**
```swift
import ServiceManagement

struct AlertSettings: View {
    // Read status from system, not stored locally
    // User can change this in System Settings > General > Login Items
    private var launchAtLoginEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    var body: some View {
        Form {
            Section {
                Toggle("Launch at login", isOn: Binding(
                    get: { launchAtLoginEnabled },
                    set: { newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            print("[AlertSettings] Login item error: \(error.localizedDescription)")
                        }
                    }
                ))

                Text("Start ClaudeMon automatically when you log in")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            // Re-check status when view appears (user may have changed in System Settings)
        }
    }
}
```

### Pattern 5: Threshold Settings UI
**What:** Settings tab for configuring alert thresholds and notification preferences.
**When to use:** Part of the main SettingsView TabView.
**Example:**
```swift
struct AlertSettings: View {
    @Environment(AlertManager.self) private var alertManager

    private let thresholdOptions = [50, 60, 70, 80, 90]

    var body: some View {
        @Bindable var alertManager = alertManager

        Form {
            Section {
                Picker("Warning threshold", selection: Binding(
                    get: { alertManager.alertThreshold },
                    set: { alertManager.alertThreshold = $0 }
                )) {
                    ForEach(thresholdOptions, id: \.self) { value in
                        Text("\(value)%").tag(value)
                    }
                }
                .pickerStyle(.menu)

                Text("Show warning when usage exceeds this percentage")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Alert Threshold")
            }

            Section {
                Toggle("macOS notifications", isOn: Binding(
                    get: { alertManager.notificationsEnabled },
                    set: { alertManager.notificationsEnabled = $0 }
                ))

                if alertManager.notificationsEnabled && !alertManager.notificationPermissionGranted {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Notifications not permitted")
                            .font(.caption)
                        Button("Open Settings") {
                            openNotificationSettings()
                        }
                        .font(.caption)
                    }
                }
            } header: {
                Text("Notifications")
            }

            // Launch at login section...
        }
        .formStyle(.grouped)
        .padding()
    }

    private func openNotificationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }
}
```

### Anti-Patterns to Avoid
- **Firing notifications on every poll:** Only notify when CROSSING a threshold upward, not continuously while above it. Track `lastNotifiedLevel` to prevent spam.
- **Storing launch-at-login state in UserDefaults:** User can change this in System Settings; always read from `SMAppService.mainApp.status`.
- **Using random UUIDs for notification identifiers:** Use fixed identifiers per alert level so subsequent notifications replace rather than stack.
- **Checking thresholds in the view layer:** Keep threshold logic in `AlertManager`, not scattered across views.
- **Requesting notification permission every time:** Request once at app startup, cache the result, and show UI to guide user to System Settings if denied.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Local notifications | Custom notification overlay | UNUserNotificationCenter | Integrates with Notification Center, Focus modes, permissions |
| Launch at login | LaunchAgent plist + launchctl | SMAppService.mainApp | Modern API, no plist files, works with System Settings UI |
| Duplicate notification prevention | Custom tracking with timestamps | Fixed notification identifiers | System handles replacement automatically |
| Notification permission check | Polling UNUserNotificationCenter | One-time request + cache result | Permission dialog only shown once per app |

**Key insight:** Apple's notification and login item APIs handle all the edge cases (Focus modes, permission persistence, System Settings sync). Hand-rolling alternatives would duplicate significant complexity.

## Common Pitfalls

### Pitfall 1: Notification Spam
**What goes wrong:** App sends a notification every time usage is checked while above threshold, flooding the user with alerts.
**Why it happens:** Checking "percentage >= threshold" is true continuously, not just at the crossing moment.
**How to avoid:** Track `lastNotifiedLevel` and only fire when the NEW level exceeds the PREVIOUS level. Reset tracking when the 5-hour window resets (detect via `resetsAt` timestamp change).
**Warning signs:** User receives 60+ notifications per hour instead of one.

### Pitfall 2: SMAppService Status Not Reflecting Reality
**What goes wrong:** Toggle shows "enabled" but app doesn't launch at login, or vice versa.
**Why it happens:** User changed setting in System Settings > General > Login Items, but app reads cached state.
**How to avoid:** Always read `SMAppService.mainApp.status` directly, never store in UserDefaults. Re-check on view appearance.
**Warning signs:** UI toggle is out of sync with actual behavior.

### Pitfall 3: Notification Permission Denied Silently
**What goes wrong:** User enables notifications in ClaudeMon but never receives them.
**Why it happens:** User denied notification permission at the system prompt, or denied it later in System Settings.
**How to avoid:** Check `UNUserNotificationCenter.current().getNotificationSettings()` and show UI guidance when denied. Provide button to open System Settings > Notifications.
**Warning signs:** `notificationsEnabled` is true but no notifications appear.

### Pitfall 4: Alert Level Doesn't Reset
**What goes wrong:** After the 5-hour window resets, user is back at 0% but no warning fires when they cross the threshold again.
**Why it happens:** `lastNotifiedLevel` was set to `.warning` and never reset.
**How to avoid:** Detect when `resetsAt` timestamp changes (new 5-hour window) and call `resetNotificationState()`.
**Warning signs:** Warnings work the first time but never again.

### Pitfall 5: Visual Indicator Flickers
**What goes wrong:** Menu bar text alternates between normal and warning state rapidly.
**Why it happens:** Alert level is computed on every frame or the view is re-rendering continuously.
**How to avoid:** Compute alert level only in `AlertManager.checkUsage()` (called once per poll), not in view body. Store `currentAlertLevel` as observable state.
**Warning signs:** Menu bar percentage visibly blinks or flickers.

### Pitfall 6: Notification Shows When App is in Foreground
**What goes wrong:** System notification banner appears even though the popover is open and the user is looking at the app.
**Why it happens:** By default, UNUserNotificationCenter delivers notifications regardless of app state.
**How to avoid:** Implement `UNUserNotificationCenterDelegate.userNotificationCenter(_:willPresent:withCompletionHandler:)` and suppress banner when app is active (popover open). The visual indicator in the popover is sufficient.
**Warning signs:** Redundant notification when user is already looking at usage data.

## Code Examples

### Complete AlertManager
```swift
import UserNotifications
import Foundation

@Observable
@MainActor
final class AlertManager {
    // MARK: - Settings

    var alertThreshold: Int {
        get {
            let stored = UserDefaults.standard.integer(forKey: "alertThreshold")
            return stored > 0 ? stored : Constants.defaultAlertThreshold
        }
        set { UserDefaults.standard.set(newValue, forKey: "alertThreshold") }
    }

    var notificationsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "notificationsEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "notificationsEnabled") }
    }

    // MARK: - Permission State

    private(set) var notificationPermissionGranted: Bool = false

    // MARK: - Alert State

    enum AlertLevel: Int, Comparable {
        case normal = 0
        case warning = 1
        case critical = 2

        static func < (lhs: AlertLevel, rhs: AlertLevel) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    private(set) var currentAlertLevel: AlertLevel = .normal
    private var lastNotifiedLevel: AlertLevel = .normal
    private var lastResetsAt: Date?

    // MARK: - Initialization

    init() {
        requestNotificationPermission()
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            Task { @MainActor in
                self.notificationPermissionGranted = granted
            }
        }
    }

    // MARK: - Usage Checking

    func checkUsage(_ usage: UsageSnapshot) {
        guard usage.hasPercentage else { return }

        // Detect window reset
        if let newResetsAt = usage.resetsAt, newResetsAt != lastResetsAt {
            resetNotificationState()
            lastResetsAt = newResetsAt
        }

        let percentage = Int(usage.primaryPercentage)
        let newLevel = alertLevel(for: percentage)

        if newLevel > currentAlertLevel && newLevel > lastNotifiedLevel {
            currentAlertLevel = newLevel
            lastNotifiedLevel = newLevel
            sendNotification(level: newLevel, percentage: percentage)
        } else {
            currentAlertLevel = newLevel
        }
    }

    private func alertLevel(for percentage: Int) -> AlertLevel {
        if percentage >= 100 {
            return .critical
        } else if percentage >= alertThreshold {
            return .warning
        }
        return .normal
    }

    func resetNotificationState() {
        lastNotifiedLevel = .normal
        currentAlertLevel = .normal
    }

    // MARK: - Notifications

    private func sendNotification(level: AlertLevel, percentage: Int) {
        guard notificationsEnabled && notificationPermissionGranted else { return }

        let content = UNMutableNotificationContent()

        switch level {
        case .warning:
            content.title = "Claude Usage Warning"
            content.body = "You've used \(percentage)% of your 5-hour limit."
            content.sound = .default
        case .critical:
            content.title = "Claude Usage Limit Reached"
            content.body = "You've reached your 5-hour usage limit."
            content.sound = UNNotificationSound.defaultCritical
        case .normal:
            return
        }

        let request = UNNotificationRequest(
            identifier: "claudemon.alert.\(level)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
```

### Notification Delegate Setup
```swift
// In ClaudeMonApp.swift
import UserNotifications

@main
struct ClaudeMonApp: App {
    @State private var monitor = UsageMonitor()
    @State private var alertManager = AlertManager()
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    init() {
        // Set notification delegate to handle foreground notifications
        UNUserNotificationCenter.current().delegate = appDelegate
    }

    // ... rest of app
}

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    // Suppress notification banner when app is active (popover visible)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner and sound even when app is in foreground
        // (since this is a menu bar app, "foreground" just means running)
        completionHandler([.banner, .sound])
    }

    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Could open popover or focus app
        NSApp.activate(ignoringOtherApps: true)
        completionHandler()
    }
}
```

### Alert Settings View
```swift
import SwiftUI
import ServiceManagement

struct AlertSettings: View {
    @Environment(AlertManager.self) private var alertManager

    private let thresholdOptions = [50, 60, 70, 80, 90]

    // Read directly from system, not stored
    private var launchAtLoginEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    var body: some View {
        @Bindable var alertManager = alertManager

        Form {
            Section {
                Picker("Warning threshold", selection: Binding(
                    get: { alertManager.alertThreshold },
                    set: { alertManager.alertThreshold = $0 }
                )) {
                    ForEach(thresholdOptions, id: \.self) { value in
                        Text("\(value)%").tag(value)
                    }
                }
                .pickerStyle(.menu)

                Text("Show warning when usage exceeds this percentage")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Alert Threshold")
            }

            Section {
                Toggle("macOS notifications", isOn: Binding(
                    get: { alertManager.notificationsEnabled },
                    set: { alertManager.notificationsEnabled = $0 }
                ))

                Text("Send system notifications when approaching usage limits")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if alertManager.notificationsEnabled && !alertManager.notificationPermissionGranted {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Notifications not permitted")
                            .font(.caption)
                        Spacer()
                        Button("Open Settings") {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .font(.caption)
                    }
                    .padding(.top, 4)
                }
            } header: {
                Text("Notifications")
            }

            Section {
                Toggle("Launch at login", isOn: Binding(
                    get: { launchAtLoginEnabled },
                    set: { newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            print("[AlertSettings] Login item error: \(error)")
                        }
                    }
                ))

                Text("Start ClaudeMon automatically when you log in")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Startup")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
```

### Integration with UsageMonitor
```swift
// In UsageMonitor.refresh() - after updating currentUsage
onUsageChanged?(currentUsage)
// Also call alert manager
onAlertCheck?(currentUsage)  // New callback for AlertManager

// In ClaudeMonApp.swift - wire up the callback
monitor.onAlertCheck = { [alertManager] usage in
    Task { @MainActor in
        alertManager.checkUsage(usage)
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| NSUserNotificationCenter | UNUserNotificationCenter | macOS 10.14 (2018) | Better integration, actionable notifications, Focus modes |
| SMLoginItemSetEnabled | SMAppService.mainApp | macOS 13 (2022) | No Launch Agent plist, syncs with System Settings UI |
| Global notification toggle | Per-app notification settings | macOS 12+ | Users control notifications granularly in System Settings |
| ObservableObject for settings | @Observable + @AppStorage | macOS 14 (2023) | Simpler state management, automatic persistence |

**Deprecated/outdated:**
- `NSUserNotificationCenter` -- deprecated since macOS 10.14, use `UNUserNotificationCenter`
- `SMLoginItemSetEnabled` -- deprecated since macOS 13, use `SMAppService`
- `LSSharedFileListInsertItemURL` -- deprecated, use `SMAppService`

## Open Questions

1. **Should critical alerts use different sound?**
   - What we know: `UNNotificationSound.defaultCritical` plays a more attention-grabbing sound
   - What's unclear: Whether this is too aggressive for a usage monitor
   - Recommendation: Use `defaultCritical` only for 100% (limit reached), `.default` for warning threshold

2. **Should we track 7-day thresholds separately?**
   - What we know: Phase 1 displays 5-hour, 7-day, and 7-day-opus utilizations
   - What's unclear: Whether users want separate alerts for each window
   - Recommendation: Phase 2 focuses on 5-hour (most relevant). Add 7-day alerts in a future phase if requested.

3. **Menu bar icon change vs. text indicator for alerts?**
   - What we know: Current design uses text ("45% !") for visual alert
   - What's unclear: Whether an icon change (SF Symbol) would be more noticeable
   - Recommendation: Start with text indicator ("!"), consistent with error state. Consider icon option in design phase.

## Sources

### Primary (HIGH confidence)
- [UNUserNotificationCenter | Apple Developer Documentation](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter) - Notification API reference
- [SMAppService | Apple Developer Documentation](https://developer.apple.com/documentation/servicemanagement/smappservice) - Login item API reference
- [Scheduling notifications | Hacking with Swift](https://www.hackingwithswift.com/read/21/2/scheduling-notifications-unusernotificationcenter-and-unnotificationrequest) - Practical notification patterns
- [Add launch at login setting | Nil Coalescing](https://nilcoalescing.com/blog/LaunchAtLoginSetting/) - SMAppService SwiftUI implementation
- [macOS Service Management - SMAppService | theevilbit](https://theevilbit.github.io/posts/smappservice/) - Detailed SMAppService status enum reference

### Secondary (MEDIUM confidence)
- [UserNotifications delegate | Apple Forums](https://developer.apple.com/forums/thread/60722) - Foreground notification handling
- [removeDeliveredNotifications | Apple Documentation](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter/1649500-removedeliverednotifications) - Notification management
- [Integrating SwiftUI with macOS Notifications | peerdh](https://peerdh.com/blogs/programming-insights/integrating-swiftui-with-macos-notifications-for-real-time-updates-1) - macOS notification patterns

### Tertiary (LOW confidence)
- SMAppService Error 108 on macOS 15 Sequoia -- reported in forums but not confirmed as blocking issue for login items

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All Apple frameworks, well-documented
- Architecture patterns: HIGH - Based on Phase 1 established patterns
- Notification API: HIGH - UNUserNotificationCenter is mature and stable
- SMAppService: MEDIUM - Some macOS 15 edge cases reported, but mainApp login items appear stable
- Pitfalls: HIGH - Each based on documented API behavior or common development patterns

**Research date:** 2026-02-13
**Valid until:** ~2026-03-15 (30 days; APIs are stable)

---
*Phase research for: ClaudeMon Phase 2 -- Alerts & Notifications*
*Researched: 2026-02-13*
