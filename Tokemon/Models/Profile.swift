import Foundation

/// A named profile that stores Claude Code credentials internally.
///
/// Profiles implement the copy/switch architecture: credentials are stored
/// INSIDE the app (not in the system keychain), and on switch, the selected
/// profile's credentials are written TO the system keychain for Claude Code to use.
struct Profile: Identifiable, Codable, Sendable {
    /// Unique identifier for the profile
    let id: UUID

    /// User-provided display name (e.g., "Work", "Personal")
    var name: String

    /// OAuth session key (from manual entry)
    var claudeSessionKey: String?

    /// Organization ID if applicable
    var organizationId: String?

    /// Full JSON blob copied from the system keychain (Claude Code credentials)
    var cliCredentialsJSON: String?

    /// True for the first/primary profile
    var isDefault: Bool

    /// When the profile was created
    var createdAt: Date

    /// Cached usage for quick display in profile switcher
    var lastUsage: UsageSnapshot?

    /// When credentials were last synced from the system keychain
    var lastSynced: Date?

    /// Whether this profile has any credentials (either synced or manual)
    var hasCredentials: Bool {
        cliCredentialsJSON != nil || claudeSessionKey != nil
    }

    /// Create a new empty profile with the given name
    static func create(name: String, isDefault: Bool = false) -> Profile {
        Profile(
            id: UUID(),
            name: name,
            isDefault: isDefault,
            createdAt: Date()
        )
    }
}
