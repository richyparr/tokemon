---
phase: 01-foundation-core-monitoring
plan: 02
subsystem: data
tags: [oauth, keychain, jsonl-parser, token-refresh, usage-api, urlsession, keychainaccess]

# Dependency graph
requires:
  - phase: 01-01
    provides: "App shell with UsageMonitor mock polling, data models, constants, menu bar display"
provides:
  - TokenManager reads/validates/refreshes OAuth credentials from macOS Keychain
  - OAuthClient fetches real usage from api.anthropic.com/api/oauth/usage
  - JSONLParser defensively parses ~/.claude/projects/ JSONL session logs
  - UsageMonitor implements OAuth-primary / JSONL-fallback data chain
  - Real usage data displayed in menu bar (percentage or token count)
  - Retry logic with 3-attempt auto-retry then manual retry required
affects: [01-03-PLAN]

# Tech tracking
tech-stack:
  added: []
  patterns: [OAuth bearer auth with automatic token refresh, defensive JSONL line-by-line parsing with skip-on-error, priority data source chain with fallback, single notification then silent fallback error pattern]

key-files:
  created:
    - ClaudeMon/Services/TokenManager.swift
    - ClaudeMon/Services/OAuthClient.swift
    - ClaudeMon/Services/JSONLParser.swift
  modified:
    - ClaudeMon/Services/UsageMonitor.swift
    - ClaudeMon/Models/UsageSnapshot.swift
    - ClaudeMon/ClaudeMonApp.swift

key-decisions:
  - "Token expiry check with 10-minute proactive buffer to avoid mid-request expiration"
  - "Keychain write-back on token refresh implemented but with logged warning about potential Claude Code conflict"
  - "JSONL primaryPercentage sentinel value of -1 to distinguish 'no percentage available' from 0%"
  - "5-hour JSONL window to match OAuth endpoint's five_hour utilization window"

patterns-established:
  - "TokenManager static methods pattern: stateless utility with typed TokenError enum"
  - "OAuth retry pattern: fetchUsageWithTokenRefresh handles expiry check and single retry on 401"
  - "JSONL defensive parsing: skip malformed lines, optional chaining on every field, log skip count"
  - "Data source priority chain: OAuth -> JSONL -> both-failed with per-source state tracking"
  - "Single notification pattern: oauthFailureNotified flag prevents repeated user alerts"

# Metrics
duration: 3min
completed: 2026-02-12
---

# Phase 1 Plan 02: Real Data Layer Summary

**OAuth client fetching usage from api.anthropic.com with Keychain token management, JSONL fallback parser for ~/.claude/projects/ session logs, and full retry logic in UsageMonitor**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-12T11:58:16Z
- **Completed:** 2026-02-12T12:01:30Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- TokenManager reads Claude Code OAuth credentials from macOS Keychain, validates expiry with 10-minute proactive buffer, checks user:profile scope, and refreshes expired tokens via POST to /v1/oauth/token
- OAuthClient fetches real usage data from /api/oauth/usage with Bearer auth, anthropic-beta header, and automatic token refresh on 401
- JSONLParser defensively parses JSONL session logs from all project directories, extracting token counts from assistant messages with full optional chaining (never crashes on malformed input)
- UsageMonitor replaced mock data with real OAuth-primary / JSONL-fallback chain, including one-time failure notification, 3-retry auto limit, and manual retry mechanism
- Menu bar now displays real percentage (OAuth) or formatted token count with "tok" suffix (JSONL fallback)

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement TokenManager and OAuthClient** - `99c5222` (feat)
2. **Task 2: Implement JSONLParser and wire real data into UsageMonitor** - `d5a8100` (feat)

## Files Created/Modified
- `ClaudeMon/Services/TokenManager.swift` - Keychain credential reading, token validation with expiry buffer, token refresh via OAuth endpoint, Keychain write-back
- `ClaudeMon/Services/OAuthClient.swift` - HTTP client for /api/oauth/usage with Bearer auth, status code handling (200/401/403), automatic token refresh cycle
- `ClaudeMon/Services/JSONLParser.swift` - Defensive JSONL parser for ~/.claude/projects/ files, session discovery, line-by-line parsing, aggregate usage computation
- `ClaudeMon/Services/UsageMonitor.swift` - Replaced mock data with real OAuth-first/JSONL-fallback chain, retry logic, manual refresh, one-time error notification
- `ClaudeMon/Models/UsageSnapshot.swift` - Added hasPercentage, totalTokens, formattedTokenCount computed properties, updated menuBarText for dual display modes
- `ClaudeMon/ClaudeMonApp.swift` - Updated StatusItemManager to handle JSONL token-count display with neutral color

## Decisions Made
- **10-minute proactive token refresh buffer:** Access tokens expire after ~8 hours. Rather than waiting for a 401, the TokenManager proactively refreshes when within 10 minutes of expiry. This prevents mid-request failures during the polling cycle.
- **Keychain write-back with warning:** Per research Open Question #3, writing refreshed tokens back to the Keychain may conflict with Claude Code. Implemented the write-back (necessary for token refresh to be useful) but added a console warning. If conflicts arise in testing, this can be disabled.
- **JSONL percentage sentinel (-1):** JSONL data provides raw token counts but no utilization percentage (that requires knowledge of plan limits). Using -1 as a sentinel distinguishes "no percentage available" from "0% usage" and drives the menu bar to show token counts instead.
- **5-hour JSONL window:** The JSONL fallback parses sessions modified in the last 5 hours, matching the OAuth endpoint's five_hour utilization window for a comparable view of recent usage.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None - both tasks compiled and built successfully on the first attempt.

## User Setup Required

None - no external service configuration required. The app reads existing Claude Code credentials from the macOS Keychain automatically.

## Next Phase Readiness
- Real data pipeline complete: OAuth primary, JSONL fallback, retry logic
- Ready for Plan 03: Settings view refinements, popover enhancements, right-click context menu
- The PopoverContentView will need updates in Plan 03 to display JSONL-specific information (token counts vs percentage)
- Error banner in popover should surface the MonitorError messages and "Retry" button for requiresManualRetry state

## Self-Check: PASSED

- All 6 files (3 created, 3 modified) verified on disk
- Both task commits (99c5222, d5a8100) verified in git history
- `swift build` succeeds with zero errors

---
*Phase: 01-foundation-core-monitoring*
*Completed: 2026-02-12*
