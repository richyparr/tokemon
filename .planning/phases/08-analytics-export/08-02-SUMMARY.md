---
phase: 08-analytics-export
plan: 02
subsystem: ui
tags: [swift, swiftui, charts, analytics, pro-gating, settings]

# Dependency graph
requires:
  - phase: 08-01
    provides: "90-day HistoryStore retention with downsampling and per-account history queries"
  - phase: 06-03
    provides: "FeatureAccessManager, ProGatedModifier, ProBadge for Pro feature gating"
provides:
  - "AnalyticsEngine with weekly/monthly summary aggregation and project breakdown"
  - "UsageSummary and ProjectUsage data models"
  - "Analytics dashboard with extended history chart, usage summaries, and project breakdown"
  - "Analytics tab in Settings window (8 tabs total)"
  - "All analytics views Pro-gated via FeatureAccessManager"
affects: [08-03-export]

# Tech tracking
tech-stack:
  added: []
  patterns: ["Static analytics engine (pure computation, no state)", "Background JSONL parsing via Task.detached", "Pro-gated view sections with inline lock states"]

key-files:
  created:
    - "Tokemon/Services/AnalyticsEngine.swift"
    - "Tokemon/Models/UsageSummary.swift"
    - "Tokemon/Models/ProjectUsage.swift"
    - "Tokemon/Views/Analytics/AnalyticsDashboardView.swift"
    - "Tokemon/Views/Analytics/ExtendedHistoryChartView.swift"
    - "Tokemon/Views/Analytics/UsageSummaryView.swift"
    - "Tokemon/Views/Analytics/ProjectBreakdownView.swift"
  modified:
    - "Tokemon/Views/Settings/SettingsView.swift"

key-decisions:
  - "AnalyticsEngine uses all static methods (no state, pure computation) for testability"
  - "ExtendedChartTimeRange enum with requiresPro property for clean Pro gating on 30d/90d"
  - "ProjectBreakdownView runs JSONL parsing in Task.detached to avoid blocking UI"
  - "AnalyticsDashboardView gates entire view at top level (not individual sub-views)"

patterns-established:
  - "Static engine pattern: pure computation structs with static methods for analytics aggregation"
  - "Background parsing: Task.detached with MainActor.run callback for expensive file I/O in views"
  - "Inline Pro gate: views check featureAccess directly and show locked state with upgrade button"

# Metrics
duration: 3min
completed: 2026-02-15
---

# Phase 8 Plan 2: Analytics Dashboard & Engine Summary

**AnalyticsEngine with weekly/monthly summaries, extended 24h/7d/30d/90d history chart, and per-project JSONL token breakdown in Pro-gated Settings > Analytics tab**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-15T06:46:37Z
- **Completed:** 2026-02-15T06:49:38Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments
- Built AnalyticsEngine with static methods for weekly/monthly usage aggregation and project JSONL breakdown
- Created 4 analytics views: ExtendedHistoryChartView, UsageSummaryView, ProjectBreakdownView, AnalyticsDashboardView
- Added Analytics tab to SettingsView (now 8 tabs) between Accounts and License
- All analytics features Pro-gated with FeatureAccessManager checks and upgrade prompts

## Task Commits

Each task was committed atomically:

1. **Task 1: Create AnalyticsEngine, UsageSummary, and ProjectUsage** - `1358633` (feat)
2. **Task 2: Build Analytics views and add Analytics tab to Settings** - `5d405c8` (feat)

## Files Created/Modified
- `Tokemon/Services/AnalyticsEngine.swift` - Static analytics engine with weeklySummaries, monthlySummaries, projectBreakdown, decodeProjectPath, formatTokenCount
- `Tokemon/Models/UsageSummary.swift` - UsageSummary model (Identifiable, Sendable) for period aggregations
- `Tokemon/Models/ProjectUsage.swift` - ProjectUsage model (Identifiable, Sendable) for per-project token breakdown
- `Tokemon/Views/Analytics/AnalyticsDashboardView.swift` - Main analytics container with Pro-gated locked splash
- `Tokemon/Views/Analytics/ExtendedHistoryChartView.swift` - Swift Charts area+line chart with 4 time range options (24h/7d/30d/90d)
- `Tokemon/Views/Analytics/UsageSummaryView.swift` - Weekly/monthly summary table with avg/peak utilization
- `Tokemon/Views/Analytics/ProjectBreakdownView.swift` - Per-project token breakdown with background JSONL parsing
- `Tokemon/Views/Settings/SettingsView.swift` - Added Analytics tab, increased minHeight from 320 to 400

## Decisions Made
- AnalyticsEngine uses all static methods (no instance state) for easy testability and no side effects
- ExtendedChartTimeRange has a `requiresPro` property so the segmented picker can show lock icons for Pro ranges
- ProjectBreakdownView runs JSONL parsing in `Task.detached` to avoid blocking the main thread during file I/O
- AnalyticsDashboardView gates the entire view at the top level rather than gating each sub-view individually

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Analytics dashboard complete with all sub-views, ready for Plan 03 (Export) to add export buttons
- AnalyticsDashboardView has Spacer placeholder where export buttons will be added
- AnalyticsEngine.weeklySummaries/monthlySummaries available for PDF/CSV export in Plan 03
- AnalyticsEngine.projectBreakdown available for export data generation
- No blockers for Plan 03

## Self-Check: PASSED

- FOUND: Tokemon/Services/AnalyticsEngine.swift
- FOUND: Tokemon/Models/UsageSummary.swift
- FOUND: Tokemon/Models/ProjectUsage.swift
- FOUND: Tokemon/Views/Analytics/AnalyticsDashboardView.swift
- FOUND: Tokemon/Views/Analytics/ExtendedHistoryChartView.swift
- FOUND: Tokemon/Views/Analytics/UsageSummaryView.swift
- FOUND: Tokemon/Views/Analytics/ProjectBreakdownView.swift
- FOUND: Tokemon/Views/Settings/SettingsView.swift
- FOUND: 08-02-SUMMARY.md
- FOUND: commit 1358633
- FOUND: commit 5d405c8

---
*Phase: 08-analytics-export*
*Completed: 2026-02-15*
