import Foundation
import AppKit

/// Central state manager for Claude usage monitoring.
/// Manages polling, data source state, and the current usage snapshot.
/// Uses @Observable for fine-grained SwiftUI reactivity (macOS 14+).
@Observable
@MainActor
final class UsageMonitor {

    // MARK: - Published State

    /// Current usage snapshot displayed in menu bar and popover
    var currentUsage: UsageSnapshot = .empty

    /// Whether a refresh is currently in progress
    var isRefreshing: Bool = false

    /// Timestamp of the last successful data update
    var lastUpdated: Date?

    /// Current error state, if any
    var error: MonitorError?

    /// OAuth data source availability
    var oauthState: DataSourceState = .available

    /// JSONL data source availability
    var jsonlState: DataSourceState = .available

    // MARK: - Computed Properties

    /// Menu bar display text, delegated to the current usage snapshot
    var menuBarText: String {
        currentUsage.menuBarText
    }

    // MARK: - Settings (UserDefaults-backed)

    /// Polling interval in seconds
    var refreshInterval: TimeInterval {
        get {
            let stored = UserDefaults.standard.double(forKey: "refreshInterval")
            return stored > 0 ? stored : Constants.defaultRefreshInterval
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "refreshInterval")
        }
    }

    /// Whether OAuth data source is enabled
    var oauthEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "oauthEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "oauthEnabled") }
    }

    /// Whether JSONL data source is enabled
    var jsonlEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "jsonlEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "jsonlEnabled") }
    }

    // MARK: - Private

    private var pollTimer: Timer?
    private var activity: NSObjectProtocol?

    // MARK: - Error Type

    /// Errors that can occur during usage monitoring
    enum MonitorError: Error, Sendable {
        case oauthFailed(String)
        case jsonlFailed(String)
        case bothSourcesFailed(String)
        case tokenExpired
        case insufficientScope
    }

    // MARK: - Initialization

    init() {
        startPolling()
    }

    // MARK: - Polling

    /// Start the polling timer with App Nap prevention.
    /// The timer fires at the configured interval, calling refresh() each time.
    func startPolling(interval: TimeInterval? = nil) {
        stopPolling()

        let pollInterval = interval ?? refreshInterval

        // Prevent App Nap from throttling our background timer
        activity = ProcessInfo.processInfo.beginActivity(
            options: [.background, .idleSystemSleepDisabled],
            reason: "ClaudeMon usage monitoring"
        )

        // Schedule repeating timer
        pollTimer = Timer.scheduledTimer(
            withTimeInterval: pollInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.refresh()
            }
        }

        // Immediate first fetch
        Task { await refresh() }
    }

    /// Stop the polling timer and release App Nap prevention.
    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
        if let activity {
            ProcessInfo.processInfo.endActivity(activity)
        }
        self.activity = nil
    }

    /// Refresh usage data from configured sources.
    /// For now uses mock data; real implementation comes in Plan 02.
    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        // Simulate network delay
        try? await Task.sleep(for: .milliseconds(500))

        // Mock data: random percentage between 20-80
        let mockPercentage = Double.random(in: 20...80)
        let mockSevenDay = Double.random(in: 10...50)

        currentUsage = UsageSnapshot(
            primaryPercentage: mockPercentage,
            fiveHourUtilization: mockPercentage,
            sevenDayUtilization: mockSevenDay,
            sevenDayOpusUtilization: 0,
            resetsAt: Date().addingTimeInterval(3600 * 2), // 2 hours from now
            source: .oauth,
            inputTokens: nil,
            outputTokens: nil,
            cacheCreationTokens: nil,
            cacheReadTokens: nil,
            model: nil
        )
        lastUpdated = Date()
        error = nil
    }

    // Note: No deinit needed -- the UsageMonitor lives for the lifetime of the app.
    // Swift 6 strict concurrency does not allow @MainActor property access in deinit.
}
