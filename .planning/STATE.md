# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-11)

**Core value:** Know your Claude usage at a glance before hitting limits.
**Current focus:** Phase 5 - Theming Polish

## Current Position

Phase: 5 of 5 (Theming Polish)
Plan: 1 of 2 in current phase
Status: Executing Phase 5
Last activity: 2026-02-14 -- Completed 05-01 Theme Infrastructure

Progress: [#########.] 90%

## Performance Metrics

**Velocity:**
- Total plans completed: 11
- Average duration: 4min
- Total execution time: 0.77 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-foundation | 2 | 17min | 9min |
| 02-alerts-notifications | 2 | 18min | 9min |
| 03-usage-trends-api | 3 | 7min | 2min |
| 04-floating-window | 2 | 2min | 1min |
| 05-theming-polish | 1 | 1min | 1min |

**Recent Trend:**
- Last 5 plans: 2min, 3min, 2min, 1min, 1min
- Trend: Fast

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Roadmap]: OAuth endpoint is primary data source, JSONL is fallback (not the other way around per research correction)
- [Roadmap]: WidgetKit widget deferred to v2 (refresh budget too limiting for real-time monitoring)
- [Roadmap]: Non-sandboxed distribution via GitHub (required for ~/.claude access)
- [Roadmap]: Design polish phase last (per user preference, after all features built)
- [01-01]: SPM executable target instead of .xcodeproj (Xcode not installed; swift build works)
- [01-01]: StatusItemManager callback pattern to solve menu bar label not updating
- [01-01]: DataSourceState.failed uses String (not Error) for Sendable conformance
- [01-02]: Token expiry check with 10-minute proactive buffer to avoid mid-request expiration
- [01-02]: Keychain write-back on token refresh with logged warning about potential Claude Code conflict
- [01-02]: JSONL primaryPercentage sentinel value of -1 to distinguish no-percentage from 0%
- [01-02]: 5-hour JSONL window to match OAuth five_hour utilization window
- [02-01]: Notification sending stubbed for Plan 02 (separation of concerns)
- [02-01]: Window reset detection via resetsAt timestamp comparison
- [02-01]: AlertLevel as Comparable via Int rawValue for threshold crossing logic
- [02-02]: Guard UNUserNotificationCenter with bundle check (SPM executables lack bundle)
- [02-02]: Stored properties with didSet for UserDefaults sync (@Observable needs stored props)
- [02-02]: @State for launchAtLogin toggle (SMAppService reads don't trigger view updates)
- [02-02]: Simplified notification permission - fire and forget (avoid MainActor callback issues)
- [03-01]: Actor isolation for HistoryStore (Swift concurrency native, no DispatchQueue needed)
- [03-01]: Synchronous throws for HistoryStore methods (file I/O is sync; actor provides concurrency safety)
- [03-01]: 30-day automatic trim on every append to prevent unbounded JSON growth
- [03-03]: Separate Keychain service (com.claudemon.admin-api) from OAuth credentials to avoid conflicts
- [03-03]: nonisolated hasAdminKey() for quick synchronous checks without actor isolation
- [03-03]: Removed #Preview macro from plan code (incompatible with SPM builds without Xcode)
- [03-02]: Conditional chart display gated on hasPercentage (JSONL fallback lacks meaningful percentage data)
- [03-02]: Removed #Preview macros from chart views (consistent with 03-03 SPM precedent)
- [04-01]: FloatingPanel uses .nonactivatingPanel styleMask to avoid stealing focus from user's work
- [04-01]: hidesOnDeactivate=false ensures panel stays visible when app loses focus
- [04-01]: setFrameAutosaveName for automatic position persistence via UserDefaults
- [04-01]: canJoinAllSpaces+fullScreenAuxiliary for visibility across all Spaces and fullscreen apps
- [05-01]: ThemeColors struct for semantic color resolution instead of direct Color usage
- [05-01]: colorSchemeOverride property for themes that enforce appearance (minimalDark always dark)
- [05-01]: UserDefaults key "selectedTheme" for theme persistence

### Pending Todos

None yet.

### Blockers/Concerns

- JSONL format is undocumented and has changed between Claude Code versions; defensive parsing required from Phase 1
- Admin API requires org admin keys; most individual Pro/Max users cannot obtain these (DATA-05 is optional enhancement)

## Session Continuity

Last session: 2026-02-14
Stopped at: Completed 05-01-PLAN.md (Theme Infrastructure)
Resume file: None
