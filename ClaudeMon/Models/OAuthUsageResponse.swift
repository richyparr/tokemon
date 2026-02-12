import Foundation

/// Codable model for the OAuth /api/oauth/usage response.
/// Maps the JSON response from https://api.anthropic.com/api/oauth/usage
struct OAuthUsageResponse: Codable, Sendable {
    let fiveHour: UsageWindow?
    let sevenDay: UsageWindow?
    let sevenDayOauthApps: UsageWindow?
    let sevenDayOpus: UsageWindow?

    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
        case sevenDayOauthApps = "seven_day_oauth_apps"
        case sevenDayOpus = "seven_day_opus"
    }

    /// A single usage time window with utilization percentage and reset time.
    struct UsageWindow: Codable, Sendable {
        /// Utilization percentage (0-100)
        let utilization: Double
        /// ISO-8601 timestamp when this window resets
        let resetsAt: String?

        enum CodingKeys: String, CodingKey {
            case utilization
            case resetsAt = "resets_at"
        }
    }

    /// Convert this API response into a UsageSnapshot for display.
    /// Uses fiveHour.utilization as primaryPercentage (most relevant for real-time monitoring).
    func toSnapshot() -> UsageSnapshot {
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var resetsAtDate: Date?
        if let resetsAtString = fiveHour?.resetsAt {
            resetsAtDate = iso8601Formatter.date(from: resetsAtString)
        }

        return UsageSnapshot(
            primaryPercentage: fiveHour?.utilization ?? 0,
            fiveHourUtilization: fiveHour?.utilization,
            sevenDayUtilization: sevenDay?.utilization,
            sevenDayOpusUtilization: sevenDayOpus?.utilization,
            resetsAt: resetsAtDate,
            source: .oauth,
            inputTokens: nil,
            outputTokens: nil,
            cacheCreationTokens: nil,
            cacheReadTokens: nil,
            model: nil
        )
    }
}
