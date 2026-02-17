---
phase: 11-multi-profile-foundation
verified: 2026-02-17T08:00:00Z
status: passed
score: 5/5 must-haves verified
---

# Phase 11: Multi-Profile Foundation Verification Report

**Phase Goal:** Users can manage multiple Claude accounts with credential switching, replacing the removed v2.0 multi-account feature with a copy/switch architecture that works with Claude Code's keychain.
**Verified:** 2026-02-17T08:00:00Z
**Status:** passed
**Re-verification:** No -- initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | User can create a named profile and see it listed in the app | VERIFIED | ProfileManager.createProfile() (line 54, ProfileManager.swift) creates and persists profiles. ProfilesSettings.swift renders profile list with List selection, inline "Add Profile" text field calling createProfile(). |
| 2 | User can sync credentials from the system keychain into a profile and enter manual session keys for secondary accounts | VERIFIED | ProfileManager.syncCredentialsFromKeychain() (line 150) reads via /usr/bin/security find-generic-password. ProfileManager.enterManualSessionKey() (line 203) stores manual keys. ProfilesSettings.swift has "Sync from Keychain" button and SecureField for manual entry. |
| 3 | User can switch active profile and the app writes that profile's credentials to the system keychain for Claude Code to use | VERIFIED | ProfileManager.setActiveProfile() (line 119) calls writeCredentialsToKeychain() which uses /usr/bin/security delete-generic-password + add-generic-password -U. ProfileSwitcherView Menu dropdown calls setActiveProfile. ProfilesSettings has "Switch to This Profile" button. TokemonApp wires onActiveProfileChanged to monitor.refresh(). |
| 4 | User can delete a profile they no longer need | VERIFIED | ProfileManager.deleteProfile() (line 69) with guards for last-profile, active-profile handling, and default reassignment. ProfilesSettings has trash button per profile with delete confirmation alert (.alert with destructive button). |
| 5 | User can see usage summaries for all profiles simultaneously in the menu bar popover | VERIFIED | UsageMonitor.refreshAllProfiles() (line 330) uses TaskGroup to fetch usage for all non-active profiles in parallel using OAuthClient.fetchUsageWithCredentials/fetchUsageWithSessionKey. PopoverContentView has "All Profiles" section (line 57-97) showing each profile name, active indicator dot, and usage percentage. |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `Tokemon/Models/Profile.swift` | Profile model with credential storage | VERIFIED | 50 lines. struct Profile with Identifiable, Codable, Sendable. Fields: id, name, claudeSessionKey, organizationId, cliCredentialsJSON, isDefault, createdAt, lastUsage, lastSynced. hasCredentials computed property. create() factory. |
| `Tokemon/Services/ProfileManager.swift` | Profile CRUD, sync, switch, persistence | VERIFIED | 371 lines. @Observable @MainActor class. createProfile, deleteProfile, updateProfileName, setActiveProfile, syncCredentialsFromKeychain, enterManualSessionKey, writeCredentialsToKeychain, updateProfileUsage, saveProfiles, loadProfiles, constructCredentialsJSON. |
| `Tokemon/Views/Settings/ProfilesSettings.swift` | Full profile management UI in Settings | VERIFIED | 296 lines. Profile list with selection, active badge, credential status text, sync/delete buttons per row. Detail section with name editing, credential status, Sync from Keychain button, SecureField for manual session key, org ID field, Save Manual Credentials button, Switch to This Profile button. Delete confirmation alert. |
| `Tokemon/Views/MenuBar/ProfileSwitcherView.swift` | Compact profile switcher for popover header | VERIFIED | 48 lines. Menu dropdown with person.crop.circle icon, active profile name, chevron. Lists all profiles with checkmark on active. Calls setActiveProfile on selection. |
| `Tokemon/Services/OAuthClient.swift` (modified) | Credential-parameterized OAuth fetch methods | VERIFIED | fetchUsageWithCredentials() at line 120 decodes JSON, checks expiry, refreshes if needed, fetches usage. fetchUsageWithSessionKey() at line 154 uses session key as Bearer token. |
| `Tokemon/Services/UsageMonitor.swift` (modified) | Multi-profile polling | VERIFIED | profileManager property at line 89. refreshAllProfiles() at line 330 uses TaskGroup for parallel fetch. Active profile usage cached in both OAuth and JSONL success paths (lines 217-220, 259-262). |
| `Tokemon/Views/MenuBar/PopoverContentView.swift` (modified) | Multi-profile usage summary section | VERIFIED | ProfileManager environment at line 13. ProfileSwitcherView conditional at line 44. "All Profiles" section at lines 57-97 with green dot active indicator, profile names, usage percentages, usageColor helper. |
| `Tokemon/TokemonApp.swift` (modified) | ProfileManager wired as environment | VERIFIED | @State profileManager at line 18. .environment(profileManager) for both popover (line 117) and Settings (line 199). SettingsWindowController.setProfileManager (line 139). monitor.profileManager = profileManager (line 142). onActiveProfileChanged callback triggering monitor.refresh() (lines 145-149). Dynamic popover height for profiles (lines 43-48). |
| `Tokemon/Views/Settings/SettingsView.swift` (modified) | Profiles tab added | VERIFIED | ProfilesSettings as first tab (line 13-16) with person.2 icon. |
| `Tokemon/Services/SettingsWindowController.swift` (modified) | ProfileManager setter and environment injection | VERIFIED | profileManager property (line 16), setProfileManager() (line 46), guard check (line 85), .environment(profileManager) (line 96). |
| `Tokemon/Utilities/Constants.swift` (modified) | Profile storage keys | VERIFIED | profilesStorageKey (line 67), activeProfileIdKey (line 70), claudeCodeKeychainService (line 76). |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| ProfilesSettings.swift | ProfileManager.swift | @Environment(ProfileManager.self) | WIRED | Line 7: environment declaration. Called: createProfile, deleteProfile, syncCredentialsFromKeychain, enterManualSessionKey, setActiveProfile, updateProfileName. |
| ProfileSwitcherView.swift | ProfileManager.swift | @Environment(ProfileManager.self) | WIRED | Line 7: environment declaration. Line 19: profileManager.setActiveProfile. Line 24: activeProfileId check. |
| TokemonApp.swift | ProfileManager.swift | @State private var profileManager | WIRED | Line 18: state declaration. Line 117+199: environment passing. Line 139: SettingsWindowController. Line 142: monitor.profileManager. Lines 145-149: onActiveProfileChanged callback. |
| PopoverContentView.swift | ProfileManager.swift | @Environment(ProfileManager.self) | WIRED | Line 13: environment declaration. Line 44: profiles.count check. Line 57: profiles.count check for summary. Lines 66-95: ForEach profiles with lastUsage display. |
| UsageMonitor.swift | ProfileManager.swift | profileManager property | WIRED | Line 89: property declaration. Lines 217-220, 259-262: updateProfileUsage for active. Lines 330-370: refreshAllProfiles reads profiles, filters by activeProfileId, calls updateProfileUsage. |
| UsageMonitor.swift | OAuthClient.swift | fetchUsageWithCredentials/fetchUsageWithSessionKey | WIRED | Lines 347-352: calls fetchUsageWithCredentials for cliCredentialsJSON, fetchUsageWithSessionKey for session keys. |
| ProfileManager.swift | System keychain | /usr/bin/security CLI | WIRED | syncCredentialsFromKeychain: find-generic-password (line 162). writeCredentialsToKeychain: delete-generic-password (line 244) + add-generic-password -U (line 264). |

