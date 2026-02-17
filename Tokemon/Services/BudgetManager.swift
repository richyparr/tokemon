import Foundation
import UserNotifications

/// Manages budget tracking, cost fetching, and budget threshold alerts.
/// Fetches cost data from the Admin API and monitors spend against the configured monthly budget.
@Observable
@MainActor
final class BudgetManager {

    // MARK: - Notifications

    /// Posted when budget configuration changes (for UI refresh)
    static let configChangedNotification = Notification.Name("BudgetManager.configChanged")

    // MARK: - Published State

    /// Budget configuration (monthly limit, thresholds, enabled state)
    var config: BudgetConfig

    /// Total dollars spent in the current calendar month
    var currentMonthSpend: Double = 0.0

    /// Daily cost breakdown for the current month (for forecasting)
    var dailyCostData: [(date: Date, cost: Double)] = []

    /// Cost by workspace for project-level attribution (BUDG-04)
    var projectCosts: [(workspaceId: String, cost: Double)] = []

    /// Whether a cost fetch is in progress
    var isLoading: Bool = false

    /// Error message from last fetch attempt
    var errorMessage: String? = nil

    // MARK: - Private State

    /// Tracks which budget thresholds have been notified this month
    @ObservationIgnored
    private var notifiedThresholds: Set<Int> = []

    /// Calendar month of last fetch (to detect month rollover and reset notifiedThresholds)
    @ObservationIgnored
    private var lastFetchMonth: Int = 0

    /// Whether we're running as a proper app bundle (required for notifications)
    @ObservationIgnored
    private let hasAppBundle: Bool = Bundle.main.bundleIdentifier != nil

    // MARK: - Initialization

    init() {
        self.config = BudgetConfig.load()
    }

    // MARK: - Configuration

    /// Save current config to UserDefaults and notify observers.
    func saveConfig() {
        BudgetConfig.save(config)
        NotificationCenter.default.post(name: BudgetManager.configChangedNotification, object: nil)
    }

    // MARK: - Cost Fetching

    /// Fetch current month cost data from the Admin API.
    /// Populates currentMonthSpend, dailyCostData, and projectCosts.
    func fetchCurrentMonthCost() async {
        isLoading = true
        errorMessage = nil

        do {
            // Calculate date range: start of current calendar month to now
            let calendar = Calendar.current
            let now = Date()
            let components = calendar.dateComponents([.year, .month], from: now)
            guard let monthStart = calendar.date(from: components) else {
                errorMessage = "Failed to calculate month start"
                isLoading = false
                return
            }

            // Detect month rollover and reset notification state
            let currentMonth = calendar.component(.month, from: now)
            if currentMonth != lastFetchMonth && lastFetchMonth != 0 {
                notifiedThresholds.removeAll()
            }
            lastFetchMonth = currentMonth

            // Fetch total cost for the month (daily buckets)
            let costResponse = try await AdminAPIClient.shared.fetchAllCostData(
                startingAt: monthStart,
                endingAt: now,
                bucketWidth: "1d"
            )

            // Fetch cost grouped by workspace
            let workspaceResponse = try await AdminAPIClient.shared.fetchCostByWorkspace(
                startingAt: monthStart,
                endingAt: now
            )

            // Update total month spend
            currentMonthSpend = costResponse.totalCost

            // Build daily cost data from buckets
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime]

            dailyCostData = costResponse.data.compactMap { bucket in
                guard let date = isoFormatter.date(from: bucket.startingAt) else { return nil }
                return (date: date, cost: bucket.totalCost)
            }

            // Build project costs from workspace-grouped results
            var workspaceTotals: [String: Double] = [:]
            for bucket in workspaceResponse.data {
                for result in bucket.results {
                    let id = result.workspaceId ?? "unknown"
                    let costDollars = (Double(result.amount) ?? 0) / 100.0
                    workspaceTotals[id, default: 0] += costDollars
                }
            }
            projectCosts = workspaceTotals.map { (workspaceId: $0.key, cost: $0.value) }
                .sorted { $0.cost > $1.cost }

            // Check budget thresholds after fetching
            checkBudgetThresholds()

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Budget Thresholds

    /// Check if current spend has crossed any budget thresholds and send notifications.
    func checkBudgetThresholds() {
        guard config.isEnabled, config.monthlyLimitDollars > 0 else { return }

        let spendPercentage = (currentMonthSpend / config.monthlyLimitDollars) * 100

        for threshold in config.alertThresholds {
            if spendPercentage >= Double(threshold) && !notifiedThresholds.contains(threshold) {
                notifiedThresholds.insert(threshold)
                sendBudgetNotification(threshold: threshold, spendPercentage: spendPercentage)
            }
        }
    }

    // MARK: - Budget Utilization

    /// Current budget utilization as a percentage (0-100+).
    /// Returns 0 if budget limit is 0 or not configured.
    var budgetUtilization: Double {
        guard config.monthlyLimitDollars > 0 else { return 0 }
        return (currentMonthSpend / config.monthlyLimitDollars) * 100
    }

    // MARK: - Private Methods

    /// Send a budget threshold notification via macOS notification center.
    private func sendBudgetNotification(threshold: Int, spendPercentage: Double) {
        guard hasAppBundle else {
            print("[BudgetManager] No app bundle, skipping budget notification")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Budget Alert"
        content.subtitle = "Tokemon"
        content.body = String(
            format: "You've spent %.0f%% of your $%.0f monthly budget.",
            spendPercentage,
            config.monthlyLimitDollars
        )
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let uniqueId = "tokemon.budget.\(threshold).\(Date().timeIntervalSince1970)"

        let request = UNNotificationRequest(
            identifier: uniqueId,
            content: content,
            trigger: nil
        )

        print("[BudgetManager] Sending budget notification: \(threshold)% threshold crossed (\(String(format: "%.1f", spendPercentage))% spent)")

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[BudgetManager] Budget notification error: \(error.localizedDescription)")
            }
        }
    }
}
