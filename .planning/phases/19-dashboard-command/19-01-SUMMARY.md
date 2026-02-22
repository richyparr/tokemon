---
phase: 19-dashboard-command
plan: 01
subsystem: testing
tags: [typescript, vitest, tdd, types, utilities]

# Dependency graph
requires:
  - phase: 18-extension-foundation
    provides: "api.ts with fetchUsage (previously Promise<unknown>), tokemon-raycast project scaffold"
provides:
  - "UsageData, UsageWindow, ExtraUsage, PaceStatus TypeScript interfaces matching Swift OAuthUsageResponse"
  - "formatCountdown: seconds to human-readable countdown (e.g. 3h 22m 14s)"
  - "computePace: on-track/ahead/behind classification with 10-point tolerance"
  - "parseResetDate: safe ISO-8601 parser returning null on invalid input"
  - "formatPercentage: 0-100 to percentage string, '--' for null/undefined"
  - "usageColor: green/yellow/orange/red thresholds at 40/70/90"
  - "fetchUsage typed as Promise<UsageData> (not Promise<unknown>)"
  - "vitest test infrastructure with 30 passing tests"
affects:
  - 19-02
  - 19-03

# Tech tracking
tech-stack:
  added: ["vitest@2.1.9 (test runner, zero-config TypeScript)"]
  patterns: ["TDD red-green-refactor cycle", "pure utility functions with no @raycast/api imports", "plain color strings mapped to Raycast constants in UI layer"]

key-files:
  created:
    - "tokemon-raycast/src/types.ts"
    - "tokemon-raycast/src/utils.ts"
    - "tokemon-raycast/src/utils.test.ts"
  modified:
    - "tokemon-raycast/src/api.ts"
    - "tokemon-raycast/package.json"

key-decisions:
  - "vitest chosen over jest: zero-config TypeScript, ESM-native, lightweight (40 packages vs jest's ~100)"
  - "utils.ts returns plain color strings ('green', 'yellow', etc.) — UI layer maps to Color.Green; keeps utilities testable without @raycast/api mock"
  - "computePace uses 10-point tolerance band (±10) so normal fluctuation doesn't flip status"
  - "parseResetDate returns null (not throws) for invalid input — safer for display code"

patterns-established:
  - "Utility isolation: utils.ts and types.ts have zero @raycast/api imports — pure TypeScript, testable in Node"
  - "Color mapping: plain strings in utils, Raycast Color enum mapping done in component layer"
  - "TDD workflow: RED commit (test(19-01):) then GREEN commit (feat(19-01):)"

# Metrics
duration: 5min
completed: 2026-02-22
---

# Phase 19 Plan 01: Types and Utilities Summary

**TypeScript interface layer for Claude OAuth usage API with 5 pure utility functions and 30 passing vitest tests, developed test-first**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-02-22T11:20:38Z
- **Completed:** 2026-02-22T11:25:00Z
- **Tasks:** 2 (TDD: RED + GREEN)
- **Files modified:** 5

## Accomplishments
- Created UsageData, UsageWindow, ExtraUsage, PaceStatus TypeScript interfaces mirroring Swift OAuthUsageResponse
- Implemented 5 pure utility functions with full test coverage (30 tests, 30 passing)
- Updated fetchUsage return type from Promise<unknown> to Promise<UsageData>
- Added vitest test runner with npm test/test:watch scripts
- Build verified: npm run build succeeds with no TypeScript errors

## Task Commits

Each task was committed atomically:

1. **Task 1: Create types and write failing tests (RED)** - `744b879` (test)
2. **Task 2: Implement utilities to pass all tests, update api.ts (GREEN)** - `3a8d538` (feat)

_Note: TDD tasks have two commits — RED (failing tests) then GREEN (implementation)_

## Files Created/Modified
- `tokemon-raycast/src/types.ts` - UsageData, UsageWindow, ExtraUsage, PaceStatus interface definitions
- `tokemon-raycast/src/utils.ts` - formatCountdown, computePace, parseResetDate, formatPercentage, usageColor
- `tokemon-raycast/src/utils.test.ts` - 30 unit tests covering all functions and edge cases
- `tokemon-raycast/src/api.ts` - fetchUsage return type updated to Promise<UsageData>
- `tokemon-raycast/package.json` - vitest devDependency + test/test:watch scripts added

## Decisions Made
- **vitest over jest:** Zero-config TypeScript support, ESM-native, lightweight — 40 packages vs jest's heavier footprint. Works out-of-the-box with the existing tsconfig.json (moduleResolution: bundler).
- **Plain color strings in utils:** usageColor returns "green"/"yellow"/"orange"/"red" (not Raycast Color enum values). This keeps utils.ts free of @raycast/api imports so tests run in plain Node without mocking Raycast. The UI layer (index.tsx) maps to Color.Green etc.
- **10-point tolerance for computePace:** A ±10 point band around expected utilization prevents normal API polling jitter from flipping between on-track/ahead/behind.
- **parseResetDate returns null, not throws:** Display code is safer when invalid dates silently degrade to null rather than crashing the render cycle.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- types.ts and utils.ts ready for import in dashboard UI (Plan 02)
- fetchUsage now returns UsageData — dashboard can destructure five_hour, seven_day etc. directly
- vitest test infrastructure in place for any future utility tests
- No blockers

---
*Phase: 19-dashboard-command*
*Completed: 2026-02-22*

## Self-Check: PASSED

- FOUND: tokemon-raycast/src/types.ts
- FOUND: tokemon-raycast/src/utils.ts
- FOUND: tokemon-raycast/src/utils.test.ts
- FOUND: tokemon-raycast/src/api.ts (Promise<UsageData> return type confirmed)
- FOUND: .planning/phases/19-dashboard-command/19-01-SUMMARY.md
- FOUND: commit 744b879 (test RED phase)
- FOUND: commit 3a8d538 (feat GREEN phase)
- utils.ts: no @raycast/api imports (CLEAN)
- types.ts: no @raycast/api imports (CLEAN)
- 30 tests confirmed in utils.test.ts
