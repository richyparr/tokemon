---
phase: 07-multi-account
plan: 01
subsystem: auth
tags: [keychain, multi-account, oauth, codable, observable, migration]

# Dependency graph
requires:
  - phase: 01-foundation
    provides: "TokenManager with Keychain credential access"
  - phase: 06-licensing
    provides: "LicenseManager pattern (Observable, MainActor, callbacks)"
provides:
  - "Account and AccountSettings models for multi-account storage"
  - "TokenManager username-parameterized overloads for per-account credentials"
  - "AccountManager service with CRUD, active account, and migration"
  - "accountsKeychainService constant for account metadata"
affects: [07-02-account-detection, 07-03-account-switcher]

# Tech tracking
tech-stack:
  added: []
  patterns: [per-account-keychain-storage, single-to-multi-migration, account-manager-observable]

key-files:
  created:
    - Tokemon/Models/Account.swift
    - Tokemon/Models/AccountSettings.swift
    - Tokemon/Services/AccountManager.swift
  modified:
    - Tokemon/Utilities/Constants.swift
    - Tokemon/Services/TokenManager.swift

key-decisions:
  - "Separate keychain service (com.tokemon.accounts) for account metadata, never modifying Claude Code's credentials keychain"
  - "Account model uses Codable+Sendable for Keychain JSON storage and Swift 6 concurrency"
  - "Single-account migration runs once via UserDefaults flag, preserving existing alert settings"

patterns-established:
  - "AccountManager pattern: @Observable @MainActor with onActiveAccountChanged callback"
  - "Multi-account credential access: TokenManager overloads keyed by username"

# Metrics
duration: 2min
completed: 2026-02-14
---

# Phase 7 Plan 1: Account Infrastructure Summary

**Account and AccountSettings models with AccountManager service for multi-account CRUD, active account tracking, and automatic single-to-multi migration**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-14T13:42:41Z
- **Completed:** 2026-02-14T13:45:14Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments
- Account and AccountSettings models with full Codable/Sendable conformance for Keychain storage
- TokenManager extended with username-parameterized overloads for per-account credential access
- AccountManager service with account CRUD, active account tracking, and automatic migration from single-account

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Account and AccountSettings models** - `738f2ef` (feat)
2. **Task 2: Add Constants and extend TokenManager** - `0bfaa3f` (feat)
3. **Task 3: Create AccountManager service with migration** - `c57c3e7` (feat)

## Files Created/Modified
- `Tokemon/Models/Account.swift` - Account struct with id, username, displayName, settings, createdAt, hasValidCredentials
- `Tokemon/Models/AccountSettings.swift` - Per-account preferences (alertThreshold, notificationsEnabled, monthlyBudgetCents)
- `Tokemon/Services/AccountManager.swift` - Central account coordinator with CRUD, active account, migration
- `Tokemon/Utilities/Constants.swift` - Added accountsKeychainService constant
- `Tokemon/Services/TokenManager.swift` - Added username-parameterized overloads for multi-account access

## Decisions Made
- Separate keychain service (com.tokemon.accounts) for account metadata to avoid any modification of Claude Code's credentials keychain
- Account model uses Codable+Sendable for Keychain JSON storage and Swift 6 concurrency safety
- Single-account migration runs once via UserDefaults flag, preserving existing alert settings into the new per-account structure

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Account infrastructure complete, ready for account detection (07-02) using KeychainAccess.allKeys() scanning
- AccountManager provides the foundation for account switcher UI (07-03)
- onActiveAccountChanged callback ready for UsageMonitor integration

## Self-Check: PASSED

- All 3 created files verified on disk
- All 3 task commits verified in git log (738f2ef, 0bfaa3f, c57c3e7)

---
*Phase: 07-multi-account*
*Completed: 2026-02-14*
