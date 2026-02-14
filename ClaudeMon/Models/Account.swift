import Foundation

/// Represents a Claude account with metadata and per-account settings.
/// Stored as part of the accounts array in ClaudeMon's own keychain service.
struct Account: Identifiable, Codable, Sendable {

    /// Unique identifier for this account
    let id: UUID

    /// User-facing display name (defaults to username)
    var displayName: String

    /// Claude Code username (matches Keychain account key)
    let username: String

    /// When this account was added to ClaudeMon
    let createdAt: Date

    /// Per-account preferences
    var settings: AccountSettings

    /// Whether this account has valid OAuth credentials
    /// Set to false when OAuth refresh fails persistently
    var hasValidCredentials: Bool

    // MARK: - Initialization

    /// Create a new account entry.
    /// - Parameters:
    ///   - id: Unique identifier (auto-generated if omitted)
    ///   - displayName: User-facing name (defaults to username if nil)
    ///   - username: Claude Code username matching Keychain account key
    init(id: UUID = UUID(), displayName: String? = nil, username: String) {
        self.id = id
        self.displayName = displayName ?? username
        self.username = username
        self.createdAt = Date()
        self.settings = AccountSettings()
        self.hasValidCredentials = true
    }
}
