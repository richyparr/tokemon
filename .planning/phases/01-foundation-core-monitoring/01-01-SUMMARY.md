---
phase: 01-foundation-core-monitoring
plan: 01
subsystem: ui
tags: [swiftui, menubarextra, appkit, nsstatus-item, spm, macos]

# Dependency graph
requires: []
provides:
  - Compilable SwiftUI menu bar app with MenuBarExtra and popover shell
  - Data models (UsageSnapshot, OAuthUsageResponse, DataSourceState) for all views
  - UsageMonitor @Observable service with polling infrastructure and mock data
  - GradientColors utility for subtle usage-level coloring
  - StatusItemManager for persistent NSStatusItem updates
  - Package.swift with MenuBarExtraAccess, SettingsAccess, KeychainAccess dependencies
affects: [01-02-PLAN, 01-03-PLAN]

# Tech tracking
tech-stack:
  added: [MenuBarExtraAccess 1.2.2, SettingsAccess 2.1.0, KeychainAccess 4.2.2, Swift 6.1, SwiftUI macOS 14]
  patterns: [@Observable with @MainActor for state management, StatusItemManager callback pattern for NSStatusItem sync, App Nap prevention with ProcessInfo.beginActivity]

key-files:
  created:
    - ClaudeMon/ClaudeMonApp.swift
    - ClaudeMon/Info.plist
    - ClaudeMon/Models/UsageSnapshot.swift
    - ClaudeMon/Models/OAuthUsageResponse.swift
    - ClaudeMon/Models/DataSourceState.swift
    - ClaudeMon/Services/UsageMonitor.swift
    - ClaudeMon/Utilities/Constants.swift
    - ClaudeMon/Utilities/GradientColors.swift
    - ClaudeMon/Views/MenuBar/PopoverContentView.swift
    - ClaudeMon/Views/Settings/SettingsView.swift
    - Package.swift
    - Package.resolved
    - .gitignore
  modified: []

key-decisions:
  - "SPM executable target instead of .xcodeproj (Xcode not installed; SPM provides clean dependency management and builds with swift build)"
  - "StatusItemManager callback pattern to solve menu bar label not updating (research pitfall #1)"
  - "nonisolated deinit not available in Swift 6.1 without experimental flag; removed deinit since UsageMonitor lives for app lifetime"
  - "DataSourceState uses String for error instead of Error to satisfy Sendable conformance"

patterns-established:
  - "StatusItemManager pattern: Store NSStatusItem reference, update via onUsageChanged callback from UsageMonitor"
  - "@Observable @MainActor pattern: All state management uses Observation framework with main actor isolation"
  - "Environment injection pattern: UsageMonitor passed via .environment(monitor) to all views"
  - "GradientColors.color(for:) pattern: Static function returning NSColor for usage percentage"

# Metrics
duration: 14min
completed: 2026-02-12
---

# Phase 1 Plan 01: App Foundation Summary

**SwiftUI menu bar app shell with MenuBarExtra, colored percentage display, popover content view, and UsageMonitor mock polling via SPM**

## Performance

- **Duration:** 14 min
- **Started:** 2026-02-12T11:40:45Z
- **Completed:** 2026-02-12T11:55:13Z
- **Tasks:** 2
- **Files modified:** 13

## Accomplishments
- Compilable macOS menu bar app with three SPM dependencies (MenuBarExtraAccess, SettingsAccess, KeychainAccess)
- LSUIElement background-only app (no Dock icon) with colored percentage text in menu bar
- PopoverContentView with large percentage, detail rows, and footer with refresh status
- UsageMonitor with Timer-based polling, App Nap prevention, and mock data cycling every 60s
- All data models (UsageSnapshot, OAuthUsageResponse, DataSourceState) ready for real data in Plan 02

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Xcode project with SPM dependencies and app entry point** - `7e47c7a` (feat)
2. **Task 2: Create data models, UsageMonitor service, gradient colors, and popover shell** - `58d14c2` (feat)

## Files Created/Modified
- `Package.swift` - SPM manifest with three dependencies, macOS 14+ target
- `Package.resolved` - Locked dependency versions for reproducible builds
- `.gitignore` - Excludes .build/, .swiftpm/, DerivedData, .DS_Store
- `ClaudeMon/ClaudeMonApp.swift` - @main entry point with MenuBarExtra, Settings scene, StatusItemManager
- `ClaudeMon/Info.plist` - LSUIElement=YES, bundle ID com.claudemon.app, macOS 14.0 minimum
- `ClaudeMon/Models/UsageSnapshot.swift` - Central usage state with all fields, .empty factory, menuBarText
- `ClaudeMon/Models/OAuthUsageResponse.swift` - Codable model for /api/oauth/usage with toSnapshot()
- `ClaudeMon/Models/DataSourceState.swift` - Enum: available, failed, disabled, notConfigured
- `ClaudeMon/Services/UsageMonitor.swift` - @Observable state manager with polling, App Nap prevention, mock data
- `ClaudeMon/Utilities/Constants.swift` - API URLs, Keychain service name, OAuth client ID, defaults
- `ClaudeMon/Utilities/GradientColors.swift` - Subtle 5-level color gradient (secondary label -> muted red)
- `ClaudeMon/Views/MenuBar/PopoverContentView.swift` - Main popover layout with percentage, details, footer
- `ClaudeMon/Views/Settings/SettingsView.swift` - Placeholder settings (built in Plan 03)

