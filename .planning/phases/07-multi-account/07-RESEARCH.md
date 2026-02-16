# Phase 7: Multi-Account - Research

**Researched:** 2026-02-14
**Domain:** Multi-account OAuth credential storage, account switching UX, per-account state management
**Confidence:** HIGH

## Summary

Multi-account support requires separating credentials storage from account-agnostic services, introducing an AccountManager to coordinate multiple OAuth credentials stored with unique Keychain account identifiers. The existing `KeychainAccess` package already supports this via its `allKeys()` and per-key storage APIs -- each account simply gets its own key (e.g., `"account-{uuid}"`).

The core architectural change is introducing a **currently active account** concept throughout the app. UsageMonitor, AlertManager, and HistoryStore will operate on whichever account is active, while AccountManager handles credential storage, account switching, and account enumeration. This follows patterns used by apps like Slack and VS Code for multi-workspace/account management.

For the combined usage view, a separate aggregation layer fetches data for all accounts in parallel and computes sums/averages as needed. Per-account alert thresholds require extending the stored account metadata to include user preferences.

**Primary recommendation:** Create an `AccountManager` service that wraps TokenManager for multi-credential Keychain access, extend `Account` model with per-account settings, modify UsageMonitor to accept an account context, and add account switcher UI to the popover header.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| [KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess) | 4.2.2 | Multi-account credential storage | Already in project; supports `allKeys()` for enumeration and per-key storage |
| Swift Observation | Built-in | Reactive state management | Already used throughout app via `@Observable` |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Foundation/UUID | Built-in | Account identifiers | Generate unique IDs for each account |
| Foundation/JSONEncoder | Built-in | Account metadata serialization | Store account settings alongside credentials |
| UserDefaults | Built-in | Active account preference | Remember which account was last used |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| UUID account IDs | Username-based IDs | UUID prevents collision if same username added twice; username is more readable |
| UserDefaults for active account | Keychain | Keychain is overkill for non-secret preference |
| Parallel fetch for combined view | Sequential fetch | Parallel is faster but more complex error handling |

**Installation:**
No new dependencies required. Uses existing `KeychainAccess` package.

## Architecture Patterns

### Recommended Project Structure
```
Tokemon/
├── Services/
│   ├── AccountManager.swift        # NEW: Multi-account coordination
│   ├── TokenManager.swift          # MODIFY: Accept accountId parameter
│   ├── UsageMonitor.swift          # MODIFY: Operate on active account
│   ├── AlertManager.swift          # MODIFY: Per-account thresholds
│   └── HistoryStore.swift          # MODIFY: Per-account history files
├── Models/
│   ├── Account.swift               # NEW: Account model with settings
│   ├── AccountSettings.swift       # NEW: Per-account preferences
│   └── ... (existing models)
├── Views/
│   ├── MenuBar/
│   │   ├── PopoverContentView.swift    # MODIFY: Add account switcher
│   │   └── AccountSwitcherView.swift   # NEW: Account picker header
│   ├── Settings/
│   │   └── AccountsSettings.swift      # NEW: Account management tab
│   └── ... (existing views)
└── Utilities/
    └── Constants.swift             # ADD: Multi-account keychain service
```

### Pattern 1: Account Model with Per-Account Settings
**What:** Single model representing an account with its credentials and preferences
**When to use:** Any operation involving account data
**Example:**
```swift
// Source: Standard multi-account app pattern
import Foundation

/// Represents a Claude account with stored credentials and user preferences
struct Account: Identifiable, Codable, Sendable {
    let id: UUID
    let displayName: String           // User-editable label (e.g., "Work", "Personal")
    let username: String              // From Claude OAuth (kSecAttrAccount original value)
    let createdAt: Date
    var settings: AccountSettings

    /// Whether this account has valid credentials (not expired)
    var hasValidCredentials: Bool = true

    init(id: UUID = UUID(), displayName: String? = nil, username: String) {
        self.id = id
        self.displayName = displayName ?? username
        self.username = username
        self.createdAt = Date()
        self.settings = AccountSettings()
    }
}

/// Per-account user preferences
struct AccountSettings: Codable, Sendable {
    /// Alert threshold percentage (50-100)
    var alertThreshold: Int = 80

    /// Whether notifications are enabled for this account
    var notificationsEnabled: Bool = true

    /// Optional monthly usage target (for budgeting)
    var monthlyBudgetCents: Int?
}
```

