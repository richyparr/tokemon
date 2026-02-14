import Foundation
import KeychainAccess

/// Central coordinator for multi-account management.
/// Handles account list, active account selection, and credential access.
@Observable
@MainActor
final class AccountManager {

    // MARK: - Published State

    /// All registered accounts
    var accounts: [Account] = []

    /// Currently active account (nil if none)
    var activeAccount: Account?

    /// Whether account operations are in progress
    var isLoading: Bool = false

    /// Current error state
    var error: AccountError?

    // MARK: - Callbacks

    /// Called when active account changes (triggers UsageMonitor refresh)
    @ObservationIgnored
    var onActiveAccountChanged: ((Account?) -> Void)?

    // MARK: - Private

    @ObservationIgnored
    private let accountsKeychain: Keychain

    private let accountsKey = "accounts"
    private let activeAccountKey = "activeAccountId"
    private let migrationKey = "didMigrateToMultiAccount"

    // MARK: - Error Types

    enum AccountError: Error, LocalizedError {
        case accountNotFound
        case duplicateAccount
        case keychainError(String)
        case noCredentials

        var errorDescription: String? {
            switch self {
            case .accountNotFound: return "Account not found"
            case .duplicateAccount: return "Account already exists"
            case .keychainError(let msg): return "Keychain error: \(msg)"
            case .noCredentials: return "No credentials found for account"
            }
        }
    }

    // MARK: - Initialization

    init() {
        accountsKeychain = Keychain(service: Constants.accountsKeychainService)
            .accessibility(.afterFirstUnlockThisDeviceOnly)

        Task { @MainActor in
            await loadAccounts()
            await migrateFromSingleAccountIfNeeded()
        }
    }

    // MARK: - Public API

    /// Add a new account from OAuth credentials.
    /// Returns the existing account if one with the same username already exists.
    /// - Parameters:
    ///   - username: Claude Code username matching Keychain account key
    ///   - displayName: Optional display name (defaults to username)
    /// - Returns: The new or existing Account
    func addAccount(username: String, displayName: String? = nil) async throws -> Account {
        // Check if account already exists
        if let existing = accounts.first(where: { $0.username == username }) {
            return existing
        }

        // Verify credentials exist in Claude Code's keychain
        do {
            _ = try TokenManager.getCredentials(username: username)
        } catch {
            throw AccountError.noCredentials
        }

        let account = Account(displayName: displayName, username: username)
        accounts.append(account)
        try await saveAccounts()

        // If first account, make it active
        if accounts.count == 1 {
            try await setActiveAccount(account)
        }

        return account
    }

    /// Set the active account and notify listeners.
    /// - Parameter account: The account to make active
    func setActiveAccount(_ account: Account) async throws {
        guard accounts.contains(where: { $0.id == account.id }) else {
            throw AccountError.accountNotFound
        }

        activeAccount = account
        UserDefaults.standard.set(account.id.uuidString, forKey: activeAccountKey)
        onActiveAccountChanged?(account)
    }

    /// Remove an account and update active account if necessary.
    /// - Parameter account: The account to remove
    func removeAccount(_ account: Account) async throws {
        accounts.removeAll { $0.id == account.id }

        // Clear active account if it was removed
        if activeAccount?.id == account.id {
            activeAccount = accounts.first
            if let newActive = activeAccount {
                UserDefaults.standard.set(newActive.id.uuidString, forKey: activeAccountKey)
            } else {
                UserDefaults.standard.removeObject(forKey: activeAccountKey)
            }
            onActiveAccountChanged?(activeAccount)
        }

        try await saveAccounts()
    }

    /// Update per-account settings.
    /// - Parameters:
    ///   - account: The account to update
    ///   - settings: New settings to apply
    func updateAccountSettings(_ account: Account, settings: AccountSettings) async throws {
        guard let index = accounts.firstIndex(where: { $0.id == account.id }) else {
            throw AccountError.accountNotFound
        }

        accounts[index].settings = settings

        if activeAccount?.id == account.id {
            activeAccount = accounts[index]
        }

        try await saveAccounts()
    }

