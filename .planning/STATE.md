# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-17)

**Core value:** Know your Claude usage at a glance before hitting limits.
**Current focus:** v3.0 shipped -- all milestones complete

## Current Position

Phase: All complete
Plan: N/A
Status: v3.0 Shipped
Last activity: 2026-02-17 -- Archived v3.0 milestone

Progress: [██████████████████████████] 100%

## Shipped Milestones

- **v1.0 MVP** -- 5 phases, 12 plans (shipped 2026-02-14)
- **v2.0 Pro Features** -- 5 phases, 14 plans (shipped 2026-02-15)
- **v3.0 Competitive Parity & Growth** -- 7 phases, 17 plans (shipped 2026-02-17)

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
- Total plans completed: 13
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
| 15    | 01   | --       | --    | --    |
| 15    | 02   | --       | --    | --    |
| 16    | 01   | 3min     | 2     | 4     |
| 16    | 02   | 2min     | 2     | 5     |
| 17    | 01   | 3min     | 2     | 7     |
| 17    | 02   | 3min     | 2     | 8     |

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

**Phase 16 Decisions:**
- Static payload methods for Sendable safety in Task.detached context (Swift 6 concurrency)
- Profile name read from UserDefaults directly (no ProfileManager dependency) for loose coupling in WebhookManager
- WebhookError enum with LocalizedError conformance for UI-friendly test webhook feedback
- Webhooks tab always visible in SettingsView -- Pro gate handled internally by WebhookSettings view
- AlertManager.onWebhookCheck fires on every check -- WebhookManager handles its own deduplication

**Phase 17 Decisions:**
- ForecastingEngine uses static methods following BurnRateCalculator pattern (stateless, testable)
- BudgetManager follows AlertManager notification pattern with once-per-threshold tracking and month rollover reset
- CostResult uses explicit init(from:) decoder for backward-compatible optional workspaceId
- Custom 270-degree arc gauge (ArcShape) instead of system Gauge for full visual control
- Rate-limited refreshIfNeeded() (5-minute interval) wired to onUsageChanged callback
- Budget tab always visible in SettingsView -- Pro gate handled internally by BudgetDashboardView

### Pending Todos

None.

### Blockers/Concerns

None.

## Session Continuity

Last session: 2026-02-17
Stopped at: Archived v3.0 milestone
Resume: All milestones shipped — ready for v4.0 planning with `/gsd:new-milestone`