### Pattern 2: AccountManager as Central Coordinator
**What:** Service that manages account list, active account, and credential access
**When to use:** Any account-related operation
**Example:**
```swift
// Source: Following existing LicenseManager/UsageMonitor patterns
import Foundation
import KeychainAccess

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

    /// Called when active account changes (for UsageMonitor refresh)
    @ObservationIgnored
    var onActiveAccountChanged: ((Account?) -> Void)?

    // MARK: - Private

    @ObservationIgnored
    private let credentialsKeychain: Keychain

    @ObservationIgnored
    private let accountsKeychain: Keychain

    private let activeAccountKey = "activeAccountId"

    init() {
        // Separate keychain service for Tokemon's account metadata
        accountsKeychain = Keychain(service: Constants.accountsKeychainService)
            .accessibility(.afterFirstUnlockThisDeviceOnly)

        // Use the same keychain service as Claude Code for credentials
        credentialsKeychain = Keychain(service: Constants.keychainService)

        Task { await loadAccounts() }
    }

    // MARK: - Public API

    /// Add a new account from OAuth credentials
    func addAccount(username: String) async throws -> Account {
        // Check if account already exists
        if let existing = accounts.first(where: { $0.username == username }) {
            return existing
        }

        let account = Account(username: username)
        accounts.append(account)
        try await saveAccounts()

        // If first account, make it active
        if accounts.count == 1 {
            try await setActiveAccount(account)
        }

        return account
    }

    /// Set the active account
    func setActiveAccount(_ account: Account) async throws {
        activeAccount = account
        UserDefaults.standard.set(account.id.uuidString, forKey: activeAccountKey)
        onActiveAccountChanged?(account)
    }

    /// Remove an account
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

    /// Update account settings
    func updateAccountSettings(_ account: Account, settings: AccountSettings) async throws {
        guard let index = accounts.firstIndex(where: { $0.id == account.id }) else { return }
        accounts[index].settings = settings

        if activeAccount?.id == account.id {
            activeAccount = accounts[index]
        }

        try await saveAccounts()
    }

    /// Get credentials for a specific account
    func getCredentials(for account: Account) throws -> TokenManager.ClaudeCredentials {
        // Credentials are stored in Claude Code's keychain under username
        return try TokenManager.getCredentials(username: account.username)
    }
}
```

### Pattern 3: Modified TokenManager for Multi-Account
**What:** Extend TokenManager to support account-specific credential access
**When to use:** When fetching/refreshing tokens for a specific account
**Example:**
```swift
// Source: Extending existing TokenManager
extension TokenManager {
    /// Read credentials for a specific account (username)
    static func getCredentials(username: String) throws -> ClaudeCredentials {
        let keychain = Keychain(service: Constants.keychainService)

        guard let json = try keychain.getString(username) else {
            throw TokenError.noCredentials
        }

        guard let data = json.data(using: .utf8) else {
            throw TokenError.noCredentials
        }

        do {
            return try JSONDecoder().decode(ClaudeCredentials.self, from: data)
        } catch {
            throw TokenError.decodingError(error)
        }
    }

    /// Get valid access token for a specific account
    static func getAccessToken(for username: String) throws -> String {
        let credentials = try getCredentials(username: username)
        let oauth = credentials.claudeAiOauth

        let expiresAtDate = Date(timeIntervalSince1970: Double(oauth.expiresAt) / 1000.0)
        let bufferDate = Date().addingTimeInterval(10 * 60)

        if expiresAtDate < bufferDate {
            throw TokenError.expired
        }

        if !oauth.scopes.contains("user:profile") {
            throw TokenError.insufficientScope
        }

        return oauth.accessToken
    }
}
```

