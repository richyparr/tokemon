---
phase: 14-distribution-trust
plan: 03
subsystem: infra
tags: [sparkle, auto-update, appcast, macOS, SPM]

# Dependency graph
requires:
  - phase: 14-01
    provides: "Code signing and release infrastructure (build-release.sh, notarize.sh, release.yml)"
provides:
  - "UpdateManager service wrapping Sparkle SPUStandardUpdaterController"
  - "Update available banner in popover"
  - "Updates settings tab with auto-check toggle"
  - "Appcast generation script for release pipeline"
affects: [14-distribution-trust, release-pipeline]

# Tech tracking
tech-stack:
  added: [Sparkle 2.x]
  patterns: [SPUUpdaterDelegate for update lifecycle, @Observable UpdateManager for UI binding]

key-files:
  created:
    - Tokemon/Services/UpdateManager.swift
    - Tokemon/Views/MenuBar/UpdateBannerView.swift
    - Tokemon/Views/Settings/GeneralSettings.swift
    - scripts/generate-appcast.sh
  modified:
    - Package.swift
    - Tokemon/Utilities/Constants.swift
    - Tokemon/TokemonApp.swift
    - Tokemon/Views/MenuBar/PopoverContentView.swift
    - Tokemon/Views/Settings/SettingsView.swift
    - Tokemon/Services/SettingsWindowController.swift
    - .github/workflows/release.yml

key-decisions:
  - "Used @preconcurrency-free SPUUpdaterDelegate conformance with local let extraction for Swift 6 concurrency safety"
  - "Named the settings tab 'Updates' instead of 'General' to avoid conflicting with existing General (RefreshSettings) tab"
  - "Appcast URL set to tokemon.app/appcast.xml for future GitHub Pages hosting"

patterns-established:
  - "UpdateManager follows existing setter pattern on SettingsWindowController (setUpdateManager)"
  - "Update banner height tracked in popoverHeight like trial banner height"

# Metrics
duration: 5min
completed: 2026-02-17
---

# Phase 14 Plan 03: Sparkle Auto-Update Integration Summary

**Sparkle 2.x integration with UpdateManager service, popover update banner, and appcast generation for release pipeline**

## Performance

- **Duration:** 5 min
- **Started:** 2026-02-17T09:26:49Z
- **Completed:** 2026-02-17T09:31:51Z
- **Tasks:** 3
- **Files modified:** 11

## Accomplishments
- Sparkle 2.x added as SPM dependency with UpdateManager wrapping SPUStandardUpdaterController
- Update banner displays in popover when a new version is detected via appcast
- Updates settings tab provides auto-check toggle, manual check button, and version info
- Appcast generation script integrated into GitHub Actions release pipeline

## Task Commits

Each task was committed atomically:

1. **Task 1: Add Sparkle dependency and create UpdateManager** - `3eaea8f` (feat)
2. **Task 2: Create update banner and Settings UI** - `7aa4bf1` (feat)
3. **Task 3: Integrate update banner into popover and add appcast generation** - `a576ac9` (feat)

## Files Created/Modified
- `Tokemon/Services/UpdateManager.swift` - Sparkle wrapper with @Observable state for update availability
- `Tokemon/Views/MenuBar/UpdateBannerView.swift` - Popover banner showing when update is available
- `Tokemon/Views/Settings/GeneralSettings.swift` - Settings tab with auto-update toggle and manual check
- `scripts/generate-appcast.sh` - Generates Sparkle appcast.xml from DMG release artifacts
- `Package.swift` - Added Sparkle 2.x dependency
- `Tokemon/Utilities/Constants.swift` - Added sparkle appcast URL and auto-check key
- `Tokemon/TokemonApp.swift` - Wired UpdateManager to environment and popover height
- `Tokemon/Views/MenuBar/PopoverContentView.swift` - Added UpdateBannerView to popover
- `Tokemon/Views/Settings/SettingsView.swift` - Added Updates tab
- `Tokemon/Services/SettingsWindowController.swift` - Added setUpdateManager for settings window
- `.github/workflows/release.yml` - Added appcast generation and upload step

## Decisions Made
- Used local `let version = item.displayVersionString` extraction before Task { @MainActor } to avoid Swift 6 sending data race on SUAppcastItem
- Named settings tab "Updates" (not "General") since RefreshSettings already occupies the "General" tab label
- Set appcast URL to `https://tokemon.app/appcast.xml` for future GitHub Pages deployment

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed Swift 6 strict concurrency data race in SPUUpdaterDelegate**
- **Found during:** Task 1 (UpdateManager creation)
- **Issue:** `item.displayVersionString` captured across actor boundary caused "sending risks data race" error
- **Fix:** Extracted version string into local `let` before crossing into @MainActor Task; removed no-op `@preconcurrency`
- **Files modified:** Tokemon/Services/UpdateManager.swift
- **Verification:** `swift build` compiles without errors
- **Committed in:** 3eaea8f (Task 1 commit)

**2. [Rule 1 - Bug] Named tab "Updates" to avoid duplicate "General" tab**
- **Found during:** Task 2 (Settings UI)
- **Issue:** Plan specified adding "General" tab but RefreshSettings already uses that label
- **Fix:** Used "Updates" tab label with `arrow.triangle.2.circlepath.circle` icon
- **Files modified:** Tokemon/Views/Settings/SettingsView.swift
- **Verification:** No duplicate tab names in settings
- **Committed in:** 7aa4bf1 (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (2 bug fixes)
**Impact on plan:** Both fixes necessary for compilation and correct UI. No scope creep.

## Issues Encountered
None beyond the auto-fixed deviations above.

## User Setup Required
None - no external service configuration required. Appcast URL will need a hosted appcast.xml when first release is published.

## Next Phase Readiness
- Sparkle auto-update infrastructure complete
- Release pipeline generates and uploads appcast.xml alongside DMG
- Ready for remaining Phase 14 plans

## Self-Check: PASSED

All 5 created files exist on disk. All 3 task commits verified in git log.

---
*Phase: 14-distribution-trust*
*Completed: 2026-02-17*
