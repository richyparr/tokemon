# Phase 22: Security Hardening - Research

**Researched:** 2026-02-20
**Domain:** macOS Keychain, App Sandboxing, Swift Logging, URL Validation
**Confidence:** HIGH (all five issues are directly verifiable from source code; patterns are well-established Swift/macOS conventions)

## Summary

Five distinct security issues were identified in the Tokemon codebase through source inspection. They are ordered by severity: (1) profile credentials in UserDefaults (plaintext plist on disk), (2) Keychain write-back conflict with Claude Code, (3) API error bodies logged via `print()` to Console.app, (4) webhook URLs accepted without HTTPS enforcement, and (5) app sandboxing feasibility. Each issue has a clear, well-established fix.

The most impactful change is migrating `Profile.claudeSessionKey` and `Profile.cliCredentialsJSON` out of UserDefaults into a dedicated Keychain service (`ai.tokemon.profiles`). The existing `KeychainAccess` 4.2.2 library (already in Package.resolved) handles this cleanly using `profileId.uuidString` as the account key. The logging issue is a two-line fix per call site using `OSLog.Logger`. The webhook HTTPS check is a one-line scheme assertion. App sandboxing is technically infeasible given Tokemon's requirements and should be documented as a known limitation rather than implemented.

The Keychain write-back conflict in `TokenManager.updateKeychainCredentials` is a real and known problem (confirmed by Claude Code issue #19456): Claude Code itself struggles with Keychain update/delete permissions after auto-updates. Tokemon writing to the same entry increases collision risk. The fix is to disable the write-back entirely and surface a user-facing message prompting re-login via Claude Code instead.

**Primary recommendation:** Migrate profile credentials to Keychain using `ai.tokemon.profiles` service with UUID account keys, disable TokenManager write-back, replace all `print()` with `OSLog.Logger`, and add HTTPS scheme validation in `WebhookManager.postJSON`. Skip sandboxing with a documented rationale.

## User Constraints

No CONTEXT.md exists for this phase. All decisions are at researcher/planner discretion.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| KeychainAccess | 4.2.2 (already installed) | Keychain read/write for profile credentials | Already used for AdminAPIClient; consistent pattern; abstracts Security.framework boilerplate |
| OSLog (system) | Built into macOS 14+ | Structured logging with privacy annotations | Apple-recommended replacement for `print()`; default privacy-redacts non-literal strings; visible in Console.app with filtering |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Foundation.URL | System | URL scheme validation | Use `.scheme == "https"` check before posting webhooks |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| KeychainAccess | Apple Security.framework directly | Security.framework is ~50 lines of boilerplate vs 3 lines with KeychainAccess; no reason to switch when library is already present |
| OSLog.Logger | swift-log (apple/swift-log) | swift-log is a backend-agnostic facade; OSLog is the Apple-native, zero-overhead option that hooks directly into Console.app; prefer OSLog for a macOS app |
| HTTPS enforcement in code | NSAppTransportSecurity Info.plist | ATS does enforce HTTPS by default on macOS apps, but Info.plist has no ATS configuration in this project, and ATS does not apply to IP addresses or custom URL schemes; explicit scheme check is defense-in-depth and provides user-facing error messages |

**No additional package installation required.** All required libraries are either already in the project or system-provided.

## Architecture Patterns

### Recommended Project Structure

No new files or directories are needed. Changes are targeted edits to existing service files:

```
Tokemon/
├── Models/
│   └── Profile.swift                  # claudeSessionKey/cliCredentialsJSON remain as model fields
│                                       # (stored in Keychain; fields are transient at encode time — see pattern below)
├── Services/
│   ├── ProfileManager.swift           # saveProfiles() strips credentials before UserDefaults write
│   │                                   # loadProfiles() rehydrates from Keychain after UserDefaults load
│   │                                   # enterManualSessionKey() writes to Keychain, not profile struct
│   │                                   # syncCredentialsFromKeychain() writes to Keychain, not profile struct
│   ├── TokenManager.swift             # Remove updateKeychainCredentials() write-back; add log message
│   ├── AdminAPIClient.swift           # Replace two print() error body calls with Logger (private)
│   └── WebhookManager.swift          # Add HTTPS scheme check in postJSON(_:to:)
└── Utilities/
    └── Constants.swift                # Add profilesKeychainService = "ai.tokemon.profiles"
```

### Pattern 1: Profile Credentials in Keychain (Preferred Migration)

**What:** Store `claudeSessionKey` and `cliCredentialsJSON` per profile in Keychain under service `ai.tokemon.profiles`, account = `profile.id.uuidString`. The Profile struct continues to carry these fields in memory. On save, credentials are stripped from the UserDefaults-encoded JSON. On load, credentials are re-populated from Keychain.

**When to use:** Every time `saveProfiles()` or `loadProfiles()` runs.

**Rationale:** This is the minimal-diff approach. It does not require changing how Profile is used throughout the app. The copy/switch architecture in ProfileManager is preserved. The Keychain service `ai.tokemon.profiles` is separate from `Claude Code-credentials`, avoiding any access conflicts.

**Example:**
```swift
// Source: KeychainAccess README + existing AdminAPIClient.swift pattern
import KeychainAccess

// In Constants.swift
static let profilesKeychainService = "ai.tokemon.profiles"

// In ProfileManager.saveProfiles():
private func saveProfiles() {
    let keychain = Keychain(service: Constants.profilesKeychainService)
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601

    // Save each profile's credentials to Keychain
    for profile in profiles {
        let accountKey = profile.id.uuidString
        if let sessionKey = profile.claudeSessionKey {
            try? keychain.set(sessionKey, key: "\(accountKey).sessionKey")
        } else {
            try? keychain.remove("\(accountKey).sessionKey")
        }
        if let credJSON = profile.cliCredentialsJSON {
            try? keychain.set(credJSON, key: "\(accountKey).cliCredentials")
        } else {
            try? keychain.remove("\(accountKey).cliCredentials")
        }
    }

    // Save profiles to UserDefaults WITHOUT credentials
    var profilesWithoutCredentials = profiles
    for i in profilesWithoutCredentials.indices {
        profilesWithoutCredentials[i].claudeSessionKey = nil
        profilesWithoutCredentials[i].cliCredentialsJSON = nil
    }
    do {
        let data = try encoder.encode(profilesWithoutCredentials)
        UserDefaults.standard.set(data, forKey: Constants.profilesStorageKey)
    } catch {
        logger.error("Failed to encode profiles: \(error.localizedDescription, privacy: .public)")
    }
    // ... activeProfileId save unchanged
}

// In ProfileManager.loadProfiles():
private func loadProfiles() {
    // Load struct data from UserDefaults (no credentials)
    // ... existing decode logic ...

    // Re-populate credentials from Keychain
    let keychain = Keychain(service: Constants.profilesKeychainService)
    for i in profiles.indices {
        let accountKey = profiles[i].id.uuidString
        profiles[i].claudeSessionKey = try? keychain.getString("\(accountKey).sessionKey")
        profiles[i].cliCredentialsJSON = try? keychain.getString("\(accountKey).cliCredentials")
    }
}
```

**Cleanup on profile deletion:** When `deleteProfile(id:)` runs, remove the Keychain entries:
```swift
// In deleteProfile(id:), after profiles.remove(at: index):
let keychain = Keychain(service: Constants.profilesKeychainService)
let accountKey = id.uuidString
try? keychain.remove("\(accountKey).sessionKey")
try? keychain.remove("\(accountKey).cliCredentials")
```

### Pattern 2: OSLog Logger for Structured Logging

**What:** Replace all `print("[Tag] ...")` calls with `OSLog.Logger`. Non-literal string values are redacted by default in Console.app when the app runs on a user's device outside Xcode.

**When to use:** All `print()` calls in Services/. The two security-critical calls in AdminAPIClient.swift (lines 369 and 493) log response bodies that may contain API error details. All ProfileManager and TokenManager calls log credential-adjacent data.

**Example:**
```swift
// Source: https://www.avanderlee.com/debugging/oslog-unified-logging/
import OSLog

// Define loggers per service file (top of file or in extension)
private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "AdminAPIClient")

// BEFORE (line 369, AdminAPIClient.swift):
let body = String(data: data, encoding: .utf8) ?? "no body"
print("[AdminAPI] cost_report error \(httpResponse.statusCode): \(body)")

// AFTER:
let body = String(data: data, encoding: .utf8) ?? "no body"
logger.error("cost_report error \(httpResponse.statusCode, privacy: .public): \(body, privacy: .private)")
// 'body' is marked .private: redacted in Console.app on user devices
// statusCode is .public: visible for debugging (not sensitive)
```

**Privacy rules for this codebase:**
| Data type | Privacy annotation |
|-----------|-------------------|
| HTTP status codes | `.public` |
| Profile names | `.public` (user-chosen display names, not secrets) |
| Error descriptions (non-credential) | `.public` |
| HTTP response bodies | `.private` (may contain token/API data) |
| Credential JSON strings | `.private` |
| Session keys / access tokens | `.private` |

### Pattern 3: HTTPS Enforcement in WebhookManager

**What:** Before posting to a webhook URL, validate the URL scheme is `https`. Reject `http://` and non-URL strings with a clear error.

**When to use:** In `postJSON(_:to:)` before creating the `URLRequest`.

**Example:**
```swift
// In WebhookManager.postJSON(_:to:):
private static func postJSON(_ payload: [String: Any], to urlString: String) async throws {
    guard let url = URL(string: urlString) else {
        throw WebhookError.invalidURL
    }
    // ADD THIS CHECK:
    guard url.scheme == "https" else {
        throw WebhookError.insecureURL  // add this case to WebhookError enum
    }
    // ... rest unchanged
}

// Add to WebhookError enum:
case insecureURL

var errorDescription: String? {
    // ...
    case .insecureURL:
        return "Webhook URL must use HTTPS"
}
```

**UI impact:** The Settings > Webhooks view should show the error when `testWebhook` throws `.insecureURL`, which already propagates errors to the UI. No additional UI changes needed beyond potentially surfacing a clearer error message.

### Pattern 4: Disable TokenManager Keychain Write-Back

**What:** Remove the call to `updateKeychainCredentials` (or make it a no-op with a clear comment) to prevent Tokemon from writing refreshed tokens back to the `Claude Code-credentials` Keychain entry owned by Claude Code.

**Why:** Claude Code issue #19456 confirms that Claude Code has its own persistent Keychain ACL issues caused by binary signature changes after auto-updates. A third-party app writing to the same entry compounds this. The safest posture for an open-source tool is to treat Claude Code's credentials as read-only and prompt users to re-authenticate via Claude Code when tokens expire.

**Example:**
```swift
// In TokenManager.swift, updateKeychainCredentials(response:) becomes:
static func updateKeychainCredentials(response: OAuthTokenResponse) throws {
    // NOTE: Write-back disabled. Writing to Claude Code's Keychain entry
    // risks ACL conflicts with Claude Code's own token refresh mechanism.
    // Instead, notify the caller to prompt user re-authentication.
    // See: https://github.com/anthropics/claude-code/issues/19456
    logger.info("Token refresh available but write-back disabled to avoid Keychain conflict with Claude Code")
}
```

**Caller impact:** Check where `updateKeychainCredentials` is called and ensure the caller presents a "Please run 'claude /login' to refresh your session" message when `TokenError.expired` is thrown and refresh is unavailable.

### Anti-Patterns to Avoid

- **Storing credentials in UserDefaults:** UserDefaults is a plaintext plist at `~/Library/Preferences/ai.tokemon.app.plist`. Any app on the system can read it. Never store tokens, session keys, or credential JSON here.
- **Using `print()` for anything credential-adjacent:** `print()` is always visible in Console.app to any app with Console access. Use `OSLog.Logger` with `.private` annotations for anything that could contain secrets.
- **Accepting HTTP webhook URLs:** Webhook payloads contain usage data; they should travel encrypted. An HTTP URL is a user error — reject it with a clear message rather than sending plaintext data to an unencrypted endpoint.
- **Enabling app sandboxing without validating subprocess execution:** `ProfileManager.syncCredentialsFromKeychain` and `writeCredentialsToKeychain` use `Process()` to invoke `/usr/bin/security`. Sandboxed apps cannot execute arbitrary binaries. Enabling sandboxing without refactoring these to use `KeychainAccess` directly would break all profile switching.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Keychain encryption | Custom AES/encryption layer on top of UserDefaults | `KeychainAccess` (already installed) | macOS Keychain encrypts at rest using hardware-backed keys; any custom encryption is weaker and adds key management complexity |
| Logging framework with privacy | Custom logger struct with redaction logic | `OSLog.Logger` (system) | Apple's unified logging is zero-overhead, has built-in privacy tiers, integrates with Console.app and Instruments, requires no dependencies |
| URL protocol checking | Regex or string prefix matching | `URL.scheme == "https"` | Swift's `URL` type parses RFC 3986 correctly; `url.scheme` is reliable; regex on URL strings misses edge cases like `HTTPS://` (case) or `javascript:` |
| Profile credential migration | One-time migration script run at launch | Implement in `loadProfiles()` with a migration version flag in UserDefaults | Simpler, no separate migration layer needed; load detects missing Keychain entries and migrates from UserDefaults if present |

**Key insight:** For Keychain and logging on macOS, Apple's own APIs outperform custom solutions by definition — they have access to hardware security features and OS-level integration that third-party code cannot replicate.

## Common Pitfalls

### Pitfall 1: Migrating Existing Users' Credentials

**What goes wrong:** After shipping the Keychain migration, existing users who already have profiles stored in UserDefaults (with credentials) will lose credentials on first launch because `loadProfiles()` looks in Keychain and finds nothing.

**Why it happens:** The migration strips credentials from UserDefaults but only writes them to Keychain going forward. Existing UserDefaults data still has credentials in it.

**How to avoid:** Implement a one-time migration in `loadProfiles()`. After decoding profiles from UserDefaults, check if Keychain is empty for a profile AND the decoded profile has non-nil credentials. If so, write them to Keychain and then strip from UserDefaults. Use a UserDefaults flag `tokemon.credentialsMigratedToKeychain` to avoid re-running migration.

**Example:**
```swift
// Migration check in loadProfiles():
let hasMigrated = UserDefaults.standard.bool(forKey: "tokemon.credentialsMigratedToKeychain")
if !hasMigrated {
    let keychain = Keychain(service: Constants.profilesKeychainService)
    for profile in profiles {
        let key = profile.id.uuidString
        if let sk = profile.claudeSessionKey {
            try? keychain.set(sk, key: "\(key).sessionKey")
        }
        if let cj = profile.cliCredentialsJSON {
            try? keychain.set(cj, key: "\(key).cliCredentials")
        }
    }
    UserDefaults.standard.set(true, forKey: "tokemon.credentialsMigratedToKeychain")
}
```

**Warning signs:** Users report losing profile credentials after update; profiles show "no credentials" after upgrade.

### Pitfall 2: KeychainAccess Throws on Nil (Not Just Failure)

**What goes wrong:** `try? keychain.getString(key)` returns `nil` for both "key doesn't exist" and "Keychain error." Silently treating both as "no credentials" is correct behavior here, but callers that need to distinguish "migrated and empty" from "Keychain error" must use `try keychain.getString(key)` and catch the error.

**Why it happens:** The `try?` pattern swallows Keychain errors (e.g., user denied Keychain access, corrupted entry). For profile credentials this is acceptable — treating a Keychain error as "no credentials" will prompt the user to re-sync. But for the AdminAPIClient's `hasAdminKey()`, a Keychain error currently returns `false` (line 27), which is the correct safe default.

**How to avoid:** Stick with `try?` for credential reads; use `try` with error handling only where you need to surface Keychain errors to the UI.

### Pitfall 3: OSLog Privacy in Debug vs Release

**What goes wrong:** `privacy: .private` redacts values in Console.app on user devices, but in Xcode debugger builds, private values ARE visible. Developers can be lulled into thinking logging is working when it only works in debug.

**Why it happens:** Apple deliberately makes `.private` show values in debug builds for developer convenience. In production (App Store / notarized distribution), `.private` values appear as `<private>`.

**How to avoid:** When testing the logging change, run the built app from Finder (not Xcode) and observe Console.app to confirm `.private` values are redacted. Do not rely on Xcode output to verify privacy behavior.

### Pitfall 4: Sandboxing Breaks Process Execution

**What goes wrong:** Enabling `com.apple.security.app-sandbox = true` in Tokemon.entitlements causes `ProfileManager.syncCredentialsFromKeychain` and `writeCredentialsToKeychain` to fail at runtime. Both methods use `Process()` to call `/usr/bin/security`. Sandboxed apps cannot spawn arbitrary child processes; the macOS sandbox profile blocks this.

**Why it happens:** The sandboxed app's process invocation of `/usr/bin/security` results in `Operation not permitted` from Mandatory Access Control. This breaks the entire profile switch/sync mechanism.

**How to avoid:** Do not enable sandboxing in this phase without first refactoring ProfileManager to use `KeychainAccess` directly instead of `/usr/bin/security` subprocess calls. That is a separate, larger refactor. Document this as a prerequisite for any future sandboxing effort.

### Pitfall 5: HTTPS Check Breaks Localhost/Test URLs

**What goes wrong:** Some Slack/Discord webhook developers use `http://localhost` for local testing. Adding a strict HTTPS-only check breaks this use case.

**Why it happens:** The check `url.scheme == "https"` blocks any non-HTTPS URL including local development servers.

**How to avoid:** This is an acceptable trade-off for a security fix. Document in the Settings UI that webhook URLs must use HTTPS. If developer testing is a concern, `http://localhost` could be exempted explicitly, but this adds complexity for minimal benefit given Tokemon's audience.

## Code Examples

Verified patterns from official sources:

### OSLog Logger Setup (per-file pattern)
```swift
// Source: https://www.avanderlee.com/debugging/oslog-unified-logging/
import OSLog

// At file scope or in a private extension:
private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ProfileManager")

// Usage:
logger.info("Loaded \(profiles.count, privacy: .public) profile(s)")
logger.error("Failed to encode profiles: \(error.localizedDescription, privacy: .public)")
// HTTP response body (sensitive):
logger.error("cost_report error \(httpResponse.statusCode, privacy: .public): \(body, privacy: .private)")
```

### KeychainAccess Store/Retrieve Pattern (already used in AdminAPIClient)
```swift
// Source: kishikawakatsumi/KeychainAccess README (existing project pattern)
let keychain = Keychain(service: "ai.tokemon.profiles")

// Store
try keychain.set(credentialsJSON, key: "\(profileId.uuidString).cliCredentials")

// Retrieve (returns nil if not found, does not throw)
let credJSON: String? = try? keychain.getString("\(profileId.uuidString).cliCredentials")

// Delete
try? keychain.remove("\(profileId.uuidString).cliCredentials")
```

### HTTPS Scheme Validation
```swift
// Standard Swift URL.scheme check
guard let url = URL(string: urlString), url.scheme == "https" else {
    throw WebhookError.insecureURL
}
```

### Token Write-Back Removal Pattern
```swift
// In TokenManager.updateKeychainCredentials:
// Replace the current implementation with a no-op + log
static func updateKeychainCredentials(response: OAuthTokenResponse) throws {
    // Intentional no-op: Tokemon does not write back to Claude Code's Keychain entry.
    // Doing so risks ACL conflicts after Claude Code auto-updates.
    // Users should run 'claude /login' to refresh expired tokens.
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `print()` for logging | `OSLog.Logger` with privacy annotations | macOS 10.12 (2016), simplified in Swift 5.5 (2021) | `print()` is always visible; `Logger` redacts private values in production Console.app |
| UserDefaults for all settings | UserDefaults for non-sensitive + Keychain for credentials | Established best practice, not a dated change | UserDefaults is plaintext; Keychain is encrypted at rest |
| HTTP accepted in webhooks | HTTPS enforced | ATS active since macOS 10.11 (2015) | Older code predates ATS; webhook URLs are user-entered so explicit validation still required |
| `NSLog` | `OSLog` / `Logger` | macOS 10.12 | NSLog has no privacy control; Logger has built-in privacy tiers |

**Deprecated/outdated:**
- `print()` for production logging: Not technically deprecated, but not appropriate for production code that handles credentials or sensitive API responses. Use `OSLog.Logger`.
- Keychain write-back to third-party app entries: Never appropriate. Claude Code's Keychain entry belongs to Claude Code. Even without the conflict issue, writing to another app's credential store violates the principle of least privilege.

## Sandboxing Feasibility Analysis

**Verdict: Do not enable sandboxing in this phase.**

Tokemon requires capabilities that conflict with the App Sandbox model:

| Capability Required | Sandbox Compatible? | Notes |
|---------------------|---------------------|-------|
| Read `~/.claude/projects/` for JSONL data | No (without user interaction) | Sandboxed apps need security-scoped bookmarks; user must pick the directory via NSOpenPanel at least once. Could work with persistent bookmark. |
| Read/write Claude Code Keychain entry | No | Sandboxed apps can only access their own Keychain items or shared access groups. Claude Code is not sandboxed and uses no shared access group entitlement. Tokemon cannot join its access group without Claude Code's cooperation. |
| Spawn `/usr/bin/security` process | No | `Process()` with arbitrary executables is blocked by sandbox. ProfileManager's entire copy/switch mechanism relies on this. |
| Network outbound to Anthropic APIs | Yes | `com.apple.security.network.client` entitlement |
| Keychain read/write for own data (profiles, admin key) | Yes | Own Keychain service works fine in sandbox |

**Sandboxing prerequisite (future phase):** Before sandboxing is feasible, ProfileManager must be refactored to use `KeychainAccess` directly (removing the `/usr/bin/security` subprocess dependency), and access to `~/.claude/projects/` must be restructured to use NSOpenPanel with persistent security-scoped bookmarks. This is a significant architectural change beyond the scope of security hardening.

**Document as known limitation:** Add a comment to Tokemon.entitlements explaining why sandboxing is disabled and what prerequisites must be met.

## Open Questions

1. **Does Claude Code's Keychain entry have an access group that Tokemon could join?**
   - What we know: Claude Code stores credentials under service `"Claude Code-credentials"` with account = username. Tokemon reads this via `/usr/bin/security` CLI and via KeychainAccess (service lookup).
   - What's unclear: Whether Claude Code's Keychain entry was created with a specific access group or ACL that Tokemon could be added to via entitlements. This would require inspecting the actual Keychain entry ACL.
   - Recommendation: Not relevant for this phase. The goal is to stop writing to Claude Code's entry, not to find a better way to write to it.

2. **Will disabling token write-back break any existing user workflows?**
   - What we know: `updateKeychainCredentials` is called after a successful token refresh in the OAuth flow. Disabling it means refreshed tokens are not persisted — the next app restart will trigger another refresh (or require re-login if the refresh token also expires).
   - What's unclear: How frequently token refresh is triggered and how long refresh tokens remain valid.
   - Recommendation: Disable the write-back and monitor for user reports. Add a log statement so developers can trace the token refresh path. The 10-minute proactive buffer in `getAccessToken` means users may not notice immediately.

3. **Should webhook URLs stored in UserDefaults be migrated to Keychain?**
   - What we know: `WebhookConfig` (slackWebhookURL, discordWebhookURL) is stored in UserDefaults. These are webhook URLs, not credentials — they don't grant account access by themselves but they do leak the user's workspace Slack/Discord webhook endpoint.
   - What's unclear: Whether community feedback considers webhook URLs sensitive enough to warrant Keychain storage.
   - Recommendation: Out of scope for this phase. The five identified issues are sufficient. Webhook URLs are configuration, not credentials. They could be a Phase 23 enhancement if users request it.

## Sources

### Primary (HIGH confidence)
- Source code inspection: `/Users/richardparr/Tokemon/Tokemon/Services/ProfileManager.swift` — confirms UserDefaults storage of credentials (lines 292-338), subprocess-based Keychain I/O (lines 150-290)
- Source code inspection: `/Users/richardparr/Tokemon/Tokemon/Services/AdminAPIClient.swift` — confirms `print()` of HTTP response bodies (lines 369, 493)
- Source code inspection: `/Users/richardparr/Tokemon/Tokemon/Services/WebhookManager.swift` — confirms `URL(string:)` only validation without HTTPS check (line 369)
- Source code inspection: `/Users/richardparr/Tokemon/Tokemon/Services/TokenManager.swift` — confirms write-back to Claude Code Keychain with explicit warning comment (lines 172-208)
- Source code inspection: `/Users/richardparr/Tokemon/Tokemon/Tokemon.entitlements` — confirms `app-sandbox = false`
- `/Users/richardparr/Tokemon/Package.resolved` — confirms KeychainAccess 4.2.2 already installed
- `https://www.avanderlee.com/debugging/oslog-unified-logging/` — OSLog.Logger API, privacy annotation syntax, subsystem/category pattern
- `https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/EnablingAppSandbox.html` — confirmed entitlements for network, user-selected files; confirmed no blanket home directory entitlement

### Secondary (MEDIUM confidence)
- `https://github.com/anthropics/claude-code/issues/19456` — Claude Code Keychain write conflict confirmed as real, active issue; Tokemon write-back compounds it (WebFetch verified)
- `https://github.com/kishikawakatsumi/KeychainAccess` — KeychainAccess API for service/account key pattern (WebFetch verified)
- Multiple WebSearch results corroborated: OSLog replaces print(), HTTPS enforcement via url.scheme, KeychainAccess for multi-account credential storage

### Tertiary (LOW confidence)
- WebSearch findings on macOS sandbox subprocess execution blocking `/usr/bin/security` — could not directly verify with official Apple documentation due to JavaScript-only Apple docs pages; consistent across multiple sources; treat as HIGH practical risk

## Metadata

**Confidence breakdown:**
- Profile credentials migration to Keychain: HIGH — source confirmed, pattern established, library in place
- OSLog replacement for print(): HIGH — source confirmed issue locations, OSLog API verified from official source
- HTTPS webhook validation: HIGH — source confirmed missing check, fix is 2-line standard Swift
- Token write-back removal: HIGH — source confirmed write-back exists with its own warning comment; Claude Code issue #19456 confirms conflict is real
- Sandboxing infeasibility: HIGH — three blockers verified from source (subprocess calls, Claude Code Keychain entry access, `~/.claude` filesystem access)

**Research date:** 2026-02-20
**Valid until:** 2026-03-22 (30 days; macOS security APIs are stable; KeychainAccess 4.x API is stable)