### Pattern 4: Account Switcher UI in Popover
**What:** Compact account picker at the top of the popover
**When to use:** Switching between accounts without opening settings
**Example:**
```swift
// Source: Following Slack/VS Code pattern
struct AccountSwitcherView: View {
    @Environment(AccountManager.self) private var accountManager
    @Environment(FeatureAccessManager.self) private var featureAccess
    @State private var showingAccountPicker = false

    var body: some View {
        if featureAccess.canAccess(.multiAccount) && accountManager.accounts.count > 1 {
            Menu {
                ForEach(accountManager.accounts) { account in
                    Button {
                        Task {
                            try? await accountManager.setActiveAccount(account)
                        }
                    } label: {
                        HStack {
                            Text(account.displayName)
                            if account.id == accountManager.activeAccount?.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }

                Divider()

                Button("Manage Accounts...") {
                    SettingsWindowController.shared.showSettings(tab: .accounts)
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "person.crop.circle")
                    Text(accountManager.activeAccount?.displayName ?? "No Account")
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
        }
    }
}
```

### Pattern 5: Combined Usage View
**What:** Aggregate usage across all accounts
**When to use:** Showing overall usage summary in settings or dashboard
**Example:**
```swift
// Source: Standard aggregation pattern
struct CombinedUsageView: View {
    @Environment(AccountManager.self) private var accountManager
    @State private var accountSnapshots: [UUID: UsageSnapshot] = [:]
    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Combined Usage")
                .font(.headline)

            if isLoading {
                ProgressView()
            } else {
                ForEach(accountManager.accounts) { account in
                    if let snapshot = accountSnapshots[account.id] {
                        HStack {
                            Text(account.displayName)
                            Spacer()
                            Text("\(Int(snapshot.primaryPercentage))%")
                                .foregroundStyle(Color(nsColor: GradientColors.color(for: snapshot.primaryPercentage)))
                        }
                    }
                }

                Divider()

                HStack {
                    Text("Average")
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(Int(averageUsage))%")
                        .fontWeight(.medium)
                }
            }
        }
        .task {
            await fetchAllUsage()
        }
    }

    private var averageUsage: Double {
        let usages = accountSnapshots.values.map { $0.primaryPercentage }
        guard !usages.isEmpty else { return 0 }
        return usages.reduce(0, +) / Double(usages.count)
    }

    private func fetchAllUsage() async {
        isLoading = true
        defer { isLoading = false }

        await withTaskGroup(of: (UUID, UsageSnapshot?).self) { group in
            for account in accountManager.accounts {
                group.addTask {
                    do {
                        let accessToken = try TokenManager.getAccessToken(for: account.username)
                        let response = try await OAuthClient.fetchUsage(accessToken: accessToken)
                        return (account.id, response.toSnapshot())
                    } catch {
                        return (account.id, nil)
                    }
                }
            }

            for await (accountId, snapshot) in group {
                if let snapshot = snapshot {
                    accountSnapshots[accountId] = snapshot
                }
            }
        }
    }
}
```

### Anti-Patterns to Avoid
- **Global singleton UsageMonitor with embedded account state:** Keep account context separate from polling logic
- **Copying credentials between keychain entries:** Use original Claude Code entries directly
- **Blocking UI during account switch:** Fetch new data async, show loading state
- **Hardcoding threshold values:** Always read from account-specific settings
- **Modifying Claude Code's keychain entries:** Read-only access to Claude Code's credentials

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Credential enumeration | Custom keychain iteration | `keychain.allKeys()` | KeychainAccess handles the complexity |
| Account metadata storage | File-based JSON | Keychain with separate service | Secure, atomic writes, migration-safe |
| Active account persistence | File/plist | UserDefaults | Simple preference, not security-sensitive |
| Parallel usage fetching | Manual threading | `withTaskGroup` | Structured concurrency, automatic cancellation |
| Account picker UI | Custom popover | SwiftUI `Menu` | Native feel, automatic dismissal |

