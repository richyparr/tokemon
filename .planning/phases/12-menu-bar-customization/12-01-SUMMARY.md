---
phase: 12-menu-bar-customization
plan: 01
subsystem: ui
tags: [nsimage, nsstatus-item, menu-bar, icon-rendering, nsattributedstring, swift]

# Dependency graph
requires:
  - phase: 05-theming-polish
    provides: GradientColors usage-level color mapping
provides:
  - MenuBarIconStyle enum with 5 display styles
  - MenuBarIconRenderer service producing NSImage or NSAttributedString per style
  - GradientColors.nsColor(for:isMonochrome:) centralized monochrome helper
  - StatusItemManager using renderer with settings-change re-rendering
affects: [12-02-PLAN, appearance-settings, floating-window]

# Tech tracking
tech-stack:
  added: []
  patterns: [renderer-pattern-for-menu-bar, notification-based-settings-sync]

key-files:
  created:
    - Tokemon/Models/MenuBarIconStyle.swift
    - Tokemon/Services/MenuBarIconRenderer.swift
  modified:
    - Tokemon/Utilities/GradientColors.swift
    - Tokemon/TokemonApp.swift

key-decisions:
  - "Renderer returns (image, title) tuple -- exactly one non-nil, letting StatusItemManager decide button layout"
  - "Battery and progressBar draw custom NSImage at 18x18pt; iconAndBar uses NSTextAttachment for SF Symbol bolt.fill"
  - "Monochrome logic centralized in GradientColors.nsColor(for:isMonochrome:) to avoid duplication"
  - "NotificationCenter-based style change sync (MenuBarStyleChanged) for immediate re-render without app restart"
  - "Error/critical states on image styles use imageLeft positioning with '!' text suffix"

patterns-established:
  - "Renderer pattern: static render method returning polymorphic output tuple for menu bar display"
  - "Settings sync: post MenuBarStyleChanged notification when user changes style, StatusItemManager observes and re-renders"

# Metrics
duration: 2min
completed: 2026-02-17
---

# Phase 12 Plan 01: Icon Rendering Engine Summary

**5-style menu bar icon renderer with battery, progress bar, SF Symbol, compact, and percentage modes plus monochrome support**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-17T07:59:24Z
- **Completed:** 2026-02-17T08:01:49Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Created MenuBarIconStyle enum with 5 cases: percentage, battery, progressBar, iconAndBar, compact
- Built MenuBarIconRenderer that renders each style as either NSImage (visual) or NSAttributedString (text)
- Wired renderer into StatusItemManager with UserDefaults-backed style/monochrome preferences
- Added settings change notification for immediate re-render when user changes icon style
- Maintained backward compatibility -- default percentage style matches previous behavior exactly

## Task Commits

Each task was committed atomically:

1. **Task 1: MenuBarIconStyle model and MenuBarIconRenderer service** - `b0697cc` (feat)
2. **Task 2: Wire renderer into StatusItemManager** - `48f6e02` (feat)

## Files Created/Modified
- `Tokemon/Models/MenuBarIconStyle.swift` - Enum with 5 icon style cases, displayName, systemImage properties
- `Tokemon/Services/MenuBarIconRenderer.swift` - Static render method producing image or attributed string per style
- `Tokemon/Utilities/GradientColors.swift` - Added nsColor(for:isMonochrome:) monochrome-aware helper
- `Tokemon/TokemonApp.swift` - StatusItemManager rewritten to use renderer, stores last params, observes style changes

## Decisions Made
- Renderer returns (image, title) tuple with exactly one non-nil value, keeping button layout logic in StatusItemManager
- Battery icon draws 13x9pt body with 2pt terminal nub, 1.5pt inset fill, in an 18x18pt NSImage
- Progress bar draws 14x4pt track with 2pt corner radius centered in 18x18pt NSImage
- iconAndBar uses NSTextAttachment with bolt.fill SF Symbol at 10pt + percentage text
- Error/critical states on image styles show "!" via imageLeft positioning rather than overlay dots
- Wrapped notification observer closure in `Task { @MainActor in }` to satisfy Swift 6 concurrency

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed MainActor isolation warning in notification observer**
- **Found during:** Task 2 (Wire renderer into StatusItemManager)
- **Issue:** NotificationCenter.addObserver closure was calling @MainActor-isolated methods from a non-isolated context, producing 6 Swift concurrency warnings
- **Fix:** Wrapped observer closure body in `Task { @MainActor in }` block
- **Files modified:** Tokemon/TokemonApp.swift
- **Verification:** Clean build with zero warnings
- **Committed in:** 48f6e02 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug fix)
**Impact on plan:** Essential for clean compilation under Swift 6 strict concurrency. No scope creep.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Icon rendering engine complete and wired into menu bar display
- Plan 12-02 can now build the settings UI picker for icon style selection
- MenuBarStyleChanged notification ready for settings view to post when user picks a new style
- All 5 styles compile and render; visual verification will happen when settings picker is added

## Self-Check: PASSED

All 5 files verified present. Both task commits (b0697cc, 48f6e02) verified in git log.

---
*Phase: 12-menu-bar-customization*
*Completed: 2026-02-17*
