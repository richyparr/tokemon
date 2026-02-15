---
phase: 08-analytics-export
plan: 01
subsystem: database
tags: [swift, history-store, downsampling, time-series, actor]

# Dependency graph
requires:
  - phase: 07-multi-account
    provides: "Per-account HistoryStore with UUID-based storage"
provides:
  - "90-day usage data retention (up from 30 days)"
  - "Automatic hourly downsampling for data older than 7 days"
  - "Per-account time-range history queries via getHistory(for:since:)"
  - "Per-account history reload via UsageMonitor.reloadHistory(for:)"
affects: [08-02-analytics-views, 08-03-export]

# Tech tracking
tech-stack:
  added: []
  patterns: ["Hourly downsampling with Calendar.dateInterval grouping", "Throttled maintenance via lastDownsampleDates dictionary"]

key-files:
  created: []
  modified:
    - "ClaudeMon/Services/HistoryStore.swift"
    - "ClaudeMon/Services/UsageMonitor.swift"

key-decisions:
  - "Downsampling throttled to once per hour on append to avoid performance overhead"
  - "downsampleOldEntries is func (not private) for potential external testing access"

patterns-established:
  - "Time-series downsampling: group by Calendar hour interval, average numeric fields, preserve first source"
  - "Throttled maintenance: track last-run dates per entity to avoid redundant work"

# Metrics
duration: 2min
completed: 2026-02-15
---

# Phase 8 Plan 1: Extended History & Downsampling Summary

**90-day HistoryStore retention with automatic hourly downsampling for data older than 7 days, reducing storage from ~25MB to ~2.4MB per account**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-15T06:41:32Z
- **Completed:** 2026-02-15T06:43:40Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Extended HistoryStore from 30-day to 90-day data retention
- Implemented automatic hourly downsampling for data beyond 7-day recent window
- Added per-account time-range queries and reload support for analytics views
- Downsampling throttled to once per hour on append for performance

## Task Commits

Each task was committed atomically:

1. **Task 1: Extend HistoryStore retention to 90 days with downsampling** - `2931826` (feat)
2. **Task 2: Ensure UsageMonitor loads extended history correctly** - `75ea868` (feat)

## Files Created/Modified
- `ClaudeMon/Services/HistoryStore.swift` - 90-day retention, recentWindowDays, downsampleOldEntries method, getHistory(for:since:) overload, shouldDownsample throttle
- `ClaudeMon/Services/UsageMonitor.swift` - reloadHistory(for:) per-account overload

## Decisions Made
- Downsampling throttled to once per hour on append via `lastDownsampleDates` dictionary to avoid performance overhead on frequent polling
- `downsampleOldEntries` left as `func` (not `private`) for potential testing access from future plans

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- 90-day history data available for analytics views (Plan 02)
- `getHistory(for:since:)` ready for 30d/90d chart queries
- `reloadHistory(for:)` ready for analytics view data loading
- No blockers for Plan 02 (analytics views) or Plan 03 (export)

## Self-Check: PASSED

- FOUND: ClaudeMon/Services/HistoryStore.swift
- FOUND: ClaudeMon/Services/UsageMonitor.swift
- FOUND: 08-01-SUMMARY.md
- FOUND: commit 2931826
- FOUND: commit 75ea868

---
*Phase: 08-analytics-export*
*Completed: 2026-02-15*
