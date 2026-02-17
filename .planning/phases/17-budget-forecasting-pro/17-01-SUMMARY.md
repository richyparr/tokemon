---
phase: 17-budget-forecasting-pro
plan: 01
subsystem: api
tags: [budget, forecasting, cost-tracking, admin-api, notifications]

# Dependency graph
requires:
  - phase: 08-analytics-export
    provides: "AdminAPIClient cost report endpoints and AdminCostResponse model"
  - phase: 06-licensing-foundation
    provides: "FeatureAccessManager and ProFeature enum for gating"
provides:
  - "BudgetConfig model with UserDefaults persistence"
  - "BudgetManager service with cost fetching and threshold alerts"
  - "ForecastingEngine with pace indicator and time-to-limit prediction"
  - "AdminAPIClient.fetchCostByWorkspace for project cost attribution"
  - "ProFeature.budgetTracking and .usageForecasting cases"
affects: [17-02-budget-ui, budget-settings, forecasting-views]

# Tech tracking
tech-stack:
  added: []
  patterns: [stateless-engine, observable-manager, workspace-cost-grouping]

key-files:
  created:
    - Tokemon/Models/BudgetConfig.swift
    - Tokemon/Services/BudgetManager.swift
    - Tokemon/Services/ForecastingEngine.swift
  modified:
    - Tokemon/Models/AdminUsageResponse.swift
    - Tokemon/Services/AdminAPIClient.swift
    - Tokemon/Services/FeatureAccessManager.swift
    - Tokemon/Utilities/Constants.swift

key-decisions:
  - "ForecastingEngine uses static methods following BurnRateCalculator pattern"
  - "BudgetManager follows AlertManager notification pattern with once-per-threshold tracking"
  - "CostResult uses init(from:) decoder for backward-compatible optional workspaceId"

patterns-established:
  - "Stateless engine pattern: ForecastingEngine with all static methods for testability"
  - "Budget threshold notifications: once-per-level with month rollover reset"

# Metrics
duration: 3min
completed: 2026-02-17
---

# Phase 17 Plan 01: Budget & Forecasting Data Layer Summary

**BudgetConfig model, BudgetManager service with threshold alerts, ForecastingEngine with pace/time-to-limit prediction, and Admin API workspace cost extension**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-17T14:59:50Z
- **Completed:** 2026-02-17T15:02:48Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- BudgetConfig model with monthly limit, alert thresholds, and UserDefaults persistence
- BudgetManager service with Admin API cost fetching, threshold alerts, and per-workspace cost attribution
- ForecastingEngine with pace indicator, daily spend rate, predicted monthly spend, and time-to-limit calculations
- AdminAPIClient extended with fetchCostByWorkspace using group_by=workspace query parameter
- ProFeature enum extended with budgetTracking and usageForecasting cases

## Task Commits

Each task was committed atomically:

1. **Task 1: BudgetConfig model, Constants key, and ProFeature cases** - `398c6ef` (feat)
2. **Task 2: BudgetManager, ForecastingEngine, and AdminAPIClient cost-by-workspace** - `64006a3` (feat)

## Files Created/Modified
- `Tokemon/Models/BudgetConfig.swift` - Budget configuration with monthly limit, thresholds, save/load via UserDefaults
- `Tokemon/Services/BudgetManager.swift` - Observable manager for cost fetching, threshold alerts, budget utilization
- `Tokemon/Services/ForecastingEngine.swift` - Stateless engine with pace indicator, daily rate, time-to-limit prediction
- `Tokemon/Models/AdminUsageResponse.swift` - Added optional workspaceId to CostResult with CodingKeys
- `Tokemon/Services/AdminAPIClient.swift` - Added fetchCostByWorkspace with group_by=workspace and pagination
- `Tokemon/Services/FeatureAccessManager.swift` - Added budgetTracking and usageForecasting ProFeature cases
- `Tokemon/Utilities/Constants.swift` - Added budgetConfigKey for UserDefaults storage

## Decisions Made
- ForecastingEngine uses static methods following BurnRateCalculator pattern (stateless, testable)
- BudgetManager follows AlertManager notification pattern with once-per-threshold tracking and month rollover reset
- CostResult uses explicit init(from:) decoder for backward-compatible optional workspaceId (existing API responses without workspace_id field still decode correctly)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Data layer complete for Plan 02 (UI layer) consumption
- BudgetManager can be instantiated and wired into settings/views
- ForecastingEngine static methods ready for view layer calculations
- No blockers for Plan 02

---
*Phase: 17-budget-forecasting-pro*
*Completed: 2026-02-17*
