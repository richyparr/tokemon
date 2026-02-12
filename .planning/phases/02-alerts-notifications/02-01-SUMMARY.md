---
phase: 02-alerts-notifications
plan: 01
subsystem: services, ui
tags: [swift, observable, alerts, menu-bar, swiftui]

# Dependency graph
requires:
  - phase: 01-foundation
    provides: UsageMonitor, UsageSnapshot, StatusItemManager, menu bar infrastructure
provides:
  - AlertManager service with AlertLevel enum (normal/warning/critical)
  - Threshold-based alert checking via checkUsage() method
  - Visual indicators in menu bar (red "!" for critical)
  - Warning banner in popover header for critical alert level
  - Window reset detection (resets notification state on new 5-hour window)
affects: [02-02-notifications, settings-ui, floating-window]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "AlertManager callback pattern via onAlertCheck for loose coupling"
    - "AlertLevel enum with Comparable for threshold comparison"
    - "UserDefaults-backed settings with clamped values (alertThreshold 50-100)"

key-files:
  created:
    - ClaudeMon/Services/AlertManager.swift
  modified:
    - ClaudeMon/Utilities/Constants.swift
    - ClaudeMon/Services/UsageMonitor.swift
    - ClaudeMon/ClaudeMonApp.swift
    - ClaudeMon/Views/MenuBar/UsageHeaderView.swift
    - ClaudeMon/Views/MenuBar/PopoverContentView.swift

key-decisions:
  - "Notification sending stubbed for Plan 02 (separation of concerns)"
  - "Window reset detection via resetsAt timestamp comparison"
  - "AlertLevel uses Int rawValue for Comparable conformance"
  - "Critical shows red with '!' indicator, warning uses gradient color without indicator"

patterns-established:
  - "onAlertCheck callback pattern: UsageMonitor notifies AlertManager on each refresh"
  - "Alert threshold stored in UserDefaults with clamped range (50-100)"

# Metrics
duration: 3min
completed: 2026-02-12
---

# Phase 02 Plan 01: Alert Manager Summary

**AlertManager service with threshold-based alert levels and visual warning indicators in menu bar and popover**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-12T18:26:32Z
- **Completed:** 2026-02-12T18:29:06Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Created AlertManager service with AlertLevel enum (normal/warning/critical)
- Implemented threshold-based checkUsage() method with window reset detection
- Added red "!" indicator in menu bar for critical alert level
- Added warning banner in popover header for critical state
- Wired AlertManager to UsageMonitor via onAlertCheck callback

## Task Commits

Each task was committed atomically:

1. **Task 1: Create AlertManager service** - `87a325a` (feat)
2. **Task 2: Wire AlertManager to UI** - `cb46061` (feat)

## Files Created/Modified

- `ClaudeMon/Services/AlertManager.swift` - AlertManager service with AlertLevel enum, threshold checking, notification state
- `ClaudeMon/Utilities/Constants.swift` - Added defaultAlertThreshold constant (80%)
- `ClaudeMon/Services/UsageMonitor.swift` - Added onAlertCheck callback, invoked on each refresh
- `ClaudeMon/ClaudeMonApp.swift` - Added AlertManager state, environment injection, wiring
- `ClaudeMon/Views/MenuBar/UsageHeaderView.swift` - Added alertLevel property and warning banner for critical
- `ClaudeMon/Views/MenuBar/PopoverContentView.swift` - Pass alertLevel from environment to header

## Decisions Made

- **Notification sending stubbed:** sendNotification() is a no-op stub; actual system notification implementation deferred to Plan 02 for separation of concerns
- **Window reset detection:** Comparing resetsAt timestamp to detect when 5-hour window resets, automatically clearing alert state
- **AlertLevel as Comparable:** Using Int rawValue allows simple > comparison for "crossing into higher level" logic
- **Visual indicator strategy:** Critical gets red color and "!" suffix; warning uses gradient color without extra indicator (subtle differentiation)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- AlertManager ready for system notification integration (Plan 02)
- Settings UI can add alertThreshold slider (future plan)
- Floating window can display alertLevel (Phase 4)

---
*Phase: 02-alerts-notifications*
*Completed: 2026-02-12*

## Self-Check: PASSED

- [x] AlertManager.swift exists at ClaudeMon/Services/AlertManager.swift
- [x] Commit 87a325a exists
- [x] Commit cb46061 exists
- [x] Build succeeds with all changes
