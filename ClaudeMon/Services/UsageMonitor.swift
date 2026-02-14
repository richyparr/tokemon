import Foundation
import AppKit

/// Central state manager for Claude usage monitoring.
/// Manages polling, data source state, and the current usage snapshot.
/// Implements the OAuth-primary / JSONL-fallback data chain with retry logic.
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

    // MARK: - Retry State

    /// Number of consecutive OAuth failures (resets on success)
    var oauthRetryCount: Int = 0

    /// Number of consecutive total failures (both sources, resets on success)
    var retryCount: Int = 0

    /// Whether manual retry is required (after maxRetryAttempts consecutive failures)
    var requiresManualRetry: Bool = false

    /// Whether the user has been notified about OAuth failure (fire once)
    @ObservationIgnored
    var oauthFailureNotified: Bool = false

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

    /// Whether to show extra usage (billing) section in popover
    var showExtraUsage: Bool {
        get { UserDefaults.standard.object(forKey: "showExtraUsage") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "showExtraUsage") }
    }

    // MARK: - Callbacks

    /// Callback invoked when currentUsage changes, used to update NSStatusItem.
    /// Set by ClaudeMonApp after the status item is available.
    @ObservationIgnored
    var onUsageChanged: ((_ usage: UsageSnapshot) -> Void)?

    /// Callback invoked to check alert thresholds after each refresh.
    /// Set by ClaudeMonApp to wire AlertManager.checkUsage.
    @ObservationIgnored
    var onAlertCheck: ((_ usage: UsageSnapshot) -> Void)?

    /// Current account for account-specific data fetching (set by account change callback)
    @ObservationIgnored
    var currentAccount: Account?

    // MARK: - History

    /// History store for recording usage over time
    @ObservationIgnored
    private let historyStore = HistoryStore.shared

    /// Historical usage data points for trend visualization
    var usageHistory: [UsageDataPoint] = []

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

        // Load historical data
        Task {
            do {
                try await historyStore.load()
                self.usageHistory = await historyStore.getHistory()
            } catch {
                print("[ClaudeMon] Failed to load history: \(error)")
            }
        }
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

    // MARK: - Data Fetching

    /// Refresh usage data from configured sources.
    ///
    /// Priority chain:
    /// 1. Try OAuth (if enabled) -- provides percentage utilization
    /// 2. Fall back to JSONL (if enabled) -- provides token counts only
    /// 3. Both failed: increment retry counter, stop auto-retry after 3 attempts
    ///
    /// Error notification: OAuth failure notifies user once, then goes silent.
    func refresh() async {
        // Don't refresh if manual retry is required
        guard !requiresManualRetry else { return }

        isRefreshing = true
        defer { isRefreshing = false }

        // Step 1: Try OAuth (primary source)
        if oauthEnabled {
            do {
                let response: OAuthUsageResponse
                if let account = currentAccount {
                    response = try await OAuthClient.fetchUsageWithTokenRefresh(for: account)
                } else {
                    response = try await OAuthClient.fetchUsageWithTokenRefresh()
                }
                currentUsage = response.toSnapshot()
                oauthState = .available
                lastUpdated = Date()
                error = nil
                // Reset retry counters on success
                oauthRetryCount = 0
                retryCount = 0
                // Notify status item and alert manager
                onUsageChanged?(currentUsage)
                onAlertCheck?(currentUsage)
                // Record to history
                await recordHistory(for: currentUsage)
                return
            } catch {
                oauthState = .failed(error.localizedDescription)
                oauthRetryCount += 1

                // Notify user ONCE about OAuth failure
                if !oauthFailureNotified {
                    oauthFailureNotified = true
                    print("[ClaudeMon] OAuth unavailable, switching to backup data source")
                    self.error = .oauthFailed("Switching to backup data source")
                }
            }
        }

        // Step 2: Try JSONL fallback
        if jsonlEnabled {
            do {
                // Use 5-hour window to match the OAuth endpoint's window
                let fiveHoursAgo = Date().addingTimeInterval(-5 * 3600)
                let aggregate = try JSONLParser.parseRecentUsage(since: fiveHoursAgo)
                currentUsage = JSONLParser.toSnapshot(from: aggregate)
                jsonlState = .available
                lastUpdated = Date()
                // Clear the error -- we have data, even if from fallback
                if oauthEnabled {
                    // Keep the informational message about fallback, but don't block
                    error = .oauthFailed("Using backup data source (local session logs)")
                } else {
                    error = nil
                }
                // Reset total retry counter on any success
                retryCount = 0
                // Notify status item and alert manager
                onUsageChanged?(currentUsage)
                onAlertCheck?(currentUsage)
                // Record to history
                await recordHistory(for: currentUsage)
                return
            } catch {
                jsonlState = .failed(error.localizedDescription)
            }
        }

        // Step 3: Both sources failed
        let lastErrorMsg: String
        if case .failed(let msg) = oauthState {
            lastErrorMsg = msg
        } else if case .failed(let msg) = jsonlState {
            lastErrorMsg = msg
        } else {
            lastErrorMsg = "All data sources unavailable"
        }

        error = .bothSourcesFailed(lastErrorMsg)
        retryCount += 1

        if retryCount >= Constants.maxRetryAttempts {
            // Stop auto-retrying after max attempts
            stopPolling()
            requiresManualRetry = true
            print("[ClaudeMon] Max retry attempts (\(Constants.maxRetryAttempts)) reached. Manual retry required.")
        }

        // Still notify status item and alert manager (error state may change display)
        onUsageChanged?(currentUsage)
        onAlertCheck?(currentUsage)
    }

    /// Manual retry: resets counters and restarts polling.
    /// Called from UI when the user taps a "Retry" button after auto-retry exhaustion.
    func manualRefresh() {
        retryCount = 0
        oauthRetryCount = 0
        requiresManualRetry = false
        oauthFailureNotified = false
        oauthState = .available
        jsonlState = .available
        startPolling()
    }

    // MARK: - History Recording

    /// Record a usage snapshot to the history store.
    /// Uses per-account storage when an active account is set.
    /// Errors are logged but do not interrupt the refresh flow.
    private func recordHistory(for usage: UsageSnapshot) async {
        let dataPoint = UsageDataPoint(from: usage)
        do {
            if let accountId = currentAccount?.id {
                try await historyStore.append(dataPoint, for: accountId)
                self.usageHistory = await historyStore.getHistory(for: accountId)
            } else {
                // Legacy single-account behavior
                try await historyStore.append(dataPoint)
                self.usageHistory = await historyStore.getHistory()
            }
        } catch {
            print("[ClaudeMon] Failed to record history: \(error)")
        }
    }

    /// Reload history from store (for UI refresh).
    func reloadHistory() async {
        usageHistory = await historyStore.getHistory()
    }

    // Note: No deinit needed -- the UsageMonitor lives for the lifetime of the app.
    // Swift 6 strict concurrency does not allow @MainActor property access in deinit.
}
