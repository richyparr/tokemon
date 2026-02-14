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
    static let developerModeProEnabled: Bool = true

    /// LemonSqueezy store ID (verify against API responses)
    static let lemonSqueezyStoreId: Int = 0  // TODO: Replace with actual store ID

    /// LemonSqueezy product ID for ClaudeMon Pro
    static let lemonSqueezyProductId: Int = 0  // TODO: Replace with actual product ID

    /// LemonSqueezy checkout URL for purchasing
    static let lemonSqueezyCheckoutURL = "https://YOURSTORE.lemonsqueezy.com/buy/YOUR_PRODUCT_ID"

    /// LemonSqueezy customer portal URL for subscription management
    static let lemonSqueezyPortalURL = "https://YOURSTORE.lemonsqueezy.com/billing"

    /// Trial duration in days
    static let trialDurationDays: Int = 14

    /// Grace period for subscription lapses in days
    static let gracePeriodDays: Int = 7

    /// Offline validation window in days
    static let offlineValidationDays: Int = 7

    /// Keychain service name for license storage (separate from OAuth credentials)
    static let licenseKeychainService = "com.claudemon.license"

    // MARK: - Multi-Account

    /// Keychain service name for ClaudeMon account metadata (separate from Claude Code credentials)
    static let accountsKeychainService = "com.claudemon.accounts"
}
