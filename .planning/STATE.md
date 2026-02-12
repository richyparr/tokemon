# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-11)

**Core value:** Know your Claude usage at a glance before hitting limits.
**Current focus:** Phase 1 - Foundation & Core Monitoring

## Current Position

Phase: 1 of 5 (Foundation & Core Monitoring)
Plan: 2 of 3 in current phase
Status: Executing
Last activity: 2026-02-12 -- Completed 01-02 real data layer

Progress: [##........] 20%

## Performance Metrics

**Velocity:**
- Total plans completed: 2
- Average duration: 9min
- Total execution time: 0.28 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-foundation | 2 | 17min | 9min |

**Recent Trend:**
- Last 5 plans: 14min, 3min
- Trend: Accelerating

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Roadmap]: OAuth endpoint is primary data source, JSONL is fallback (not the other way around per research correction)
- [Roadmap]: WidgetKit widget deferred to v2 (refresh budget too limiting for real-time monitoring)
- [Roadmap]: Non-sandboxed distribution via GitHub (required for ~/.claude access)
- [Roadmap]: Design polish phase last (per user preference, after all features built)
- [01-01]: SPM executable target instead of .xcodeproj (Xcode not installed; swift build works)
- [01-01]: StatusItemManager callback pattern to solve menu bar label not updating
- [01-01]: DataSourceState.failed uses String (not Error) for Sendable conformance
- [01-02]: Token expiry check with 10-minute proactive buffer to avoid mid-request expiration
- [01-02]: Keychain write-back on token refresh with logged warning about potential Claude Code conflict
- [01-02]: JSONL primaryPercentage sentinel value of -1 to distinguish no-percentage from 0%
- [01-02]: 5-hour JSONL window to match OAuth five_hour utilization window

### Pending Todos

None yet.

### Blockers/Concerns

- JSONL format is undocumented and has changed between Claude Code versions; defensive parsing required from Phase 1
- Admin API requires org admin keys; most individual Pro/Max users cannot obtain these (DATA-05 is optional enhancement)

## Session Continuity

Last session: 2026-02-12
Stopped at: Completed 01-02-PLAN.md (real data layer)
Resume file: None
