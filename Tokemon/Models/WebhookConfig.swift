import Foundation

/// Configuration model for webhook alert destinations (Slack, Discord).
/// Stores URLs, enabled flags, and message template preferences.
/// Persisted via UserDefaults as JSON.
struct WebhookConfig: Codable, Sendable {

    // MARK: - Destination URLs

    /// Slack incoming webhook URL (empty string = not configured)
    var slackWebhookURL: String = ""

    /// Discord webhook URL (empty string = not configured)
    var discordWebhookURL: String = ""

    // MARK: - Enabled Flags

    /// Whether Slack notifications are active
    var slackEnabled: Bool = false

    /// Whether Discord notifications are active
    var discordEnabled: Bool = false

    // MARK: - Message Template Fields

    /// Include usage percentage in message
    var includePercentage: Bool = true

    /// Include time until reset in message
    var includeResetTime: Bool = true

    /// Include 7-day usage if available
    var includeWeeklyUsage: Bool = false

    /// Include which profile triggered the alert
    var includeProfileName: Bool = true

    /// Optional custom message prepended to alert (empty = none)
    var customMessage: String = ""

    // MARK: - Defaults

    /// Default configuration with all defaults applied
    static let `default` = WebhookConfig()

    // MARK: - Computed Helpers

    /// Whether Slack is both enabled and has a URL configured
    var hasSlack: Bool {
        slackEnabled && !slackWebhookURL.isEmpty
    }

    /// Whether Discord is both enabled and has a URL configured
    var hasDiscord: Bool {
        discordEnabled && !discordWebhookURL.isEmpty
    }

    /// Whether any webhook destination is active
    var hasAnyWebhook: Bool {
        hasSlack || hasDiscord
    }

    // MARK: - Persistence

    /// Save configuration to UserDefaults as JSON
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Constants.webhookConfigKey)
        }
    }

    /// Load configuration from UserDefaults. Returns nil if not stored or decode fails.
    static func load() -> WebhookConfig? {
        guard let data = UserDefaults.standard.data(forKey: Constants.webhookConfigKey) else {
            return nil
        }
        return try? JSONDecoder().decode(WebhookConfig.self, from: data)
    }
}
