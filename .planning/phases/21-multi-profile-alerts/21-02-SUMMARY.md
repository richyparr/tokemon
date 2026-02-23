---
phase: 21-multi-profile-alerts
plan: 02
subsystem: tokemon-raycast
tags: [alerts, threshold, settings, menu-bar, background-refresh, LocalStorage, raycast, typescript]
dependency_graph:
  requires:
    - phase: 21-01
      provides: AlertSettings type, ALERT_SETTINGS_KEY, DEFAULT_ALERT_SETTINGS constants
  provides:
    - settings command (Form UI for threshold + enable toggle + test alert)
    - background alert logic in menu-bar (deduplicated by window ID)
  affects: [menu-bar.tsx, settings.tsx]
tech_stack:
  added: []
  patterns:
    - split-loader-form pattern (outer state loader + inner form component for stable useForm initialValues)
    - LaunchType.Background guard for menu bar alert logic
    - lastAlertedWindowId deduplication (update LocalStorage first to prevent race conditions)
key_files:
  created:
    - tokemon-raycast/src/settings.tsx
  modified:
    - tokemon-raycast/src/menu-bar.tsx
    - tokemon-raycast/package.json
key_decisions:
  - Split SettingsCommand into outer loader + inner AlertSettingsForm to avoid enableReinitialize (not supported in this @raycast/utils version)
  - lastAlertedWindowId updated in LocalStorage BEFORE showing toast to prevent race on rapid refreshes
  - LaunchType.Background guard ensures alerts only fire during scheduled 5-min background refreshes, not user-opens
  - Test Alert action uses Toast.Style.Failure to match the real alert appearance
patterns_established:
  - "split-loader-form: outer useEffect loads async state, inner component receives stable initialValues for useForm"
  - "alert-dedup: write dedup key to storage before side-effectful notification"
metrics:
  duration: ~5 min (Task 1 complete; Task 2 pending human verify)
  completed: 2026-02-23
  tasks_completed: 1
  files_modified: 3
---

# Phase 21 Plan 02: Threshold Alerts Summary

**Settings Form command + background threshold alert with window-deduplication: users configure a % threshold, menu bar fires a toast once per 5h session window when usage crosses it.**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-02-23T03:58:24Z
- **Completed:** 2026-02-23 (Task 1 done; Task 2 pending human verify)
- **Tasks:** 1/2 complete (Task 2 is human-verify checkpoint)
- **Files modified:** 3

## Accomplishments

- Created settings.tsx: Form command with threshold validation (1-100), enable checkbox, save to LocalStorage, and Test Alert action
- Updated menu-bar.tsx: background-only alert logic reading settings from LocalStorage, deduplicating by resets_at window ID
- Added "settings" command entry to package.json
- Build passes (5 entry points), 30/30 tests pass

## Task Commits

Each task was committed atomically:

1. **Task 1: Create settings command and add alert logic to menu bar** - `26e5484` (feat) — in tokemon-raycast repo

**Plan metadata:** pending (after human verify)

## Files Created/Modified

- `tokemon-raycast/src/settings.tsx` - Settings Form command: threshold text field, enable checkbox, save action, test alert action
- `tokemon-raycast/src/menu-bar.tsx` - Added LocalStorage/showToast/environment imports, parseAlertSettings helper, useEffect alert check with LaunchType.Background guard
- `tokemon-raycast/package.json` - Added "settings" command entry

## Decisions Made

- Split SettingsCommand into loader wrapper + inner AlertSettingsForm: `@raycast/utils` `useForm` does not support `enableReinitialize` — mounting the inner form only after settings load gives stable initialValues without that option
- `lastAlertedWindowId` written to LocalStorage before `showToast` to prevent a second background refresh from firing a duplicate if the first toast is still pending
- `LaunchType.Background` guard: alerts must not fire when user opens the menu bar manually (only on the automated 5-min interval)
- Test Alert uses `Toast.Style.Failure` (red) — matches the real alert's appearance so users know exactly what to expect

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed unsupported `enableReinitialize` from useForm call**
- **Found during:** Task 1 (settings.tsx creation)
- **Issue:** `@raycast/utils` `useForm` in installed version does not accept `enableReinitialize` — TypeScript error TS2353 caused build failure
- **Fix:** Split component into outer `SettingsCommand` (manages loading state + LocalStorage) and inner `AlertSettingsForm` (receives stable initialValues, mounts only after load). Same UX result with no API violation.
- **Files modified:** tokemon-raycast/src/settings.tsx
- **Verification:** `npm run build` succeeded with 5 entry points, no TypeScript errors
- **Committed in:** 26e5484 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - bug/incompatible API)
**Impact on plan:** Fix required for build success. UX and behavior identical to plan spec. No scope creep.

## Issues Encountered

None beyond the auto-fixed `enableReinitialize` TypeScript error.

## Next Phase Readiness

- Task 2 (human-verify checkpoint) remaining: user must verify profiles add/switch/delete, settings save, test alert, background alert
- After human approval, STATE.md should be updated to Phase 21 complete / advance to Phase 22 (Security Hardening)

## Self-Check: PASSED

Files exist:
- FOUND: tokemon-raycast/src/settings.tsx
- FOUND: tokemon-raycast/src/menu-bar.tsx
- FOUND: tokemon-raycast/package.json

Commits exist (tokemon-raycast repo):
- FOUND: 26e5484 (Task 1 — feat(21-02): add settings command and background alert logic)

---
*Phase: 21-multi-profile-alerts*
*Completed: 2026-02-23*
