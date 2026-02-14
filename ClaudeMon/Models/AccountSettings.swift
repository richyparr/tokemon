import Foundation

/// Per-account preferences mirroring global settings but scoped to a single account.
/// Stored as part of the Account struct in ClaudeMon's keychain service.
struct AccountSettings: Codable, Sendable {

    /// Usage percentage at which to trigger an alert (0-100)
    var alertThreshold: Int

    /// Whether push notifications are enabled for this account
    var notificationsEnabled: Bool

    /// Optional monthly budget in cents (nil means no budget set)
    var monthlyBudgetCents: Int?

    // MARK: - Initialization

    init(alertThreshold: Int = 80, notificationsEnabled: Bool = true, monthlyBudgetCents: Int? = nil) {
        self.alertThreshold = alertThreshold
        self.notificationsEnabled = notificationsEnabled
        self.monthlyBudgetCents = monthlyBudgetCents
    }
}
