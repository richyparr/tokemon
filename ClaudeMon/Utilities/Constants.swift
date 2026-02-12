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
}
