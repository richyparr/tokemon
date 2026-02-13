---
phase: 03-usage-trends-api
plan: 02
subsystem: ui
tags: [swift, swift-charts, visualization, burn-rate, time-series, swiftui]

# Dependency graph
requires:
  - phase: 03-usage-trends-api
    plan: 01
    provides: "UsageDataPoint model, HistoryStore actor, UsageMonitor.usageHistory property"
  - phase: 01-foundation
    provides: "UsageSnapshot model, UsageMonitor, PopoverContentView layout"
provides:
  - "BurnRateCalculator with rolling-window rate calculation and time-to-limit projection"
  - "UsageChartView with Swift Charts area/line visualization and 24h/7d toggle"
  - "BurnRateView with color-coded burn rate and urgency-colored time-to-limit"
  - "Popover integration showing trends when OAuth data is available"
affects: [04-design-polish]

# Tech tracking
tech-stack:
  added: [Swift Charts]
  patterns: [area-line chart combo, catmullRom interpolation, rolling-window calculation, conditional UI sections]

key-files:
  created:
    - ClaudeMon/Services/BurnRateCalculator.swift
    - ClaudeMon/Views/Charts/UsageChartView.swift
    - ClaudeMon/Views/Charts/BurnRateView.swift
  modified:
    - ClaudeMon/Views/MenuBar/PopoverContentView.swift

key-decisions:
  - "Removed #Preview macros from chart views (incompatible with SPM builds, per 03-03 precedent)"
  - "Conditional chart display gated on hasPercentage (JSONL fallback lacks meaningful percentage data)"

patterns-established:
  - "Chart views in Views/Charts/ directory with dedicated folder structure"
  - "Conditional UI sections using monitor.currentUsage.hasPercentage for OAuth-only features"

# Metrics
duration: 2min
completed: 2026-02-13
---

# Phase 3 Plan 2: Usage Trend Visualization Summary

**Swift Charts area/line visualization with burn rate calculator and time-to-limit projection integrated into popover**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-13T06:07:33Z
- **Completed:** 2026-02-13T06:09:41Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments
- BurnRateCalculator with 2-hour rolling window for stable usage pace estimates and time-to-limit projection
- UsageChartView using Swift Charts with area+line combo, 24h/7d segmented picker, and empty state
- BurnRateView showing color-coded burn rate and urgency-colored time-to-limit estimate
- Popover integration that conditionally shows trends only when OAuth percentage data is available

## Task Commits

Each task was committed atomically:

1. **Task 1: Create BurnRateCalculator** - `1fef9ba` (feat)
2. **Task 2: Create UsageChartView with Swift Charts** - `22d17c4` (feat)
3. **Task 3: Create BurnRateView and integrate into popover** - `1ea7d9d` (feat)

## Files Created/Modified
- `ClaudeMon/Services/BurnRateCalculator.swift` - Burn rate calculation with rolling window, time-to-limit projection, formatting, and level classification
- `ClaudeMon/Views/Charts/UsageChartView.swift` - Swift Charts area+line visualization with 24h/7d toggle and empty state
- `ClaudeMon/Views/Charts/BurnRateView.swift` - Burn rate display with flame icon and time-to-limit with clock icon
- `ClaudeMon/Views/MenuBar/PopoverContentView.swift` - Added UsageChartView and BurnRateView sections after usage detail

## Decisions Made
- Removed #Preview macros from all new views since SPM builds without Xcode don't support the Preview macro (consistent with 03-03 precedent)
- Chart and burn rate views conditionally displayed only when `hasPercentage` is true, since JSONL fallback data lacks meaningful percentage values for charting

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All Phase 3 plans complete (03-01 history, 03-02 visualization, 03-03 admin API)
- Chart visualization consumes usageHistory from UsageMonitor established in 03-01
- Ready for Phase 4 design polish to refine chart colors, spacing, and typography

## Self-Check: PASSED

All 4 created/modified files verified on disk. All 3 task commits verified in git history.

---
*Phase: 03-usage-trends-api*
*Completed: 2026-02-13*
