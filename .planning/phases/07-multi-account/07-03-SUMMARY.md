---
phase: 07-multi-account
plan: 03
subsystem: ui
tags: [multi-account, per-account-alerts, combined-usage, history-store, swiftui, taskgroup]

# Dependency graph
requires:
  - phase: 07-multi-account
    provides: "Account model, AccountManager service, AccountSwitcherView, account-aware OAuthClient"
  - phase: 02-alerts-notifications
    provides: "AlertManager with threshold and notification support"
provides:
  - "Per-account alert threshold and notification settings in AccountsSettings"
  - "AlertManager per-account threshold support with account-aware notifications"
  - "CombinedUsageView with parallel TaskGroup fetch across all accounts"
  - "Per-account HistoryStore with backward-compatible legacy methods"
affects: [08-analytics-export]

# Tech tracking
tech-stack:
  added: []
  patterns: [per-account-alert-thresholds, parallel-usage-fetch, per-account-history-files]

key-files:
  created:
    - Tokemon/Views/Settings/CombinedUsageView.swift
  modified:
    - Tokemon/Views/Settings/AccountsSettings.swift
    - Tokemon/Services/AlertManager.swift
    - Tokemon/Services/HistoryStore.swift
    - Tokemon/Services/UsageMonitor.swift
    - Tokemon/TokemonApp.swift

key-decisions:
  - "Per-account notification identifiers allow independent alert notifications per account"
  - "HistoryStore uses sentinel UUID for legacy single-account backward compatibility"
  - "CombinedUsageView shows highest usage as headline metric (not average)"

patterns-established:
  - "Per-account settings pattern: Binding wrapping AccountManager.updateAccountSettings"
  - "Parallel fetch pattern: withTaskGroup for concurrent per-account API calls"
  - "Per-account history pattern: separate JSON files in Tokemon/history/{uuid}.json"

# Metrics
duration: 3min
completed: 2026-02-14
---

# Phase 7 Plan 3: Per-Account Alerts & Combined Usage Summary

**Per-account alert thresholds with notifications, CombinedUsageView with parallel TaskGroup fetch, and per-account HistoryStore with backward-compatible legacy storage**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-14T13:53:43Z
- **Completed:** 2026-02-14T13:56:54Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments
- Per-account alert threshold slider (50-100%) and notification toggle in AccountsSettings
- AlertManager uses per-account thresholds with account-name-prefixed notifications
- CombinedUsageView aggregates usage across all accounts with parallel TaskGroup fetch
- HistoryStore supports per-account files while maintaining backward compatibility

## Task Commits

Each task was committed atomically:

1. **Task 1: Add per-account settings editor to AccountsSettings** - `55ba81b` (feat)
2. **Task 2: Modify AlertManager for per-account thresholds** - `cae4352` (feat)
3. **Task 3: Create CombinedUsageView and update HistoryStore for per-account** - `1f5fed9` (feat)

## Files Created/Modified
- `Tokemon/Views/Settings/CombinedUsageView.swift` - Aggregated usage view across all accounts with parallel fetch
- `Tokemon/Views/Settings/AccountsSettings.swift` - Per-account alert threshold slider, notifications toggle, CombinedUsageView integration
- `Tokemon/Services/AlertManager.swift` - Per-account threshold support, account-aware notifications
- `Tokemon/Services/HistoryStore.swift` - Per-account history files with legacy backward compatibility
- `Tokemon/Services/UsageMonitor.swift` - Per-account history recording
- `Tokemon/TokemonApp.swift` - AlertManager wired to AccountManager

## Decisions Made
- Per-account notification identifiers (tokemon.alert.{level}.{accountName}) allow independent alerts per account without deduplication conflicts
- HistoryStore uses a sentinel UUID (all zeros) for legacy single-account data to maintain backward compatibility without migration
- CombinedUsageView shows highest usage as the headline metric rather than average, since the highest is most actionable

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Multi-account phase complete with full per-account customization
- Per-account history storage ready for analytics and export features (08)
- CombinedUsageView provides the aggregated view needed for multi-account dashboard

## Self-Check: PASSED

- All 1 created file verified on disk (CombinedUsageView.swift)
- All 5 modified files verified on disk
- All 3 task commits verified in git log (55ba81b, cae4352, 1f5fed9)

---
*Phase: 07-multi-account*
*Completed: 2026-02-14*
