---
phase: 11-multi-profile-foundation
plan: 01
subsystem: auth
tags: [keychain, profiles, credentials, copy-switch, process, userdefaults]

# Dependency graph
requires:
  - phase: 01-foundation-core-monitoring
    provides: "TokenManager with keychain access patterns and ClaudeCredentials structure"
provides:
  - "Profile model with internal credential storage (cliCredentialsJSON, claudeSessionKey)"
  - "ProfileManager service with full CRUD operations"
  - "Keychain copy/switch operations via /usr/bin/security CLI"
  - "Manual session key entry support"
  - "UserDefaults persistence for profiles"
affects: [11-02, 11-03, 12-multi-profile-ui]

# Tech tracking
tech-stack:
  added: []
  patterns: [copy-switch credential architecture, Process-based keychain I/O]

key-files:
  created:
    - Tokemon/Models/Profile.swift
    - Tokemon/Services/ProfileManager.swift
  modified:
    - Tokemon/Utilities/Constants.swift

key-decisions:
  - "Used Process + /usr/bin/security for keychain I/O instead of KeychainAccess library to avoid permission issues with Claude Code's keychain entry"
  - "UserDefaults for profile persistence (lightweight, no new dependencies) rather than separate keychain or file storage"
  - "Profile stores full JSON blob from system keychain rather than parsing individual fields"

patterns-established:
  - "Copy/switch pattern: credentials stored inside app, written to system keychain on profile switch"
  - "Process-based keychain access: delete-then-add with -U flag for atomic keychain writes"
  - "ProfileManager debug logging with [ProfileManager] prefix"

# Metrics
duration: 2min
completed: 2026-02-17
---

# Phase 11 Plan 01: Profile Data Layer Summary

**Profile model with copy/switch credential architecture using Process-based keychain I/O for multi-profile foundation**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-17T07:23:53Z
- **Completed:** 2026-02-17T07:25:57Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Profile struct with Identifiable, Codable, Sendable conformance storing credentials internally
- ProfileManager with full CRUD (create, delete, rename, set-active) and UserDefaults persistence
- Keychain sync operation reads from system keychain via `/usr/bin/security find-generic-password`
- Keychain write operation pushes credentials to system keychain via `/usr/bin/security add-generic-password`
- Manual session key entry with automatic JSON construction matching TokenManager.ClaudeCredentials format
- Auto-creates default profile and syncs system credentials on first launch

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Profile model and Constants updates** - `a66fd4b` (feat)
2. **Task 2: Create ProfileManager service with CRUD and keychain operations** - `6bf2d6c` (feat)

## Files Created/Modified
- `Tokemon/Models/Profile.swift` - Profile struct with credential fields, hasCredentials computed property, and create factory method
- `Tokemon/Services/ProfileManager.swift` - @Observable @MainActor ProfileManager with CRUD, keychain sync/write, manual entry, UserDefaults persistence
- `Tokemon/Utilities/Constants.swift` - Added profilesStorageKey, activeProfileIdKey, claudeCodeKeychainService constants

## Decisions Made
- Used Process + `/usr/bin/security` CLI for system keychain operations instead of KeychainAccess library -- avoids permission issues with Claude Code's keychain entry and matches the recommended approach from research
- Stored full JSON blob from system keychain rather than parsing individual OAuth fields -- preserves all credential data including subscription type, rate limit tier, and any future fields
- Used UserDefaults for profile persistence -- lightweight, no new dependencies needed, appropriate for the small data size of profile metadata

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Profile model and ProfileManager service ready for UI integration in Plan 02
- `onActiveProfileChanged` callback ready to be wired by TokemonApp
- Copy/switch pattern fully implemented at the service layer

## Self-Check: PASSED

All files verified present. All commits verified in git log. All content requirements confirmed.

---
*Phase: 11-multi-profile-foundation*
*Completed: 2026-02-17*
