# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-17)

**Core value:** Know your Claude usage at a glance before hitting limits.
**Current focus:** v3.0 Phase 14 -- Distribution & Trust

## Current Position

Phase: 14 of 17 (Distribution & Trust)
Plan: 4 of 4 in current phase (all plans complete)
Status: Phase Complete
Last activity: 2026-02-17 -- Completed 14-03 Sparkle Auto-Update

Progress: [████████░░░░░░░░░░░░░░░░░░] 31%

## Shipped Milestones

- **v1.0 MVP** -- 5 phases, 12 plans (shipped 2026-02-14)
- **v2.0 Pro Features** -- 5 phases, 14 plans (shipped 2026-02-15)

## Performance Metrics

**v1.0 Milestone:**
- Total plans completed: 12
- Total phases: 5
- Lines of code: 3,948 Swift
- Timeline: 3 days (Feb 11-14, 2026)

**v2.0 Milestone:**
- Total plans completed: 14
- Total phases: 5
- Lines of code: 7,706 Swift
- Timeline: 2 days (Feb 14-15, 2026)

**v3.0 Milestone:**
- Total plans completed: 11
- Total phases: 7 (Phases 11-17)
- Requirements: 33

| Phase | Plan | Duration | Tasks | Files |
|-------|------|----------|-------|-------|
| 11    | 01   | 2min     | 2     | 3     |
| 11    | 02   | 3min     | 2     | 6     |
| 11    | 03   | 2min     | 2     | 5     |
| 12    | 01   | 2min     | 2     | 4     |
| 12    | 02   | 1min     | 2     | 1     |
| 13    | 01   | 2min     | 2     | 4     |
| 13    | 02   | 3min     | 3     | 5     |
| 14    | 01   | 3min     | 2     | 3     |
| 14    | 02   | 2min     | 2     | 4     |
| 14    | 03   | 5min     | 3     | 11    |
| 14    | 04   | 2min     | 2     | 3     |

## Accumulated Context

### Decisions

See PROJECT.md Key Decisions table for full list.

**v3.0 Research Insights:**
- Claude Usage Tracker (1.2k stars) uses copy/switch credential architecture
- ClaudeBar uses protocol-based multi-provider design
- Terminal statusline has 11 duplicate GitHub issues -- highest demand feature
- 85% of enterprises exceed AI budgets -- opportunity for budget tracking PRO feature

**Phase 11 Decisions:**
- Used Process + /usr/bin/security for keychain I/O (not KeychainAccess) to avoid permission issues with Claude Code's keychain entry
- UserDefaults for profile persistence (lightweight, appropriate for small profile metadata)
- Profile stores full JSON blob from system keychain rather than parsing individual fields
- Profiles tab placed as FIRST tab in Settings for prominence
- ProfileSwitcherView uses Menu dropdown matching popover footer style
- SettingsWindowController gets setProfileManager following existing setter pattern
- usageColor threshold at 80% for compact profile summary (matching GradientColors orange range)
- Multi-profile polling sequential after main refresh (not concurrent with active profile update)
- saveProfiles() on every usage update for persistence (UserDefaults writes are fast)

**Phase 12 Decisions:**
- Renderer returns (image, title) tuple with exactly one non-nil -- StatusItemManager decides button layout
- Battery/progressBar render custom NSImage at 18x18pt; iconAndBar uses NSTextAttachment for SF Symbol
- Monochrome logic centralized in GradientColors.nsColor(for:isMonochrome:) to avoid duplication
- NotificationCenter-based style change sync for immediate re-render without app restart
- Error/critical states on image styles use imageLeft positioning with "!" text suffix
- Radio group picker iterates MenuBarIconStyle.allCases with displayName labels and rawValue tags
- Style descriptions as dynamic caption text below picker, updating based on selection
- Monochrome toggle in own "Color Mode" section for visual clarity

**Phase 14 Decisions:**
- SKIP_SIGNING env var for testing build-release.sh bundle structure without Developer ID certificate
- Entitlements file used during codesign for hardened runtime compatibility with keychain access
- DMG re-signed and re-stapled after app stapling for complete notarization chain
- softprops/action-gh-release@v2 with auto release notes generation
- Called checkForSessionReset from within checkUsage (Option 2) to keep wiring simpler -- avoids adding another callback to UsageMonitor
- Session notification uses timeSensitive interruption level (not critical) since it is informational
- Used cask format (not formula) since Tokemon is a macOS .app distributed as DMG
- Added depends_on macos >= :sonoma matching Info.plist LSMinimumSystemVersion 14.0
- SHA256 computed once in release CI and forwarded via repository_dispatch client-payload to tap
- Local let extraction for SUAppcastItem.displayVersionString to avoid Swift 6 sending data race
- Named settings tab "Updates" (not "General") to avoid conflicting with existing RefreshSettings tab
- Appcast URL set to tokemon.app/appcast.xml for future GitHub Pages hosting

### Pending Todos

None.

### Blockers/Concerns

None.

## Session Continuity

Last session: 2026-02-17
Stopped at: Completed 14-03 Sparkle Auto-Update (Phase 14 complete)
Resume: Begin Phase 15
