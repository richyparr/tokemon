# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-18)

**Core value:** Know your Claude usage at a glance before hitting limits.
**Current focus:** v4.0 Raycast Integration - Phase 19 Dashboard Command

## Current Position

Phase: 18-extension-foundation
Plan: 2 of 2 complete
Status: Complete
Last activity: 2026-02-19 — Phase 18 verified (9/9 must-haves passed), human-verified in Raycast

Next: Phase 19 (Dashboard Command)

Progress: [##########################] v1-v3 complete | 17.1 [##########] 3/3 | 18 [##########] 2/2

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

### Roadmap Evolution

- Phase 17.1 inserted after Phase 17: Automated Testing — XCTest/XCUITest infrastructure for Swift app UI bugs (URGENT)

### Pending Todos

None.

### Blockers/Concerns

None.

## Session Continuity

Last session: 2026-02-19
Stopped at: Phase 18 complete and verified. Raycast extension scaffolded at tokemon-raycast/ with setup wizard, token validation, and custom branding.
Resume: Plan Phase 19 (Dashboard Command)
