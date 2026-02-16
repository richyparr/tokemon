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

    // MARK: - LemonSqueezy Licensing

    /// Developer mode: bypass licensing and treat as Pro user
    /// Set to false before shipping!
    static let developerModeProEnabled: Bool = false

    /// LemonSqueezy store ID (verify against API responses)
    static let lemonSqueezyStoreId: Int = 292990

    /// LemonSqueezy product ID for Tokemon Pro
    static let lemonSqueezyProductId: Int = 830222

    /// LemonSqueezy checkout URL for purchasing
    static let lemonSqueezyCheckoutURL = "https://tokemon.lemonsqueezy.com/buy/1308154"

    /// LemonSqueezy customer portal URL for subscription management
    static let lemonSqueezyPortalURL = "https://tokemon.lemonsqueezy.com/billing"

    /// Trial duration in days
    static let trialDurationDays: Int = 14

    /// Grace period for subscription lapses in days
    static let gracePeriodDays: Int = 7

    /// Offline validation window in days
    static let offlineValidationDays: Int = 7

    /// Keychain service name for license storage (separate from OAuth credentials)
    static let licenseKeychainService = "ai.tokemon.license"

    // MARK: - Multi-Account

    /// Keychain service name for Tokemon account metadata (separate from Claude Code credentials)
    static let accountsKeychainService = "ai.tokemon.accounts"
}