**Key insight:** The app's job is coordination, not re-implementing OAuth. Claude Code handles the OAuth flow -- Tokemon just reads the stored credentials and fetches usage data for each account.

## Common Pitfalls

### Pitfall 1: Modifying Claude Code's Keychain Entries
**What goes wrong:** Writing account metadata to Claude Code's keychain service corrupts credentials
**Why it happens:** Tempting to co-locate all account data
**How to avoid:** Use a separate keychain service (`Constants.accountsKeychainService`) for Tokemon's account metadata; only *read* from Claude Code's service
**Warning signs:** Claude Code reports credential errors after Tokemon runs

### Pitfall 2: Not Handling Account Removal During Active Session
**What goes wrong:** App crashes or shows stale data when active account is removed
**Why it happens:** References to removed account persist in UsageMonitor/AlertManager
**How to avoid:** `onActiveAccountChanged` callback triggers full refresh; guard against nil active account
**Warning signs:** Crash after removing the last account, or seeing data from wrong account

### Pitfall 3: Race Condition on Account Switch
**What goes wrong:** Usage data from old account displayed after switching
**Why it happens:** Previous fetch completes after account switch
**How to avoid:** Cancel in-flight requests on account switch; use Task cancellation
**Warning signs:** Briefly showing wrong account's data, percentage jumps unexpectedly

```swift
// Good: Cancel and restart on account switch
private var currentFetchTask: Task<Void, Never>?

func switchAccount(_ account: Account) {
    currentFetchTask?.cancel()
    currentFetchTask = Task {
        await refresh(for: account)
    }
}
```

### Pitfall 4: Forgetting to Migrate Single-Account Data
**What goes wrong:** Existing users lose their settings/history after upgrade
**Why it happens:** New multi-account schema doesn't read old single-account data
**How to avoid:** Migration code that creates first Account from existing credentials
**Warning signs:** Users complain settings/history lost after update

### Pitfall 5: Per-Account History Bloat
**What goes wrong:** Disk usage grows linearly with account count
**Why it happens:** Each account gets its own 30-day history file
**How to avoid:** Consider shared history with account ID field, or reduce retention per account
**Warning signs:** Large Application Support folder, slow history loads

### Pitfall 6: OAuth Refresh Token Conflicts
**What goes wrong:** Refreshing one account's token invalidates another's
**Why it happens:** Both accounts share refresh logic without isolation
**How to avoid:** Each account's token refresh is independent; don't share refresh state
**Warning signs:** "Token expired" errors on account that wasn't actively used

## Code Examples

### Migration from Single to Multi-Account

```swift
// Source: Standard migration pattern
func migrateFromSingleAccount() async throws {
    // Check if migration already done
    guard UserDefaults.standard.bool(forKey: "didMigrateToMultiAccount") == false else {
        return
    }

    // Check for existing Claude Code credentials
    let keychain = Keychain(service: Constants.keychainService)
    let username = NSUserName()

    guard let _ = try? keychain.getString(username) else {
        // No existing credentials, nothing to migrate
        UserDefaults.standard.set(true, forKey: "didMigrateToMultiAccount")
        return
    }

    // Create account for existing credentials
    let account = Account(username: username)

    // Migrate existing settings as account-specific settings
    let existingThreshold = UserDefaults.standard.integer(forKey: "alertThreshold")
    let existingNotifications = UserDefaults.standard.bool(forKey: "notificationsEnabled")

    var settings = AccountSettings()
    settings.alertThreshold = existingThreshold > 0 ? existingThreshold : 80
    settings.notificationsEnabled = existingNotifications

    var migratedAccount = account
    migratedAccount.settings = settings

    // Save as first account
    try await accountManager.saveAccount(migratedAccount)
    try await accountManager.setActiveAccount(migratedAccount)

    UserDefaults.standard.set(true, forKey: "didMigrateToMultiAccount")
}
```

