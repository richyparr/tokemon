import Foundation

/// Service for sending usage alert webhooks to Slack and Discord.
/// Formats messages using Slack Block Kit and Discord embed formats.
/// Fire-and-forget delivery -- only testWebhook throws on failure.
@Observable
@MainActor
final class WebhookManager {

    // MARK: - Types

    /// Supported webhook destination services
    enum WebhookService: String, CaseIterable, Sendable {
        case slack
        case discord
    }

    /// Alert severity level (local to WebhookManager to avoid coupling with AlertManager)
    enum AlertLevel: Sendable {
        case warning
        case critical
    }

    // MARK: - State

    /// Webhook configuration loaded from UserDefaults, saved on change
    var config: WebhookConfig {
        didSet {
            config.save()
        }
    }

    /// Whether we've notified about warning level this usage window
    @ObservationIgnored
    private var hasNotifiedWarning: Bool = false

    /// Whether we've notified about critical level this usage window
    @ObservationIgnored
    private var hasNotifiedCritical: Bool = false

    /// Tracks the window reset timestamp (rounded to minute) to detect new windows
    @ObservationIgnored
    private var lastResetsAtMinute: Int = 0

    // MARK: - Initialization

    init() {
        self.config = WebhookConfig.load() ?? .default
    }

    // MARK: - Public Methods

    /// Check usage and send webhook notifications if thresholds are met.
    /// Mirrors AlertManager's logic: fires once per level per usage window.
    ///
    /// - Parameters:
    ///   - usage: Current usage snapshot
    ///   - alertThreshold: Warning threshold percentage (e.g. 80)
    func checkUsageAndNotify(_ usage: UsageSnapshot, alertThreshold: Int) {
        guard usage.hasPercentage else { return }
        guard config.hasAnyWebhook else { return }

        // Detect window reset by comparing reset time rounded to minutes
        if let resetsAt = usage.resetsAt {
            let resetsAtMinute = Int(resetsAt.timeIntervalSince1970 / 60)
            if resetsAtMinute != lastResetsAtMinute {
                print("[WebhookManager] Usage window reset detected, clearing notification state")
                resetNotificationState()
                lastResetsAtMinute = resetsAtMinute
            }
        }

        let percentage = Int(usage.primaryPercentage)

        // Calculate alert level
        if percentage >= 100 && !hasNotifiedCritical {
            hasNotifiedCritical = true
            sendWebhook(level: .critical, usage: usage)
        } else if percentage >= alertThreshold && !hasNotifiedWarning {
            hasNotifiedWarning = true
            sendWebhook(level: .warning, usage: usage)
        }
    }

    /// Reset notification flags (called on window reset or manually)
    func resetNotificationState() {
        hasNotifiedWarning = false
        hasNotifiedCritical = false
    }

    /// Send a test message to verify the webhook URL works.
    /// Throws on HTTP error so the UI can report success/failure.
    ///
    /// - Parameter service: Which webhook service to test
    func testWebhook(service: WebhookService) async throws {
        switch service {
        case .slack:
            guard !config.slackWebhookURL.isEmpty else {
                throw WebhookError.noURL
            }
            try await sendSlackTest()
        case .discord:
            guard !config.discordWebhookURL.isEmpty else {
                throw WebhookError.noURL
            }
            try await sendDiscordTest()
        }
    }

    // MARK: - Private: Dispatch

