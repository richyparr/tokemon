---
phase: 18-extension-foundation
plan: 02
subsystem: ui
tags: [raycast, typescript, react, oauth, api, setup-wizard]

# Dependency graph
requires:
  - 18-01 (extension scaffold, package.json manifest, raycast-env.d.ts types)
provides:
  - constants.ts: API endpoint constants ported from Swift Constants.swift
  - api.ts: fetchUsage function with TokenError class, token trimming, proper headers
  - setup.tsx: Setup wizard with markdown guide and openExtensionPreferences action
  - index.tsx: Stub dashboard that reads token from preferences and validates via fetchUsage
affects:
  - 19-dashboard-command (imports fetchUsage from api.ts, extends index.tsx)
  - 20-setup-command (extends or replaces setup.tsx)
  - 21-store-submission

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "useEffect + useState pattern for async data fetch in Raycast commands"
    - "TokenError class (extends Error) for distinguishing token errors from network errors"
    - "Token trimming before use to prevent whitespace-only tokens passing required:true check"
    - "openExtensionPreferences() as primary action in both setup and error recovery flows"

key-files:
  created:
    - tokemon-raycast/src/constants.ts
    - tokemon-raycast/src/api.ts
  modified:
    - tokemon-raycast/src/setup.tsx
    - tokemon-raycast/src/index.tsx

key-decisions:
  - "TokenError extends Error with statusCode field so callers can use instanceof to distinguish token vs network failures"
  - "fetchUsage typed as Promise<unknown> — full response typing deferred to Phase 19"
  - "index.tsx uses useEffect + useState (not useCachedPromise) to keep api.ts dependency-free from @raycast/api"
  - "setup.tsx detects existing token via getPreferenceValues and shows alternate 'Token Configured' UI"

# Metrics
duration: 2min
completed: 2026-02-19
---

# Phase 18 Plan 02: Setup Wizard and API Foundation Summary

**Setup wizard with markdown token guide, fetchUsage with TokenError class and proper OAuth headers, and stub dashboard with token validation — all four source files compile and build cleanly**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-02-19T09:22:53Z
- **Completed:** 2026-02-19T09:24:32Z
- **Tasks:** 2 of 3 complete (Task 3 is human checkpoint)
- **Files modified:** 4

## Accomplishments

- constants.ts: All four API constants ported exactly from Tokemon/Utilities/Constants.swift — USAGE_URL, TOKEN_REFRESH_URL, OAUTH_CLIENT_ID, ANTHROPIC_BETA_HEADER
- api.ts: fetchUsage exports TokenError class (statusCode 401/403) for typed error handling, trims token before use, sends all required headers (Authorization Bearer, Accept application/json, anthropic-beta, User-Agent)
- setup.tsx: Renders Detail with markdown guide covering both browser dev tools and Keychain paths; detects existing token and shows variant UI with "Update Token" action; primary action calls openExtensionPreferences()
- index.tsx: Reads oauthToken from preferences, trims whitespace, calls fetchUsage in useEffect on mount, shows Toast.Style.Failure with "Open Preferences" primaryAction on TokenError, shows Toast.Style.Failure with error message on network failure, shows success stub on valid token
- npm run build succeeds cleanly; npx tsc --noEmit passes; Prettier formatting verified clean

## Task Commits

Each task was committed atomically (in tokemon-raycast/ independent git repo):

1. **Task 1: Create API constants and fetch utility** - `e465cb7` (feat)
2. **Task 2: Implement setup wizard and stub dashboard** - `2ad049f` (feat)

## Files Created/Modified

- `tokemon-raycast/src/constants.ts` — USAGE_URL, TOKEN_REFRESH_URL, OAUTH_CLIENT_ID, ANTHROPIC_BETA_HEADER (ported from Swift Constants.swift)
- `tokemon-raycast/src/api.ts` — fetchUsage(token: string): Promise<unknown> with TokenError class, token trimming, full OAuth headers, 401/403/network error handling
- `tokemon-raycast/src/setup.tsx` — Detail view with two-path markdown guide (browser + Keychain); token-configured variant; openExtensionPreferences primary action
- `tokemon-raycast/src/index.tsx` — getPreferenceValues for token, useEffect fetchUsage call, Toast.Style.Failure on error with openExtensionPreferences action, success stub Detail

## Decisions Made

- `fetchUsage` is typed as `Promise<unknown>` — the plan explicitly defers full response typing to Phase 19
- `TokenError` uses a `statusCode: 401 | 403` field so Phase 19 can distinguish expired vs missing-scope without string parsing
- `api.ts` has zero Raycast imports — it is a pure utility so it can be unit-tested independently of the Raycast environment
- `useEffect + useState` used in `index.tsx` rather than `useCachedPromise` to keep api.ts clean of Raycast dependencies

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Prettier auto-fix via direct npx call**
- **Found during:** Task 2 verification
- **Issue:** `ray lint` exits with code 2 due to pre-existing author validation error ("tokemon" not a registered Raycast user), blocking the Prettier fix stage from running
- **Fix:** Ran `npx prettier --write` directly; all files reported as already correctly formatted. The Prettier "error" in ray lint output was caused by ESLint aborting the pipeline, not actual formatting issues
- **Pre-existing issues (not deviations):** Invalid author "tokemon" (placeholder documented in 18-01 decisions) and ESLint ERR_PACKAGE_PATH_NOT_EXPORTED (ESLint 8 vs Node 22 incompatibility, noted in 18-01 summary) — both pre-date this plan

## Pending

- **Task 3 (checkpoint:human-verify):** Human must run `npm run dev` and verify extension loads in Raycast with icon, setup wizard renders correctly, preferences panel opens, and token validation works

## Self-Check: PASSED

Files verified:
- tokemon-raycast/src/constants.ts — created
- tokemon-raycast/src/api.ts — created
- tokemon-raycast/src/setup.tsx — modified (4 → 76 lines)
- tokemon-raycast/src/index.tsx — modified (3 → 91 lines)

Commits verified:
- e465cb7 — feat(18-02): add API constants and fetchUsage utility
- 2ad049f — feat(18-02): implement setup wizard and stub dashboard

Build verified: npm run build exits 0 ("built extension successfully")
TypeScript verified: npx tsc --noEmit exits 0 (no type errors)
