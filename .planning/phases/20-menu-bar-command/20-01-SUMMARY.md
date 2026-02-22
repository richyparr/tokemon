---
phase: 20-menu-bar-command
plan: 01
subsystem: ui
tags: [typescript, react, raycast, menubar, background-refresh]

# Dependency graph
requires:
  - phase: 19-dashboard-command
    provides: "types.ts, utils.ts, api.ts — all business logic"
provides:
  - "MenuBarExtra command with colored icon, percentage title, and dropdown"
  - "Background refresh via interval: 5m in package.json manifest"
  - "Icon tintColor mapped from usageColor() thresholds (green/yellow/orange/red)"
  - "Dropdown with session/weekly details, Open Dashboard action, Preferences action"
  - "No-token guard with warning icon and setup prompt"
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns: ["MenuBarExtra with useCachedPromise for menu bar commands", "interval manifest property for Raycast-native background refresh", "Icon.CircleFilled tintColor for color-coded status", "launchCommand for cross-command navigation"]

key-files:
  created:
    - "tokemon-raycast/src/menu-bar.tsx"
  modified:
    - "tokemon-raycast/package.json"

key-decisions:
  - "colorMap duplicated in menu-bar.tsx (not shared with index.tsx) — keeps commands self-contained"
  - "Icon.CircleFilled with tintColor is the only color mechanism — title text color is not programmable (macOS controls it, open Raycast issue #12610)"
  - "interval: 5m chosen for background refresh — safe for Store submission, appropriate for API polling"
  - "isLoading passed directly from useCachedPromise — NEVER manually managed (critical for background refresh lifecycle)"
  - "No-token state returns MenuBarExtra with Icon.Warning (not null) — returning null hides the item entirely"
  - "Error state dims icon to Color.SecondaryText — visual indicator without crashing"

patterns-established:
  - "MenuBarExtra + useCachedPromise + interval for persistent menu bar items"
  - "Cross-command navigation via launchCommand({ name, type: LaunchType.UserInitiated })"

# Metrics
duration: 6min
completed: 2026-02-22
---

# Phase 20 Plan 01: Menu Bar Command Summary

**Raycast menu bar command with colored icon, percentage display, 5m auto-refresh — human-verified**

## Performance

- **Duration:** ~6 min
- **Completed:** 2026-02-22
- **Tasks:** 2 (1 auto + 1 human checkpoint)
- **Files modified:** 2

## Accomplishments
- Created menu-bar.tsx — thin UI shell importing all business logic from existing modules
- MenuBarExtra with Icon.CircleFilled tintColor showing green/yellow/orange/red based on usage (MENU-03)
- Percentage title text displayed next to icon in macOS menu bar (MENU-01)
- interval: "5m" in package.json enables Raycast-native background refresh (MENU-02)
- Dropdown shows Session (5h) usage + reset countdown, Weekly (7d) usage
- "Open Dashboard" action launches index command via launchCommand
- "Preferences" action opens extension preferences
- No-token guard shows Icon.Warning with setup prompt
- Error state dims icon to SecondaryText
- Build verified: npm run build succeeds, npm test passes (30 tests)

## Task Commits

1. **Task 1: Create menu-bar.tsx and add package.json command entry** - `47d2ce4` (feat)
2. **Task 2: Human checkpoint — verified in Raycast** - User confirmed icon, color, percentage, and dropdown all working

## Files Created/Modified
- `tokemon-raycast/src/menu-bar.tsx` - MenuBarExtra command (81 lines)
- `tokemon-raycast/package.json` - Added menu-bar command entry with mode "menu-bar" and interval "5m"

## Decisions Made
- **colorMap duplicated:** Each command is self-contained — no shared module for Raycast Color mapping
- **Icon.CircleFilled + tintColor:** Only supported color mechanism for menu bar items (title text color is not programmable)
- **5-minute interval:** Conservative for Store submission, appropriate for API polling frequency
- **No-token returns MenuBarExtra with Warning:** Never return null (would hide the menu bar item)

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered
- Menu bar icon was initially hidden by macOS due to crowded menu bar — resolved by user closing some menu bar apps. This is expected macOS behavior, not a code issue.

## Human Verification

User confirmed in Raycast:
- Yellow circle icon visible in macOS menu bar (68% usage in yellow range)
- 68% text displayed next to icon
- Dropdown shows session details, weekly usage, Open Dashboard, Preferences

## Next Phase Readiness
- Phase 20 complete — all 3 MENU requirements met
- Ready for Phase 21 (Multi-Profile & Alerts)
- No blockers

---
*Phase: 20-menu-bar-command*
*Completed: 2026-02-22*

## Self-Check: PASSED

- FOUND: tokemon-raycast/src/menu-bar.tsx (81 lines, exports default MenuBarCommand)
- FOUND: commit 47d2ce4 (feat(20-01): create menu-bar command)
- VERIFIED: MENU-01 (usage percentage) - title={formatPercentage(utilization)}
- VERIFIED: MENU-02 (auto refresh) - "interval": "5m" in package.json
- VERIFIED: MENU-03 (color) - Icon.CircleFilled tintColor mapped from usageColor()
- VERIFIED: Human approved menu bar in Raycast