    /// Fire-and-forget webhook delivery to all enabled services
    private func sendWebhook(level: AlertLevel, usage: UsageSnapshot) {
        let currentConfig = config
        Task.detached { [currentConfig] in
            if currentConfig.hasSlack {
                do {
                    try await Self.sendSlackPayload(level: level, usage: usage, config: currentConfig)
                } catch {
                    print("[WebhookManager] Slack send failed: \(error.localizedDescription)")
                }
            }
            if currentConfig.hasDiscord {
                do {
                    try await Self.sendDiscordPayload(level: level, usage: usage, config: currentConfig)
                } catch {
                    print("[WebhookManager] Discord send failed: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Private: Slack

    /// Send a Slack Block Kit formatted payload
    private static func sendSlackPayload(level: AlertLevel, usage: UsageSnapshot, config: WebhookConfig) async throws {
        let emoji: String
        let title: String
        switch level {
        case .warning:
            emoji = ":warning:"
            title = "Usage Warning"
        case .critical:
            emoji = ":rotating_light:"
            title = "Usage Limit Reached"
        }

        var blocks: [[String: Any]] = []

        // Header block
        blocks.append([
            "type": "header",
            "text": [
                "type": "plain_text",
                "text": "\(emoji) \(title)",
                "emoji": true
            ] as [String: Any]
        ])

        // Section block with fields
        var fields: [[String: Any]] = []

        if config.includePercentage {
            fields.append([
                "type": "mrkdwn",
                "text": "*Usage:* \(Int(usage.primaryPercentage))%"
            ])
        }

        if config.includeResetTime, let resetsAt = usage.resetsAt {
            fields.append([
                "type": "mrkdwn",
                "text": "*Resets:* \(formatResetTime(resetsAt))"
            ])
        }

        if config.includeWeeklyUsage, let weekly = usage.sevenDayUtilization {
            fields.append([
                "type": "mrkdwn",
                "text": "*Weekly:* \(Int(weekly))%"
            ])
        }

        if config.includeProfileName {
            let profileName = activeProfileName()
            fields.append([
                "type": "mrkdwn",
                "text": "*Profile:* \(profileName)"
            ])
        }

        if !fields.isEmpty {
            blocks.append([
                "type": "section",
                "fields": fields
            ])
        }

        // Custom message context block
        if !config.customMessage.isEmpty {
            blocks.append([
                "type": "context",
                "elements": [
                    [
                        "type": "mrkdwn",
                        "text": config.customMessage
                    ]
                ]
            ])
        }

        let payload: [String: Any] = ["blocks": blocks]
        try await postJSON(payload, to: config.slackWebhookURL)
    }

    /// Send a test message to Slack
    private func sendSlackTest() async throws {
        let payload: [String: Any] = [
            "blocks": [
                [
                    "type": "header",
                    "text": [
                        "type": "plain_text",
                        "text": ":white_check_mark: Tokemon Webhook Test",
                        "emoji": true
                    ] as [String: Any]
                ],
                [
                    "type": "section",
                    "text": [
                        "type": "mrkdwn",
                        "text": "Your Slack webhook is configured correctly. You'll receive usage alerts here."
                    ]
                ]
            ]
        ]
        try await Self.postJSON(payload, to: config.slackWebhookURL)
    }

    // MARK: - Private: Discord

    /// Send a Discord embed formatted payload
    private static func sendDiscordPayload(level: AlertLevel, usage: UsageSnapshot, config: WebhookConfig) async throws {
        let title: String
        let color: Int
        switch level {
        case .warning:
            title = "Usage Warning"
            color = 16776960 // Yellow
        case .critical:
            title = "Usage Limit Reached"
            color = 16711680 // Red
        }

        var fields: [[String: Any]] = []

        if config.includePercentage {
            fields.append([
                "name": "Usage",
                "value": "\(Int(usage.primaryPercentage))%",
                "inline": true
            ])
        }

        if config.includeResetTime, let resetsAt = usage.resetsAt {
            fields.append([
                "name": "Resets",
                "value": formatResetTime(resetsAt),
                "inline": true
            ])
        }

        if config.includeWeeklyUsage, let weekly = usage.sevenDayUtilization {
            fields.append([
                "name": "Weekly",
                "value": "\(Int(weekly))%",
                "inline": true
            ])
        }

        if config.includeProfileName {
            let profileName = activeProfileName()
            fields.append([
                "name": "Profile",
                "value": profileName,
                "inline": true
            ])
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        var embed: [String: Any] = [
            "title": title,
            "color": color,
            "fields": fields,
            "footer": ["text": "Tokemon"] as [String: Any],
            "timestamp": formatter.string(from: Date())
        ]

        if !config.customMessage.isEmpty {
            embed["description"] = config.customMessage
        }

        let payload: [String: Any] = [
            "embeds": [embed]
        ]
        try await postJSON(payload, to: config.discordWebhookURL)
    }

    /// Send a test message to Discord
    private func sendDiscordTest() async throws {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        let embed: [String: Any] = [
            "title": "Tokemon Webhook Test",
            "description": "Your Discord webhook is configured correctly. You'll receive usage alerts here.",
            "color": 5763719, // Green
            "footer": ["text": "Tokemon"] as [String: Any],
            "timestamp": formatter.string(from: Date())
        ]

        let payload: [String: Any] = [
            "embeds": [embed]
        ]
        try await Self.postJSON(payload, to: config.discordWebhookURL)
    }

    // MARK: - Private: Helpers

    /// Format a reset date as human-readable relative time (e.g., "in 2h 15m" or "in 45m")
    private static func formatResetTime(_ date: Date) -> String {
        let interval = date.timeIntervalSinceNow
        guard interval > 0 else { return "now" }

        let totalMinutes = Int(interval / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return "in \(hours)h \(minutes)m"
        } else {
            return "in \(minutes)m"
        }
    }

    /// Get the active profile name from UserDefaults, or "Default" if not found
    private static func activeProfileName() -> String {
        guard let activeIdString = UserDefaults.standard.string(forKey: Constants.activeProfileIdKey),
              let activeId = UUID(uuidString: activeIdString),
              let data = UserDefaults.standard.data(forKey: Constants.profilesStorageKey) else {
            return "Default"
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let profiles = try? decoder.decode([Profile].self, from: data),
              let active = profiles.first(where: { $0.id == activeId }) else {
            return "Default"
        }

        return active.name
    }

    /// POST JSON payload to a webhook URL
    private static func postJSON(_ payload: [String: Any], to urlString: String) async throws {
        guard let url = URL(string: urlString) else {
            throw WebhookError.invalidURL
        }

        let jsonData = try JSONSerialization.data(withJSONObject: payload)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WebhookError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw WebhookError.httpError(statusCode: httpResponse.statusCode)
        }
    }

    // MARK: - Error

    /// Webhook-specific errors
    enum WebhookError: LocalizedError {
        case noURL
        case invalidURL
        case invalidResponse
        case httpError(statusCode: Int)

        var errorDescription: String? {
            switch self {
            case .noURL:
                return "No webhook URL configured"
            case .invalidURL:
                return "Invalid webhook URL"
            case .invalidResponse:
                return "Invalid response from webhook"
            case .httpError(let statusCode):
                return "Webhook returned HTTP \(statusCode)"
            }
        }
    }
}
