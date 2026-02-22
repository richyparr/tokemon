# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-18)

**Core value:** Know your Claude usage at a glance before hitting limits.
**Current focus:** v4.0 Raycast Integration - Phase 21 Multi-Profile & Alerts

## Current Position

Phase: 20-menu-bar-command
Plan: 1 of 1 complete
Status: Complete
Last activity: 2026-02-22 — Phase 20 complete (Menu bar command verified in Raycast)

Next: Phase 21 (Multi-Profile & Alerts)

Progress: [##########################] v1-v3 complete | 17.1 [##########] 3/3 | 18 [##########] 2/2 | 19 [##########] 2/2 | 20 [##########] 1/1

## Shipped Milestones

- **v1.0 MVP** -- 5 phases, 12 plans (shipped 2026-02-14)
- **v2.0 Pro Features** -- 4 phases, 11 plans (shipped 2026-02-15)
- **v3.0 Competitive Parity & Growth** -- 7 phases, 17 plans (shipped 2026-02-17)

## Performance Metrics

**Cumulative (v1.0-v3.0):**
- Total plans completed: 40
- Total phases: 16
- Lines of code: 14,418 Swift
- Timeline: 6 days (Feb 11-17, 2026)

**Phase 17.1 (Automated Testing):**
- Plan 01: 57 min, 2 tasks, 13 files
- Plan 02: 6 min, 2 tasks, 7 files
- Plan 03: 20 min, 2 tasks, 4 files

**Phase 18 (Raycast Extension Foundation):**
- Plan 01: 2 min, 2 tasks, 12 files
- Plan 02: 5 min, 3 tasks, 5 files (including human checkpoint)

**Phase 19 (Dashboard Command):**
- Plan 01: 5 min, 2 tasks, 5 files
- Plan 02: 5 min, 2 tasks, 1 file (including human checkpoint)

**Phase 20 (Menu Bar Command):**
- Plan 01: 6 min, 2 tasks, 2 files (including human checkpoint)

**v4.0 (TypeScript/React):**
- Codebase in `tokemon-raycast/` (sibling to Tokemon/ Swift project)
- Target: 4 phases, ~8-12 plans

## Accumulated Context

### Decisions

See PROJECT.md Key Decisions table for full list.

**Phase 17.1 Decisions:**
- PRODUCT_MODULE_NAME set to lowercase 'tokemon' to match SPM convention
- Sparkle added to project.yml (was missing from xcodegen config)
- Bundle.module replaced with Bundle.main for Xcode project compatibility
- SnapshotTestCase uses record:.missing for auto-record on first run
- PopoverHeightCalculator extracted as enum with static function for testable height computation
- Snapshot tests use @MainActor to match UsageMonitor/AlertManager isolation
- Pass resetsAt: nil in snapshot test mocks to avoid time-dependent text
- Clear UserDefaults profile data in setUp() to prevent cross-test contamination

**v4.0 Architecture Decisions (from research):**
- Standalone extension (no Tokemon.app dependency)
- TypeScript/React with @raycast/api
- Manual token entry via password preferences (Keychain access causes store rejection)
- useCachedState for instant UI, LocalStorage for persistence
- OAuth token refresh handled automatically after initial entry

**Phase 18 Decisions:**
- tokemon-raycast/ placed as sibling to Tokemon/ Swift project (independent git repo)
- password-type preference for OAuth token (not Keychain) — Keychain causes Store rejection
- package-lock.json committed (required for Raycast Store submission)
- author field set to "tokemon" placeholder — user must update before publishing
- extractToken() handles both full Keychain JSON blob and raw access token transparently
- oauthToken preference required:false so Setup tutorial is visible on first launch
- TokenError extends Error with statusCode: 401 | 403 for typed error handling
- fetchUsage typed as Promise<unknown> — full response typing deferred to Phase 19
- api.ts has zero Raycast imports — pure utility, testable without Raycast environment

**Phase 19 Decisions:**
- vitest chosen over jest: zero-config TypeScript, ESM-native, lightweight (40 packages)
- usageColor returns plain strings ("green" etc.) so utils.ts is testable without @raycast/api mock
- computePace uses ±10 tolerance band to prevent jitter from flipping pace status
- parseResetDate returns null (not throws) for invalid input — safer for display code
- colorMap/paceConfig lookup tables in index.tsx — keeps @raycast/api Color in UI layer only
- All hooks called unconditionally before early returns — React hook rules compliance
- Conditional Sonnet/Opus rows only shown when utilization is non-null

**Phase 20 Decisions:**
- colorMap duplicated per command (not shared) — keeps commands self-contained
- Icon.CircleFilled + tintColor is only color mechanism for menu bar (title text color not programmable)
- interval: 5m for background refresh — safe for Store submission
- No-token returns MenuBarExtra with Icon.Warning (never null — would hide the item)

### Roadmap Evolution

- Phase 17.1 inserted after Phase 17: Automated Testing — XCTest/XCUITest infrastructure for Swift app UI bugs (URGENT)
- Phase 22 added: Security Hardening — Move profile credentials to Keychain, sanitize error logging, enforce HTTPS webhooks, evaluate sandboxing, fix Keychain write-back conflicts

### Pending Todos

None.

### Blockers/Concerns

None.

## Session Continuity

Last session: 2026-02-22
Stopped at: Phase 20 complete (Menu bar command verified, all 3 MENU requirements met)
Resume file: none