### Per-Account HistoryStore

```swift
// Source: Extending existing HistoryStore pattern
actor HistoryStore {
    private var fileURLs: [UUID: URL] = [:]  // Account ID -> history file
    private var caches: [UUID: [UsageDataPoint]] = [:]

    private func fileURL(for accountId: UUID) -> URL {
        if let cached = fileURLs[accountId] { return cached }

        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("Tokemon/history", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)

        let url = appDir.appendingPathComponent("\(accountId.uuidString).json")
        fileURLs[accountId] = url
        return url
    }

    func append(_ point: UsageDataPoint, for accountId: UUID) throws {
        var cache = caches[accountId] ?? []
        cache.append(point)
        caches[accountId] = cache
        try save(for: accountId)
    }

    func getHistory(for accountId: UUID) -> [UsageDataPoint] {
        return caches[accountId] ?? []
    }
}
```

### Accounts Settings Tab

```swift
// Source: Following existing SettingsView tab pattern
struct AccountsSettings: View {
    @Environment(AccountManager.self) private var accountManager
    @Environment(FeatureAccessManager.self) private var featureAccess
    @State private var selectedAccount: Account?
    @State private var showingRemoveConfirmation = false

    var body: some View {
        Form {
            Section("Accounts") {
                ForEach(accountManager.accounts) { account in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(account.displayName)
                                .fontWeight(.medium)
                            Text(account.username)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if account.id == accountManager.activeAccount?.id {
                            Text("Active")
                                .font(.caption)
                                .foregroundStyle(.green)
                        } else {
                            Button("Switch") {
                                Task { try? await accountManager.setActiveAccount(account) }
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedAccount = account
                    }
                }
            }

            if let account = selectedAccount {
                Section("Settings for \(account.displayName)") {
                    AccountSettingsEditor(account: account)
                }

                Section {
                    Button("Remove Account", role: .destructive) {
                        showingRemoveConfirmation = true
                    }
                }
            }

            Section {
                HStack {
                    Text("Add accounts by signing in via Claude Code CLI")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .confirmationDialog("Remove Account?", isPresented: $showingRemoveConfirmation) {
            Button("Remove", role: .destructive) {
                if let account = selectedAccount {
                    Task { try? await accountManager.removeAccount(account) }
                    selectedAccount = nil
                }
            }
        }
    }
}
```

### OAuthClient Extension for Multi-Account

