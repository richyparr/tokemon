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
  affects: [menu-bar.tsx, settings.tsx, useTokenSource.ts]
tech_stack:
  added: [showHUD (alert delivery)]
  patterns:
    - split-loader-form pattern (outer state loader + inner form component for stable useForm initialValues)
    - LaunchType.Background guard for menu bar alert logic
    - lastAlertedWindowId deduplication (update LocalStorage first to prevent race conditions)
    - onData callback for side-effects (replaces useEffect)
    - useMemo for stable TokenSource identity
key_files:
  created:
    - tokemon-raycast/src/settings.tsx
  modified:
    - tokemon-raycast/src/menu-bar.tsx
    - tokemon-raycast/src/useTokenSource.ts
    - tokemon-raycast/package.json
key_decisions:
  - Split SettingsCommand into outer loader + inner AlertSettingsForm to avoid enableReinitialize (not supported in this @raycast/utils version)
  - lastAlertedWindowId updated in LocalStorage BEFORE showing HUD to prevent race on rapid refreshes
  - LaunchType.Background guard ensures alerts only fire during scheduled 5-min background refreshes, not user-opens
  - Refactored alert from useEffect to onData callback for reliability (avoids stale closure)
  - Switched from showToast to showHUD for better background alert visibility
  - Memoized TokenSource in useTokenSource to prevent useCachedPromise re-triggering on render
patterns_established:
  - "split-loader-form: outer useEffect loads async state, inner component receives stable initialValues for useForm"
  - "alert-dedup: write dedup key to storage before side-effectful notification"
  - "onData-callback: side effects on fetch success via onData, not useEffect on data"
metrics:
  duration: ~7 min (across sessions)
  completed: 2026-02-24
  tasks_completed: 2
  files_modified: 4
---

# Phase 21 Plan 02: Threshold Alerts Summary

**Settings Form command + background threshold alert with window-deduplication: users configure a % threshold, menu bar fires a HUD once per 5h session window when usage crosses it.**

## Performance

- **Duration:** ~7 min (across 2 sessions)
- **Started:** 2026-02-23
- **Completed:** 2026-02-24 (human verify approved)
- **Tasks:** 2/2 complete
- **Files modified:** 4

## Accomplishments

- Created settings.tsx: Form command with threshold validation (1-100), enable checkbox, save to LocalStorage, and Test Alert action
- Updated menu-bar.tsx: background-only alert logic via onData callback, deduplicating by resets_at window ID, using showHUD
- Stabilized useTokenSource.ts: memoized TokenSource to prevent useCachedPromise re-triggering
- Added "settings" command entry to package.json
- Build passes, 48/48 tests pass

## Task Commits

1. **Task 1: Create settings command and add alert logic to menu bar** - `26e5484` (feat) — in tokemon-raycast repo
2. **Fix: Stabilize token resolution and alert delivery** - `5b2d096` (fix) — memoized TokenSource, refactored alert to onData + showHUD
3. **Task 2: Human-verify checkpoint** - Approved 2026-02-24 (menu bar, profiles, settings, alerts all working)

## Files Created/Modified

- `tokemon-raycast/src/settings.tsx` - Settings Form command: threshold text field, enable checkbox, save action, test alert action
- `tokemon-raycast/src/menu-bar.tsx` - checkAlert as standalone function, onData callback, showHUD, LaunchType.Background guard
- `tokemon-raycast/src/useTokenSource.ts` - useMemo for stable TokenSource identity, loading state handled in derivation
- `tokemon-raycast/package.json` - Added "settings" command entry

## Decisions Made

- Split SettingsCommand into loader wrapper + inner AlertSettingsForm: `@raycast/utils` `useForm` does not support `enableReinitialize` — mounting the inner form only after settings load gives stable initialValues
- `lastAlertedWindowId` written to LocalStorage before `showHUD` to prevent race on rapid refreshes
- `LaunchType.Background` guard: alerts only fire on automated 5-min interval, not user-opens
- Switched from `showToast` to `showHUD`: more visible during background refresh
- Moved alert from `useEffect` to `onData` callback: avoids stale closure issues, more reliable
- Memoized TokenSource with `useMemo`: prevents `useCachedPromise` from re-triggering on every render

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed unsupported `enableReinitialize` from useForm call**
- Split component into outer loader + inner form. Same UX, no API violation.

**2. [Rule 1 - Improvement] Alert delivery changed from showToast to showHUD**
- showHUD more visible during background refresh; showToast requires foreground window

**3. [Rule 1 - Improvement] Alert checking moved from useEffect to onData callback**
- Avoids stale closure on `data`, fires exactly once per successful fetch

**4. [Rule 1 - Bug] TokenSource memoization in useTokenSource**
- New object identity on every render caused useCachedPromise to re-trigger continuously

**Total deviations:** 4 auto-fixed | **Impact:** All improvements, no scope creep

## Human Verification: APPROVED

Verified 2026-02-24:
- Menu bar shows usage percentage (was behind firewall earlier — network issue, not code)
- Profiles add/switch/delete working
- Settings save and threshold configuration working
- Alert delivery working

## Self-Check: PASSED

Files exist:
- FOUND: tokemon-raycast/src/settings.tsx
- FOUND: tokemon-raycast/src/menu-bar.tsx (checkAlert, showHUD, LaunchType.Background)
- FOUND: tokemon-raycast/src/useTokenSource.ts (useMemo)
- FOUND: tokemon-raycast/package.json (settings command entry)

Commits exist:
- FOUND: 26e5484 (Task 1)
- FOUND: 5b2d096 (fix — token resolution + alert refactor)

---
*Phase: 21-multi-profile-alerts*
*Completed: 2026-02-24*
