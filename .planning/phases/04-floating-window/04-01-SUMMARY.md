---
phase: 04-floating-window
plan: 01
subsystem: ui
tags: [nswindow, nspanel, appkit, floating-window, macos]

# Dependency graph
requires:
  - phase: 01-foundation
    provides: "UsageMonitor, AlertManager, SettingsWindowController pattern"
provides:
  - "FloatingPanel NSPanel subclass with always-on-top non-activating behavior"
  - "FloatingWindowController singleton for panel lifecycle management"
  - "NSWindow+Position extension for corner-based window placement"
affects: [04-floating-window]

# Tech tracking
tech-stack:
  added: []
  patterns: [NSPanel non-activating floating window, setFrameAutosaveName position persistence]

key-files:
  created:
    - ClaudeMon/Services/FloatingWindowController.swift
    - ClaudeMon/Utilities/NSWindow+Position.swift
  modified: []

key-decisions:
  - "FloatingPanel uses .nonactivatingPanel styleMask to avoid stealing focus from user's work"
  - "hidesOnDeactivate=false ensures panel stays visible when app loses focus"
  - "setFrameAutosaveName for automatic position persistence via UserDefaults"
  - "canJoinAllSpaces+fullScreenAuxiliary for visibility across all Spaces and fullscreen apps"

patterns-established:
  - "FloatingPanel NSPanel subclass: always configure hidesOnDeactivate, nonactivatingPanel, and isFloatingPanel together"
  - "FloatingWindowController singleton: follows same setMonitor/setAlertManager dependency injection as SettingsWindowController"
  - "NSWindow.Position: reusable enum-based corner positioning with padding"

# Metrics
duration: 1min
completed: 2026-02-14
---

# Phase 04 Plan 01: Floating Window Foundation Summary

**NSPanel floating window infrastructure with always-on-top non-activating behavior, position persistence via setFrameAutosaveName, and corner positioning utilities**

## Performance

- **Duration:** 1 min
- **Started:** 2026-02-14T05:13:20Z
- **Completed:** 2026-02-14T05:14:44Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- FloatingPanel NSPanel subclass with hidesOnDeactivate=false, nonactivatingPanel, .floating level
- FloatingWindowController singleton managing panel lifecycle with show/hide/toggle API
- NSWindow+Position extension for corner-based window placement respecting menu bar and Dock

## Task Commits

Each task was committed atomically:

1. **Task 1: Create NSWindow position extension** - `06eff87` (feat)
2. **Task 2: Create FloatingPanel and FloatingWindowController** - `6a04785` (feat)

## Files Created/Modified
- `ClaudeMon/Utilities/NSWindow+Position.swift` - NSWindow extension with Position struct (Horizontal/Vertical enums) and setPosition() for corner placement
- `ClaudeMon/Services/FloatingWindowController.swift` - FloatingPanel NSPanel subclass + FloatingWindowController singleton for lifecycle management

## Decisions Made
- FloatingPanel uses `.nonactivatingPanel` styleMask to prevent stealing focus from user's current work
- `hidesOnDeactivate = false` is the critical setting that keeps the panel visible when the app loses focus
- `setFrameAutosaveName` called before `makeKeyAndOrderFront` for automatic position persistence
- `canJoinAllSpaces` + `fullScreenAuxiliary` collection behavior for visibility across all Spaces
- `isReleasedWhenClosed = false` to keep panel in memory for reuse without recreation
- Placeholder content (Text view) will be replaced with FloatingWindowView in Plan 04-02

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- FloatingPanel and FloatingWindowController ready for Plan 04-02 to add SwiftUI content view
- FloatingWindowController.showFloatingWindow() creates panel with placeholder content
- Plan 04-02 will replace placeholder with FloatingWindowView and wire up menu bar toggle

## Self-Check: PASSED

- All 2 created files exist on disk
- Both commit hashes (06eff87, 6a04785) found in git log
- swift build completes successfully with no warnings

---
*Phase: 04-floating-window*
*Completed: 2026-02-14*