```swift
// Source: Extending existing OAuthClient
extension OAuthClient {
    /// Fetch usage for a specific account
    static func fetchUsage(for account: Account) async throws -> OAuthUsageResponse {
        let accessToken = try TokenManager.getAccessToken(for: account.username)
        return try await fetchUsage(accessToken: accessToken)
    }

    /// Fetch usage with token refresh for a specific account
    static func fetchUsageWithTokenRefresh(for account: Account) async throws -> OAuthUsageResponse {
        do {
            let accessToken = try TokenManager.getAccessToken(for: account.username)
            return try await fetchUsage(accessToken: accessToken)
        } catch TokenManager.TokenError.expired {
            let refreshedToken = try await performTokenRefresh(for: account.username)
            return try await fetchUsage(accessToken: refreshedToken)
        }
    }

    private static func performTokenRefresh(for username: String) async throws -> String {
        let refreshToken = try TokenManager.getRefreshToken(for: username)
        let tokenResponse = try await TokenManager.refreshAccessToken(refreshToken: refreshToken)
        try TokenManager.updateKeychainCredentials(response: tokenResponse, for: username)
        return tokenResponse.accessToken
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Separate apps per account | Single app with account switcher | Standard practice | Better UX, less resource usage |
| Blocking account switch | Async switch with cached state | Swift concurrency era | No UI freezes |
| Manual credential management | Leverage existing OAuth flow | Always | Less code, fewer bugs |
| Global settings | Per-account settings | Multi-account pattern | User flexibility |

**Deprecated/outdated:**
- **Copying credentials to custom keychain:** Just reference Claude Code's entries
- **Single-file history:** Per-account files scale better
- **Modal account picker:** Inline menu is faster for switching

## Open Questions

1. **Account display name source**
   - What we know: Can use the username from Keychain
   - What's unclear: Does Claude OAuth return a display name or email?
   - Recommendation: Default to username, allow user to rename in settings

2. **Adding new accounts flow**
   - What we know: Claude Code's `claude login` creates the keychain entry
   - What's unclear: Should Tokemon prompt user to run `claude login` or detect new credentials automatically?
   - Recommendation: Manual "Add Account" button that shows instructions, plus periodic check for new credentials

3. **Combined view metrics**
   - What we know: Can show per-account percentages
   - What's unclear: Should combined view show sum, average, or max?
   - Recommendation: Show highest usage (max) as the headline, list all accounts below

4. **History retention for removed accounts**
   - What we know: Per-account history files
   - What's unclear: Keep history when account removed?
   - Recommendation: Offer to delete or keep during removal confirmation

## Sources

### Primary (HIGH confidence)
- [KeychainAccess GitHub](https://github.com/kishikawakatsumi/KeychainAccess) - `allKeys()` and per-key storage patterns
- Existing Tokemon codebase - TokenManager, LicenseStorage, UsageMonitor patterns
- [Apple Maintaining State in Your Apps](https://developer.apple.com/documentation/swift/maintaining-state-in-your-apps) - State management patterns

### Secondary (MEDIUM confidence)
- [SwiftUI Picker on macOS](https://serialcoder.dev/text-tutorials/macos-tutorials/flavors-of-swiftui-picker-on-macos/) - Menu-style picker patterns
- [Building macOS Menu Bar with SwiftUI](https://developer.apple.com/documentation/SwiftUI/Building-and-customizing-the-menu-bar-with-SwiftUI) - Menu bar patterns
- [Slack Workspace Switching](https://slack.com/help/articles/1500002200741-Switch-between-workspaces) - Multi-workspace UX patterns
- [Swift by Sundell State Management](https://www.swiftbysundell.com/articles/swiftui-state-management-guide/) - Observable patterns

### Tertiary (LOW confidence)
- WebSearch results for multiple account Keychain patterns - General guidance

## Integration Points with Existing Codebase

### TokenManager.swift
- Add overloaded methods that accept `username: String` parameter
- Keep existing parameterless methods for backward compatibility (use active account)

### UsageMonitor.swift
- Accept `Account` context in `refresh()` method
- Store reference to `AccountManager` for active account lookup
- Cancel in-flight requests on account switch

### AlertManager.swift
- Read threshold from `account.settings.alertThreshold` instead of global UserDefaults
- Per-account notification state tracking

### HistoryStore.swift
- Change from single file to per-account files
- Add `accountId` parameter to all methods

### TokemonApp.swift
- Add `AccountManager` as `@State` property
- Wire `onActiveAccountChanged` callback to trigger UsageMonitor refresh
- Pass to views via `.environment()`

### PopoverContentView.swift
- Add `AccountSwitcherView` in header (when Pro and multiple accounts)
- Inject `AccountManager` via environment

### SettingsView.swift
- Add "Accounts" tab between "Alerts" and "License"
- Gate with `featureAccess.canAccess(.multiAccount)`

### Constants.swift
- Add `accountsKeychainService = "com.tokemon.accounts"`

## Metadata

**Confidence breakdown:**
- Multi-account Keychain storage: HIGH - KeychainAccess docs are clear
- Account switcher UX: HIGH - Standard macOS pattern, SwiftUI Menu works well
- Per-account AlertManager: MEDIUM - Extension of existing patterns, may need iteration
- Combined usage aggregation: MEDIUM - Parallel fetch is straightforward, aggregation metrics TBD

**Research date:** 2026-02-14
**Valid until:** 2026-03-14 (patterns are stable, no external API dependencies for this phase)
