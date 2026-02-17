import Foundation

/// Configuration model for terminal statusline export.
/// Persisted to UserDefaults as a JSON blob.
struct StatuslineConfig: Codable, Sendable {
    /// Master toggle for statusline export
    var enabled: Bool

    /// Show 5-hour session percentage
    var showSessionPercent: Bool

    /// Show 7-day weekly percentage
    var showWeeklyPercent: Bool

    /// Show time until reset
    var showResetTimer: Bool

    /// Field separator string
    var separator: String

    /// Whether to include ANSI color codes in color output file
    var useColors: Bool

    /// Prefix before statusline content
    var prefix: String

    /// Suffix after statusline content
    var suffix: String

    /// Default configuration
    static let defaultConfig = StatuslineConfig(
        enabled: false,
        showSessionPercent: true,
        showWeeklyPercent: true,
        showResetTimer: true,
        separator: " | ",
        useColors: true,
        prefix: "[",
        suffix: "]"
    )

    /// Load configuration from UserDefaults
    static func load() -> StatuslineConfig {
        guard let data = UserDefaults.standard.data(forKey: Constants.statuslineConfigKey),
              let config = try? JSONDecoder().decode(StatuslineConfig.self, from: data) else {
            return .defaultConfig
        }
        return config
    }

    /// Save configuration to UserDefaults
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Constants.statuslineConfigKey)
        }
    }
}