    /// Update an account's display name.
    /// - Parameters:
    ///   - account: The account to update
    ///   - displayName: New display name
    func updateDisplayName(_ account: Account, displayName: String) async throws {
        guard let index = accounts.firstIndex(where: { $0.id == account.id }) else {
            throw AccountError.accountNotFound
        }

        accounts[index].displayName = displayName

        if activeAccount?.id == account.id {
            activeAccount = accounts[index]
        }

        try await saveAccounts()
    }

    /// Scan Claude Code's keychain for accounts not yet registered in ClaudeMon.
    /// Users run `claude login` externally, then ClaudeMon detects and imports the new credentials.
    /// - Returns: Array of newly added accounts.
    @discardableResult
    func checkForNewAccounts() async throws -> [Account] {
        let claudeKeychain = Keychain(service: Constants.keychainService)

        // Get all keys (usernames) from Claude Code's keychain
        let allKeys = claudeKeychain.allKeys()

        // Find keys not already in our accounts list
        let existingUsernames = Set(accounts.map { $0.username })
        let newUsernames = allKeys.filter { !existingUsernames.contains($0) }

        var newAccounts: [Account] = []

        for username in newUsernames {
            // Verify credentials are valid (readable) before adding
            do {
                _ = try TokenManager.getCredentials(username: username)
                let account = try await addAccount(username: username)
                newAccounts.append(account)
                print("[AccountManager] Discovered new account: \(username)")
            } catch {
                // Skip invalid/unreadable credentials
                print("[AccountManager] Skipping \(username): \(error.localizedDescription)")
            }
        }

        return newAccounts
    }

    /// Get access token for the currently active account.
    /// - Returns: OAuth access token string
    /// - Throws: `AccountError.accountNotFound` if no active account
    func getActiveAccountAccessToken() throws -> String {
        guard let account = activeAccount else {
            throw AccountError.accountNotFound
        }
        return try TokenManager.getAccessToken(for: account.username)
    }

    // MARK: - Private Methods

    private func loadAccounts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            if let data = try accountsKeychain.getData(accountsKey) {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                accounts = try decoder.decode([Account].self, from: data)
            }

            // Restore active account
            if let activeId = UserDefaults.standard.string(forKey: activeAccountKey),
               let uuid = UUID(uuidString: activeId),
               let account = accounts.first(where: { $0.id == uuid }) {
                activeAccount = account
            } else if !accounts.isEmpty {
                // Default to first account
                activeAccount = accounts.first
            }
        } catch {
            self.error = .keychainError(error.localizedDescription)
        }
    }

    private func saveAccounts() async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(accounts)
        try accountsKeychain.set(data, key: accountsKey)
    }

    /// Migrate existing single-account user to multi-account structure.
    /// Runs once on first launch after update. Creates an Account entry
    /// from existing Claude Code credentials and migrates alert settings.
    private func migrateFromSingleAccountIfNeeded() async {
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

        // Check for existing Claude Code credentials (current user)
        let username = NSUserName()

        do {
            _ = try TokenManager.getCredentials(username: username)

            // Credentials exist - create account entry
            var account = Account(username: username)

            // Migrate existing alert settings
            let existingThreshold = UserDefaults.standard.integer(forKey: "alertThreshold")
            let existingNotifications = UserDefaults.standard.bool(forKey: "notificationsEnabled")

            account.settings.alertThreshold = existingThreshold > 0 ? existingThreshold : 80
            account.settings.notificationsEnabled = existingNotifications

            accounts.append(account)
            activeAccount = account

            try await saveAccounts()
            UserDefaults.standard.set(account.id.uuidString, forKey: activeAccountKey)

            print("[AccountManager] Migrated single account to multi-account: \(username)")
        } catch {
            // No existing credentials - nothing to migrate
            print("[AccountManager] No existing credentials to migrate")
        }

        UserDefaults.standard.set(true, forKey: migrationKey)
    }
}