## Decisions Made
- **SPM over .xcodeproj:** Xcode.app is not installed on this machine. SPM provides clean builds via `swift build` and proper dependency management. An .xcodeproj can be generated later with `swift package generate-xcodeproj` or by opening Package.swift in Xcode.
- **StatusItemManager callback pattern:** The menuBarExtraAccess statusItem callback only fires once during setup. To solve the "menu bar label not updating" pitfall from research, added a dedicated StatusItemManager that stores the NSStatusItem reference and an `onUsageChanged` callback on UsageMonitor that triggers updates on every refresh cycle.
- **Removed deinit from UsageMonitor:** Swift 6.1 strict concurrency does not allow @MainActor-isolated property access from deinit. `nonisolated deinit` requires an experimental feature flag. Since UsageMonitor lives for the app lifetime, deinit cleanup is unnecessary.
- **Sendable DataSourceState:** Changed `.failed(Error)` to `.failed(String)` to satisfy Sendable conformance without existential type issues.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Created .gitignore to exclude .build/ directory**
- **Found during:** Task 1
- **Issue:** SPM .build/ directory would be committed to git without a .gitignore
- **Fix:** Created .gitignore with standard Swift/macOS exclusions
- **Files modified:** .gitignore
- **Verification:** `git status` no longer shows .build/
- **Committed in:** 7e47c7a (Task 1 commit)

**2. [Rule 1 - Bug] Fixed MenuBarExtra API call signature**
- **Found during:** Task 1
- **Issue:** Plan's code example used `MenuBarExtra(isPresented:)` which is not a valid initializer
- **Fix:** Changed to `MenuBarExtra { content } label: { label }` (standard API)
- **Files modified:** ClaudeMon/ClaudeMonApp.swift
- **Verification:** Build succeeds
- **Committed in:** 7e47c7a (Task 1 commit)

**3. [Rule 1 - Bug] Fixed .frame() signature on PopoverContentView**
- **Found during:** Task 1
- **Issue:** `.frame(width:minHeight:maxHeight:)` is not a valid overload
- **Fix:** Changed to `.frame(minWidth:maxWidth:minHeight:maxHeight:)`
- **Files modified:** ClaudeMon/Views/MenuBar/PopoverContentView.swift
- **Verification:** Build succeeds
- **Committed in:** 7e47c7a (Task 1 commit)

**4. [Rule 1 - Bug] Fixed deinit actor isolation in UsageMonitor**
- **Found during:** Task 1
- **Issue:** @MainActor class cannot access isolated properties from deinit in Swift 6
- **Fix:** Removed deinit (unnecessary for app-lifetime object)
- **Files modified:** ClaudeMon/Services/UsageMonitor.swift
- **Verification:** Build succeeds without concurrency errors
- **Committed in:** 7e47c7a (Task 1 commit)

**5. [Rule 2 - Missing Critical] Added StatusItemManager for persistent menu bar updates**
- **Found during:** Task 2
- **Issue:** Research pitfall #1 warns that MenuBarExtra label may not re-render on state changes. The menuBarExtraAccess callback fires once.
- **Fix:** Created StatusItemManager to store NSStatusItem reference and added onUsageChanged callback to UsageMonitor for persistent updates
- **Files modified:** ClaudeMon/ClaudeMonApp.swift, ClaudeMon/Services/UsageMonitor.swift
- **Verification:** Build succeeds; callback wired in menuBarExtraAccess setup
- **Committed in:** 58d14c2 (Task 2 commit)

---

**Total deviations:** 5 auto-fixed (2 bugs, 1 blocking, 1 missing critical, 1 API correction)
**Impact on plan:** All auto-fixes were necessary for compilation and correct runtime behavior. No scope creep.

## Issues Encountered
- **No Xcode.app installed:** The plan specified `xcodebuild build` for verification. Since only Command Line Tools are available, used `swift build` via SPM instead. The project builds and runs correctly. An .xcodeproj can be generated later if needed.
- **Swift 6 strict concurrency:** Required adjustments to satisfy Sendable conformance (DataSourceState error type) and actor isolation rules (deinit removal). All resolved within task scope.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- App shell complete and compiling with all three SPM dependencies
- Ready for Plan 02: OAuth client, token manager, and JSONL parser (real data fetching)
- Ready for Plan 03: Settings view, popover refinements, right-click context menu
- UsageMonitor.refresh() stub is ready to be replaced with real OAuth + JSONL fetching

## Self-Check: PASSED

- All 13 created files verified on disk
- Both task commits (7e47c7a, 58d14c2) verified in git history
- `swift build` succeeds with zero errors

---
*Phase: 01-foundation-core-monitoring*
*Completed: 2026-02-12*