### Requirements Coverage

| Requirement | Status | Blocking Issue |
|-------------|--------|----------------|
| PROF-01: Create multiple profiles with custom names | SATISFIED | -- |
| PROF-02: Sync CLI credentials from system keychain to profile | SATISFIED | -- |
| PROF-03: Enter manual session keys for secondary accounts | SATISFIED | -- |
| PROF-04: Switch between profiles (writes credentials to system keychain) | SATISFIED | -- |
| PROF-05: Delete profiles | SATISFIED | -- |
| PROF-06: See all profiles' usage in menu bar simultaneously | SATISFIED | -- |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| -- | -- | No anti-patterns found | -- | -- |

No TODOs, FIXMEs, placeholders, empty implementations, or stub patterns detected in any phase 11 artifacts.

### Human Verification Required

### 1. Profile Creation and Listing

**Test:** Open Settings, go to Profiles tab, click Add Profile, enter a name, confirm.
**Expected:** Profile appears in the list immediately with "No credentials" status.
**Why human:** Visual rendering, list selection behavior, inline text field UX.

### 2. Keychain Sync

**Test:** With Claude Code already authenticated, click "Sync from Keychain" on a profile.
**Expected:** Status changes to "Synced X ago" and credentials are stored internally.
**Why human:** Requires actual system keychain with Claude Code credentials present. Keychain permission prompt may appear.

### 3. Manual Session Key Entry

**Test:** Select a profile, enter a session key in the SecureField, optionally an org ID, click "Save Manual Credentials".
**Expected:** Status changes to "Manual key". Credentials stored for that profile.
**Why human:** SecureField input masking, form validation UX.

### 4. Profile Switching

**Test:** Create two profiles with credentials. Switch between them via the popover dropdown or Settings "Switch to This Profile" button.
**Expected:** Active profile changes, green dot moves, credentials are written to system keychain (verifiable via `security find-generic-password -s "Claude Code-credentials" -a $USER -w`).
**Why human:** Requires end-to-end keychain write verification. Profile switch callback triggering monitor refresh.

### 5. Profile Deletion

**Test:** Delete a non-active profile. Then try deleting the active profile.
**Expected:** Confirmation alert appears. On confirm, profile is removed. Deleting active profile switches to another first. Cannot delete last profile (button disabled).
**Why human:** Alert dialog behavior, edge case handling for active/last profile.

### 6. Multi-Profile Usage Display

**Test:** With two profiles that have valid credentials, wait for a polling cycle.
**Expected:** "All Profiles" section appears in popover showing both profiles with usage percentages and green active dot on the active one.
**Why human:** Requires two valid credential sets. Visual layout, real-time polling behavior, percentage display accuracy.

### Gaps Summary

No gaps found. All 5 observable truths verified. All 11 artifacts pass existence, substantive, and wiring checks. All 7 key links verified as wired. All 6 PROF requirements have supporting implementations. Zero anti-patterns detected. Project compiles cleanly (`swift build` succeeds). All 9 commits match the documented plan execution.

The phase delivers a complete copy/switch multi-profile architecture: Profile model stores credentials internally, ProfileManager handles CRUD + keychain I/O via /usr/bin/security CLI, ProfilesSettings provides full management UI, ProfileSwitcherView provides quick switching, and UsageMonitor polls all profiles simultaneously via TaskGroup with credential-parameterized OAuthClient methods.

---

_Verified: 2026-02-17T08:00:00Z_
_Verifier: Claude (gsd-verifier)_
