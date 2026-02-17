import Foundation

/// Configuration model for budget tracking (monthly dollar limit and alert thresholds).
/// Persisted via UserDefaults as JSON, following the same pattern as WebhookConfig.
struct BudgetConfig: Codable, Sendable {

    // MARK: - Properties

    /// Whether budget tracking is enabled
    var isEnabled: Bool = false

    /// Monthly spending limit in USD
    var monthlyLimitDollars: Double = 100.0

    /// Budget alert threshold percentages (e.g., notify at 50%, 75%, 90% of budget)
    var alertThresholds: [Int] = [50, 75, 90]

    // MARK: - Persistence

    /// Load configuration from UserDefaults. Returns default config if not stored or decode fails.
    static func load() -> BudgetConfig {
        guard let data = UserDefaults.standard.data(forKey: Constants.budgetConfigKey) else {
            return BudgetConfig()
        }
        return (try? JSONDecoder().decode(BudgetConfig.self, from: data)) ?? BudgetConfig()
    }

    /// Save configuration to UserDefaults as JSON.
    static func save(_ config: BudgetConfig) {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: Constants.budgetConfigKey)
        }
    }
}
