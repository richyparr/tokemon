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

    /// Timestamp of the last SUCCESSFUL OAuth data fetch (not rate-limited cache hits)
    @ObservationIgnored
    private var lastOAuthFetchTime: Date?

    /// Consecutive 429 count for backoff calculation
    @ObservationIgnored
    private var rateLimitHits: Int = 0

    /// Maximum age (in seconds) for cached OAuth data before falling through to JSONL on rate limit.
    /// The usage API rate limits to ~1 request per 2 minutes, so cached data within 10 minutes
    /// is still reasonably accurate. The alternative (JSONL) shows only token counts with no percentage.
    @ObservationIgnored
    private let maxCachedDataAge: TimeInterval = 600

    // MARK: - Computed Properties

    /// Menu bar display text, delegated to the current usage snapshot
    var menuBarText: String {
        currentUsage.menuBarText
    }

    /// How old the current OAuth data is (nil if source is not OAuth or no fetch recorded)
    var oauthDataAge: TimeInterval? {
        guard currentUsage.source == .oauth, let fetchTime = lastOAuthFetchTime else { return nil }
        return Date().timeIntervalSince(fetchTime)
    }

    /// Whether the current display is showing cached (stale) OAuth data due to rate limiting
    var isShowingCachedData: Bool {
        if case .oauthRateLimited = error, currentUsage.source == .oauth {
            return true
        }
        return false
    }

    // MARK: - Settings (UserDefaults-backed)

    /// Minimum polling interval — usage API rate limits to ~1 request per 2 minutes.
    @ObservationIgnored
    private let minimumRefreshInterval: TimeInterval = 150

    /// Polling interval in seconds
    var refreshInterval: TimeInterval {
        get {
            let stored = UserDefaults.standard.double(forKey: "refreshInterval")
            let interval = stored > 0 ? stored : Constants.defaultRefreshInterval
            // Enforce minimum to respect API rate limits
            return max(interval, minimumRefreshInterval)
        }
        set {
            UserDefaults.standard.set(max(newValue, minimumRefreshInterval), forKey: "refreshInterval")
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
    /// Stored property with didSet for SwiftUI reactivity (computed properties don't trigger @Observable updates)
    var showExtraUsage: Bool = UserDefaults.standard.object(forKey: "showExtraUsage") as? Bool ?? true {
        didSet { UserDefaults.standard.set(showExtraUsage, forKey: "showExtraUsage") }
    }

    // MARK: - Multi-Profile

    /// Reference to ProfileManager for multi-profile polling (set by TokemonApp after init)
    @ObservationIgnored
    var profileManager: ProfileManager?

    // MARK: - Callbacks

    /// Callback invoked when currentUsage changes, used to update NSStatusItem.
    /// Set by TokemonApp after the status item is available.
    @ObservationIgnored
    var onUsageChanged: ((_ usage: UsageSnapshot) -> Void)?

    /// Callback invoked to check alert thresholds after each refresh.
    /// Set by TokemonApp to wire AlertManager.checkUsage.
    @ObservationIgnored
    var onAlertCheck: ((_ usage: UsageSnapshot) -> Void)?

    /// Callback invoked to export usage to statusline files after each refresh.
    /// Set by TokemonApp to wire StatuslineExporter.export.
    @ObservationIgnored
    var onStatuslineExport: ((_ usage: UsageSnapshot) -> Void)?

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
        case oauthRateLimited
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
                print("[Tokemon] Failed to load history: \(error)")
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
            reason: "Tokemon usage monitoring"
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
        guard !requiresManualRetry else { return
        }

        isRefreshing = true
        defer { isRefreshing = false }

        // Step 1: Try OAuth (primary source)
        if oauthEnabled {
            do {
                let response = try await OAuthClient.fetchUsageWithTokenRefresh()
                currentUsage = response.toSnapshot()
                oauthState = .available
                lastUpdated = Date()
                lastOAuthFetchTime = Date()
                error = nil
                // Reset retry counters on success
                oauthRetryCount = 0
                retryCount = 0
                oauthFailureNotified = false
                // Reset rate limit backoff — restore normal polling
                if rateLimitHits > 0 {
                    rateLimitHits = 0
                    startPolling()
                }
                // Notify status item, alert manager, and statusline exporter
                onUsageChanged?(currentUsage)
                onAlertCheck?(currentUsage)
                onStatuslineExport?(currentUsage)
                // Record to history
                await recordHistory(for: currentUsage)
                // Update active profile's cached usage and fetch all other profiles
                if let profileManager, let activeId = profileManager.activeProfileId {
                    profileManager.updateProfileUsage(profileId: activeId, usage: currentUsage)
                }
                await refreshAllProfiles()
                return
            } catch OAuthClient.OAuthError.rateLimited {
                // Rate limited (429) -- common during active Claude Code sessions.
                rateLimitHits += 1

                // Back off: 5min, 10min, capped at 10min
                let backoffSeconds = min(600, TimeInterval(rateLimitHits) * 300)
                print("[Tokemon] Rate limited (\(rateLimitHits)x), backing off to \(Int(backoffSeconds))s")
                startPolling(interval: backoffSeconds)

                // Only keep cached data if it's recent enough to still be accurate.
                let cachedAge = lastOAuthFetchTime.map { Date().timeIntervalSince($0) }
                if let age = cachedAge, currentUsage.source == .oauth, age < maxCachedDataAge {
                    print("[Tokemon] Keeping cached OAuth data (\(Int(age))s old)")
                    error = .oauthRateLimited
                    return
                }
                // Cached data is stale or doesn't exist -- fall through to JSONL
                let ageStr = cachedAge.map { "\(Int($0))s" } ?? "none"
                print("[Tokemon] Cached data too old (\(ageStr)), trying JSONL")
                oauthState = .failed("Rate limited")
            } catch {
                print("[Tokemon] OAuth failed: \(error) — \(error.localizedDescription)")
                oauthState = .failed(error.localizedDescription)
                oauthRetryCount += 1

                // Notify user ONCE about OAuth failure
                if !oauthFailureNotified {
                    oauthFailureNotified = true
                    print("[Tokemon] OAuth unavailable, switching to backup data source")
                    self.error = .oauthFailed("Switching to local session logs")
                }
            }
        }

        // Step 2: Try JSONL fallback
        let isRateLimited = {
            if case .failed(let msg) = oauthState, msg == "Rate limited" { return true }
            return false
        }()

        if jsonlEnabled {
            do {
                // Use 5-hour window to match the OAuth endpoint's window
                let fiveHoursAgo = Date().addingTimeInterval(-5 * 3600)
                let aggregate = try JSONLParser.parseRecentUsage(since: fiveHoursAgo)
                currentUsage = JSONLParser.toSnapshot(from: aggregate)
                jsonlState = .available
                lastUpdated = Date()
                // Set error context based on WHY we fell back
                if !oauthEnabled || isRateLimited {
                    // Rate limited during active session is expected -- no banner needed
                    error = nil
                } else {
                    // Genuine OAuth failure -- show backup source message with refresh guidance
                    error = .oauthFailed("Using local session logs. To restore full data, run /exit then /login in Claude Code.")
                }
                // Reset total retry counter on any success
                retryCount = 0
                // Notify status item, alert manager, and statusline exporter
                onUsageChanged?(currentUsage)
                onAlertCheck?(currentUsage)
                onStatuslineExport?(currentUsage)
                // Record to history
                await recordHistory(for: currentUsage)
                // Update active profile's cached usage and fetch all other profiles
                if let profileManager, let activeId = profileManager.activeProfileId {
                    profileManager.updateProfileUsage(profileId: activeId, usage: currentUsage)
                }
                await refreshAllProfiles()
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
            print("[Tokemon] Max retry attempts (\(Constants.maxRetryAttempts)) reached. Manual retry required.")
        }

        // Still notify status item, alert manager, and statusline exporter (error state may change display)
        onUsageChanged?(currentUsage)
        onAlertCheck?(currentUsage)
        onStatuslineExport?(currentUsage)
    }

    /// Manual retry: resets counters and restarts polling.
    /// Called from UI when the user taps a "Retry" button after auto-retry exhaustion.
    func manualRefresh() {
        retryCount = 0
        oauthRetryCount = 0
        requiresManualRetry = false
        oauthFailureNotified = false
        lastOAuthFetchTime = nil
        oauthState = .available
        jsonlState = .available
        startPolling()
    }

    // MARK: - History Recording

    /// Record a usage snapshot to the history store.
    /// Errors are logged but do not interrupt the refresh flow.
    private func recordHistory(for usage: UsageSnapshot) async {
        let dataPoint = UsageDataPoint(from: usage)
        do {
            try await historyStore.append(dataPoint)
            self.usageHistory = await historyStore.getHistory()
        } catch {
            print("[Tokemon] Failed to record history: \(error)")
        }
    }

    /// Reload history from store (for UI refresh).
    func reloadHistory() async {
        usageHistory = await historyStore.getHistory()
    }

    // MARK: - Multi-Profile Polling

    /// Fetch usage for all profiles simultaneously (for PROF-06 multi-profile display).
    /// Updates each profile's lastUsage in ProfileManager.
    /// Called after the main refresh() completes successfully.
    func refreshAllProfiles() async {
        guard let profileManager else { return }

        // Fetch usage for all profiles that have credentials (excluding active -- already fetched)
        let otherProfiles = profileManager.profiles.filter {
            $0.id != profileManager.activeProfileId && $0.hasCredentials
        }

        guard !otherProfiles.isEmpty else { return }

        // Use TaskGroup for parallel fetching
        await withTaskGroup(of: (UUID, UsageSnapshot?).self) { group in
            for profile in otherProfiles {
                group.addTask {
                    do {
                        let response: OAuthUsageResponse
                        if let credJSON = profile.cliCredentialsJSON {
                            response = try await OAuthClient.fetchUsageWithCredentials(credJSON)
                        } else if let sessionKey = profile.claudeSessionKey {
                            response = try await OAuthClient.fetchUsageWithSessionKey(
                                sessionKey,
                                orgId: profile.organizationId
                            )
                        } else {
                            return (profile.id, nil)
                        }
                        return (profile.id, response.toSnapshot())
                    } catch {
                        print("[UsageMonitor] Failed to fetch usage for profile \(profile.name): \(error)")
                        return (profile.id, nil)
                    }
                }
            }

            for await (profileId, snapshot) in group {
                if let snapshot {
                    profileManager.updateProfileUsage(profileId: profileId, usage: snapshot)
                }
            }
        }
    }

    // Note: No deinit needed -- the UsageMonitor lives for the lifetime of the app.
    // Swift 6 strict concurrency does not allow @MainActor property access in deinit.
}
