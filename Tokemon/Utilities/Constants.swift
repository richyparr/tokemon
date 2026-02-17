import Foundation

/// App-wide constants for API endpoints, configuration defaults, and service identifiers.
enum Constants {
    /// OAuth usage endpoint URL
    static let oauthUsageURL = "https://api.anthropic.com/api/oauth/usage"

    /// OAuth token refresh endpoint URL
    static let oauthTokenRefreshURL = "https://console.anthropic.com/v1/oauth/token"

    /// Claude Code CLI OAuth client ID (official)
    static let oauthClientId = "9d1c250a-e61b-44d9-88ed-5944d1962f5e"

    /// macOS Keychain service name where Claude Code stores credentials
    static let keychainService = "Claude Code-credentials"

    /// Default polling interval in seconds
    static let defaultRefreshInterval: TimeInterval = 60

    /// Path to Claude Code project session files
    static let claudeProjectsPath = "~/.claude/projects/"

    /// Maximum number of retry attempts before requiring manual retry
    static let maxRetryAttempts = 3

    /// Default alert threshold percentage (warning fires at this level)
    static let defaultAlertThreshold = 80

    // MARK: - Multi-Account

    /// Keychain service name for Tokemon account metadata (separate from Claude Code credentials)
    static let accountsKeychainService = "ai.tokemon.accounts"

    // MARK: - Multi-Profile

    /// UserDefaults key for profile storage
    static let profilesStorageKey = "tokemon.profiles"

    /// UserDefaults key for active profile ID
    static let activeProfileIdKey = "tokemon.activeProfileId"

    /// Keychain service for Claude Code credentials (alias for keychainService).
    /// Used by ProfileManager for copy/switch operations -- reads FROM and writes TO
    /// Claude Code's keychain entry. Same value as `keychainService`; the alias
    /// makes the intent clearer in profile-related code.
    static let claudeCodeKeychainService = "Claude Code-credentials"

    // MARK: - Auto-Start Session

    /// UserDefaults key for auto-start session notification preference
    static let autoStartSessionKey = "tokemon.autoStartSession"

    // MARK: - Terminal Statusline

    /// Directory for statusline cache files (~/.tokemon)
    static let statuslineDirectory = "~/.tokemon"

    /// UserDefaults key for statusline configuration
    static let statuslineConfigKey = "tokemon.statuslineConfig"

    // MARK: - Sparkle Updates

    /// URL to appcast.xml hosted on GitHub Pages or releases
    static let sparkleAppcastURL = "https://tokemon.app/appcast.xml"

    /// UserDefaults key for automatic update check preference
    static let autoCheckUpdatesKey = "tokemon.autoCheckUpdates"

    // MARK: - Webhook Alerts

    /// UserDefaults key for webhook configuration (JSON-encoded WebhookConfig)
    static let webhookConfigKey = "tokemon.webhookConfig"

    // MARK: - Budget & Forecasting

    /// UserDefaults key for budget configuration (JSON-encoded BudgetConfig)
    static let budgetConfigKey = "tokemon.budgetConfig"
}
