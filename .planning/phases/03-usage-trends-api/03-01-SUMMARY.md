---
phase: 03-usage-trends-api
plan: 01
subsystem: api
tags: [swift, actor, json-persistence, codable, time-series]

# Dependency graph
requires:
  - phase: 01-foundation
    provides: "UsageSnapshot model and UsageMonitor polling infrastructure"
provides:
  - "UsageDataPoint time-series model for historical data"
  - "HistoryStore actor with JSON persistence and 30-day trim"
  - "UsageMonitor.usageHistory property for chart binding"
affects: [03-02-PLAN, 03-03-PLAN]

# Tech tracking
tech-stack:
  added: []
  patterns: [actor-based persistence, ISO8601 JSON encoding, time-series recording]

key-files:
  created:
    - Tokemon/Models/UsageDataPoint.swift
    - Tokemon/Services/HistoryStore.swift
  modified:
    - Tokemon/Services/UsageMonitor.swift

key-decisions:
  - "Actor isolation for HistoryStore instead of DispatchQueue (Swift concurrency native)"
  - "Synchronous throws instead of async throws for HistoryStore methods (no actual async work)"
  - "30-day automatic trim on every append to prevent unbounded file growth"
  - "ISO8601 date encoding for human-readable JSON persistence"

patterns-established:
  - "Actor-based persistence: HistoryStore pattern for thread-safe file I/O"
  - "History recording: recordHistory() called after each successful data fetch"

# Metrics
duration: 3min
completed: 2026-02-13
---

# Phase 3 Plan 1: Historical Data Persistence Summary

**UsageDataPoint model with actor-isolated HistoryStore persisting usage snapshots as JSON to Application Support**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-13T06:02:23Z
- **Completed:** 2026-02-13T06:05:09Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments
- UsageDataPoint Codable struct that captures essential metrics from UsageSnapshot for time-series storage
- HistoryStore actor with JSON persistence to ~/Library/Application Support/Tokemon/usage_history.json
- UsageMonitor integration that records every successful OAuth and JSONL refresh to history

## Task Commits

Each task was committed atomically:

1. **Task 1: Create UsageDataPoint model** - `5fa7dca` (feat)
2. **Task 2: Create HistoryStore actor with JSON persistence** - `75784dd` (feat)
3. **Task 3: Wire HistoryStore to UsageMonitor** - `2c1050f` (feat)

## Files Created/Modified
- `Tokemon/Models/UsageDataPoint.swift` - Time-series data point model with Codable, Identifiable, Sendable conformance
- `Tokemon/Services/HistoryStore.swift` - Actor-isolated JSON persistence with 30-day trim and ISO8601 encoding
- `Tokemon/Services/UsageMonitor.swift` - Added historyStore integration, usageHistory property, and recordHistory() method

## Decisions Made
- Used synchronous `throws` instead of `async throws` for HistoryStore methods since the underlying file I/O is synchronous; actor isolation provides the concurrency safety
- Extracted `recordHistory()` as a private helper to keep the refresh() method clean and avoid duplicating history recording code in both OAuth and JSONL success paths
- Made historyStore `@ObservationIgnored` since it is a private implementation detail not needed for SwiftUI observation

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- UsageDataPoint model and HistoryStore are ready for Plan 03-02 (trend charts and SwiftUI visualization)
- `usageHistory` property on UsageMonitor provides direct binding for chart views
- `getHistory(since:)` enables filtered time ranges for chart zoom levels

## Self-Check: PASSED

All 3 created/modified files verified on disk. All 3 task commits verified in git history.

---
*Phase: 03-usage-trends-api*
*Completed: 2026-02-13*
