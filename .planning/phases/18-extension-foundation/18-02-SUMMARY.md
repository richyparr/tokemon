---
phase: 18-extension-foundation
plan: 02
subsystem: commands
tags: [raycast, typescript, react, oauth, setup-wizard, dashboard]

# Dependency graph
requires:
  - 18-01 (extension scaffold, package.json manifest, raycast-env.d.ts types)
provides:
  - constants.ts: API endpoint constants ported from Swift Constants.swift
  - api.ts: fetchUsage function with TokenError class, extractToken for JSON/raw handling
  - setup.tsx: Setup wizard with markdown guide and openExtensionPreferences action
  - index.tsx: Stub dashboard that reads token from preferences and validates via fetchUsage
affects:
  - 19-dashboard-command (imports fetchUsage from api.ts, extends index.tsx)
  - 20-menu-bar-command (reuses api.ts and constants.ts)
  - 21-multi-profile-alerts (extends preferences and token management)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "extractToken() parses full Keychain JSON blob OR raw access token transparently"
    - "useEffect + useState pattern for async data fetch in Raycast commands"
    - "TokenError class (extends Error) for distinguishing token errors from network errors"
    - "required:false preference + in-command empty check for better first-run UX"
    - "openExtensionPreferences() as primary action in both setup and error recovery flows"

key-files:
  created:
    - tokemon-raycast/src/constants.ts
    - tokemon-raycast/src/api.ts
  modified:
    - tokemon-raycast/src/setup.tsx
    - tokemon-raycast/src/index.tsx
    - tokemon-raycast/package.json

key-decisions:
  - "extractToken() added to handle both full Keychain JSON blob and raw access token"
  - "oauthToken preference changed to required:false so Setup tutorial is visible on first launch"
  - "Setup guide recommends Keychain copy as Option A (paste full JSON, auto-extracted)"
  - "fetchUsage typed as Promise<unknown> — full response typing deferred to Phase 19"
  - "api.ts kept as pure utility (no @raycast/api imports) for testability"

patterns-established:
  - "Pattern: extractToken() for transparent JSON/raw token handling across all commands"
  - "Pattern: TokenError class with statusCode for typed 401/403 error handling"
  - "Pattern: required:false preference + in-command empty check for better first-run UX"

# Metrics
duration: 5min
completed: 2026-02-19
---

# Phase 18 Plan 02: Setup Wizard & Token Validation Summary

**Setup wizard with markdown token guide, fetchUsage with typed errors, and extractToken for transparent Keychain JSON/raw token handling — human-verified working in Raycast**

## Performance

- **Duration:** ~5 min (including human verification)
- **Completed:** 2026-02-19
- **Tasks:** 3/3 (2 auto + 1 human checkpoint approved)
- **Files modified:** 5

## Accomplishments

- constants.ts: All four API constants ported from Tokemon/Utilities/Constants.swift — USAGE_URL, TOKEN_REFRESH_URL, OAUTH_CLIENT_ID, ANTHROPIC_BETA_HEADER
- api.ts: fetchUsage with TokenError class (401/403), extractToken for JSON blob + raw token, proper OAuth headers
- setup.tsx: Markdown guide with Keychain (Option A) and browser DevTools (Option B) paths; token-configured variant
- index.tsx: Token validation on mount, success stub, failure toast with "Open Preferences" recovery
- Human verified: extension loads in Raycast with icon, Setup shows tutorial, Dashboard validates token

## Task Commits

1. **Task 1: Create API constants and fetch utility** - `e465cb7`
2. **Task 2: Implement setup wizard and stub dashboard** - `2ad049f`
3. **Task 3: Human verification** - Approved
4. **Post-checkpoint fix: JSON blob extraction** - `56b42fa`

## Deviations from Plan

- **extractToken() added** — Discovered during human testing that Keychain stores JSON blob, not raw token. Users paste full JSON, extractToken parses it automatically.
- **required:false** — Changed from required:true after user testing revealed Raycast's built-in gate prevents Setup tutorial from being visible on first launch.
- Both deviations improve UX without changing scope.

## Issues Encountered

- OAuth access tokens expire every ~4 hours. User's first paste was stale (macOS app had auto-refreshed). Token refresh is Phase 19+ scope — expected limitation.
- `ray lint` exits with error due to "tokemon" not being a registered Raycast author (placeholder from 18-01), not a code issue.

## Self-Check: PASSED

All 4 source files exist, npm run build passes, human verification approved.
