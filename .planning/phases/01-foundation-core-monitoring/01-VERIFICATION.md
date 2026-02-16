---
phase: 01-foundation-core-monitoring
verified: 2026-02-13T12:00:00Z
status: passed
score: 5/5 must-haves verified
re_verification: false
---

# Phase 1: Foundation & Core Monitoring Verification Report

**Phase Goal:** User can see their current Claude usage at a glance from the menu bar, with live data from OAuth endpoint and Claude Code logs
**Verified:** 2026-02-13
**Status:** PASSED
**Re-verification:** No -- initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | App runs as a background process with a status icon visible in the macOS menu bar (no Dock icon) | VERIFIED | `Info.plist` has `LSUIElement=true` (line 22). `TokemonApp.swift` uses `MenuBarExtra` with `.menuBarExtraStyle(.window)`. `StatusItemManager` renders colored `NSAttributedString` on `NSStatusItem.button`. |
| 2 | Clicking the menu bar icon opens a popover showing current usage (messages/tokens used, percentage of limit, limits remaining) broken down by source | VERIFIED | `PopoverContentView` composes `UsageHeaderView` (big 52pt percentage or token count), `UsageDetailView` (reset time + usage windows for OAuth; token counts for JSONL), `RefreshStatusView` (last updated), and `ErrorBannerView`. All receive `UsageMonitor` via `@Environment`. |
| 3 | Menu bar icon color reflects usage level (green/orange/red) so user can assess status without clicking | VERIFIED | `GradientColors.color(for:)` implements 5-level gradient: <40% secondary label, 40-64% warm green-yellow, 65-79% amber, 80-94% warm orange, 95%+ muted red. `StatusItemManager.update()` applies via `NSAttributedString` foreground color. Error state appends "!" in warm orange. |
| 4 | Usage data refreshes automatically at a configurable interval and user can manually trigger a refresh | VERIFIED | `UsageMonitor.startPolling()` creates `Timer.scheduledTimer` at `refreshInterval` (default 60s). Calls `refresh()` immediately on start. `RefreshSettings` offers 30s/1m/2m/5m/10m picker that restarts polling on change. Manual refresh: arrow.clockwise button in popover footer, "Refresh Now" in right-click context menu, and `manualRefresh()` from retry button. App Nap prevented via `ProcessInfo.beginActivity`. |
| 5 | User can enable/disable individual data sources in settings, and the app shows a clear message when a data source fails | VERIFIED | `DataSourceSettings` has toggles for "OAuth Endpoint (Primary)" and "Claude Code Logs (Fallback)" bound to `monitor.oauthEnabled`/`monitor.jsonlEnabled` with at-least-one-enabled guard. Status indicators (green/red/gray dots) per source. `ErrorBannerView` shows user-friendly messages ("Using backup data source", "Unable to fetch usage data", etc.) with "Show details" expander for technical error text and "Retry" button after 3 failed auto-retries. |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `Tokemon/TokemonApp.swift` | @main entry point with MenuBarExtra, StatusItemManager, right-click context menu | VERIFIED (249 lines) | @main struct with MenuBarExtra scene, @State UsageMonitor, StatusItemManager with NSAttributedString updates, ContextMenuActions with Refresh/Settings/Quit, right-click event monitor |
| `Tokemon/Info.plist` | LSUIElement=YES for background-only app | VERIFIED (27 lines) | LSUIElement true, bundle ID com.tokemon.app, macOS 14.0 minimum |
| `Tokemon/Models/UsageSnapshot.swift` | Central usage state model with OAuth + JSONL fields | VERIFIED (88 lines) | Codable/Sendable struct with percentage, utilization windows, token counts, DataSource enum, menuBarText, hasPercentage, formattedTokenCount |
| `Tokemon/Models/OAuthUsageResponse.swift` | Codable model for /api/oauth/usage | VERIFIED (56 lines) | fiveHour/sevenDay/sevenDayOpus UsageWindows with CodingKeys, toSnapshot() conversion |
| `Tokemon/Models/DataSourceState.swift` | Per-source availability enum | VERIFIED (17 lines) | available/failed(String)/disabled/notConfigured with isUsable computed property |
| `Tokemon/Services/UsageMonitor.swift` | @Observable central state manager with real data fetching | VERIFIED (255 lines) | OAuth-first/JSONL-fallback chain, retry logic (3 attempts then manual), one-time failure notification, UserDefaults-backed settings, Timer polling with App Nap prevention |
| `Tokemon/Services/OAuthClient.swift` | HTTP client for /api/oauth/usage | VERIFIED (128 lines) | fetchUsage with Bearer auth + anthropic-beta header, fetchUsageWithTokenRefresh with automatic refresh on 401, status code handling (200/401/403) |
| `Tokemon/Services/TokenManager.swift` | Keychain read, token validation, token refresh | VERIFIED (206 lines) | getCredentials from Keychain service "Claude Code-credentials" with empty key, 10-minute proactive expiry buffer, scope validation, refreshAccessToken via POST, updateKeychainCredentials write-back |
| `Tokemon/Services/JSONLParser.swift` | Defensive JSONL parser for ~/.claude/projects/ | VERIFIED (267 lines) | findProjectDirectories, findSessionFiles with date filter, parseSession with defensive line-by-line parsing (optional chaining, skip on error, log skip count), parseRecentUsage with aggregation, toSnapshot with -1 sentinel |
| `Tokemon/Services/SettingsWindowController.swift` | Custom NSWindow for settings (workaround for LSUIElement) | VERIFIED (55 lines) | Singleton with manual NSWindow creation, NSHostingController wrapping SettingsView |
| `Tokemon/Utilities/Constants.swift` | API URLs, Keychain service, defaults | VERIFIED (25 lines) | oauthUsageURL, oauthTokenRefreshURL, oauthClientId, keychainService, defaultRefreshInterval, claudeProjectsPath, maxRetryAttempts |
| `Tokemon/Utilities/GradientColors.swift` | Subtle usage-level color gradient | VERIFIED (30 lines) | 5-level gradient with calibrated NSColors (not harsh traffic lights) |
| `Tokemon/Utilities/Extensions.swift` | Date/number formatting extensions | VERIFIED (86 lines) | relativeTimeString(), formattedResetTime(), Int.formattedTokenCount, Double.percentageFormatted |
| `Tokemon/Views/MenuBar/PopoverContentView.swift` | Main popover composing all sub-views | VERIFIED (82 lines) | Composes UsageHeaderView, UsageDetailView, ErrorBannerView (conditional), RefreshStatusView, refresh button, gear menu with Settings/Quit |
| `Tokemon/Views/MenuBar/UsageHeaderView.swift` | Big percentage/token display | VERIFIED (57 lines) | 52pt SF Rounded bold text, GradientColors integration, JSONL token count fallback, "--%" for no data |
| `Tokemon/Views/MenuBar/UsageDetailView.swift` | Usage breakdown rows | VERIFIED (88 lines) | OAuth mode: reset time, 5-hour/7-day/Opus utilization. JSONL mode: input/output/cache token counts, model name |
| `Tokemon/Views/MenuBar/RefreshStatusView.swift` | Spinner + last updated timestamp | VERIFIED (32 lines) | ProgressView when refreshing, checkmark when idle, always-visible "Updated X ago" text |
| `Tokemon/Views/MenuBar/ErrorBannerView.swift` | Error state with Show details | VERIFIED (125 lines) | User-friendly messages by error type, "Show details"/"Hide details" toggle with animated expansion, technical description, Retry button when requiresManualRetry |
| `Tokemon/Views/Settings/SettingsView.swift` | Three-tab settings container | VERIFIED (30 lines) | TabView with General (RefreshSettings), Data Sources (DataSourceSettings), Appearance (AppearanceSettings) |
| `Tokemon/Views/Settings/DataSourceSettings.swift` | OAuth/JSONL toggles with guards | VERIFIED (114 lines) | Toggles with at-least-one-enabled prevention, status indicators (green/red/gray dots), descriptions |
| `Tokemon/Views/Settings/RefreshSettings.swift` | Refresh interval picker | VERIFIED (50 lines) | 5-option picker (30s to 10m), restarts polling on change, displays current interval |
| `Tokemon/Views/Settings/AppearanceSettings.swift` | Menu bar display style | VERIFIED (41 lines) | Percentage (active), Claude Logo (coming soon), Gauge Meter (coming soon) |
| `Package.swift` | SPM manifest with dependencies | VERIFIED (26 lines) | MenuBarExtraAccess 1.2.2, SettingsAccess 2.1.0, KeychainAccess 4.2.2, macOS 14+ |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| TokemonApp.swift | UsageMonitor | `@State private var monitor = UsageMonitor()` | WIRED | Line 9: instantiates monitor; passes to views via `.environment(monitor)` |
| TokemonApp.swift | PopoverContentView | `MenuBarExtra { PopoverContentView() }` | WIRED | Line 15: instantiated as MenuBarExtra content |
| TokemonApp.swift | StatusItemManager | `.menuBarExtraAccess` callback stores NSStatusItem | WIRED | Lines 27-49: stores statusItem, wires onUsageChanged callback, installs right-click monitor |
| UsageMonitor.swift | OAuthClient | `OAuthClient.fetchUsageWithTokenRefresh()` in refresh() | WIRED | Line 167: async call with response mapped to currentUsage via toSnapshot() |
| UsageMonitor.swift | JSONLParser | `JSONLParser.parseRecentUsage(since:)` in refresh() | WIRED | Lines 196-197: fallback call with toSnapshot() conversion |
| OAuthClient.swift | TokenManager | `TokenManager.getAccessToken()` + refresh flow | WIRED | Lines 97-101: getAccessToken with expired token catch, performTokenRefresh calls getRefreshToken/refreshAccessToken/updateKeychainCredentials |
| TokenManager.swift | Keychain | `Keychain(service: Constants.keychainService)` | WIRED | Line 71: reads from "Claude Code-credentials" service with empty key; line 204: write-back on refresh |
| PopoverContentView | UsageMonitor | `@Environment(UsageMonitor.self)` | WIRED | Line 8: environment injection, used for all subview data |
| PopoverContentView | SettingsWindowController | `SettingsWindowController.shared.showSettings()` | WIRED | Line 80: gear menu opens settings window |
| SettingsView | UsageMonitor | `@Environment(UsageMonitor.self)` | WIRED | Line 6: environment injection, passed to all tab views |
| DataSourceSettings | UsageMonitor settings | `$monitor.oauthEnabled` / `$monitor.jsonlEnabled` | WIRED | Lines 15, 38: @Bindable toggle bindings to UserDefaults-backed properties |
| RefreshSettings | UsageMonitor polling | Picker binding calls `monitor.startPolling(interval:)` | WIRED | Lines 23-28: onChange restarts polling with new interval |
| StatusItemManager | Right-click NSMenu | `NSEvent.addGlobalMonitorForEvents` | WIRED | Lines 113-148: global right-click monitor checks button bounds, shows context menu |

### Requirements Coverage

| Requirement | Status | Details |
|-------------|--------|---------|
| DATA-01: OAuth primary source | SATISFIED | OAuthClient.fetchUsageWithTokenRefresh() in UsageMonitor.refresh() |
| DATA-02: Clear message on OAuth failure | SATISFIED | ErrorBannerView with user-friendly messages + Show details |
| DATA-03: JSONL fallback | SATISFIED | JSONLParser.parseRecentUsage() as fallback in refresh() |
| DATA-04: Parse ~/.claude/projects/ | SATISFIED | JSONLParser.findProjectDirectories() + parseSession() |
| DATA-06: Enable/disable data sources | SATISFIED | DataSourceSettings toggles with at-least-one guard |
| MENU-01: Status icon in menu bar | SATISFIED | MenuBarExtra + StatusItemManager |
| MENU-02: Click opens popover | SATISFIED | MenuBarExtra .window style opens PopoverContentView |
| MENU-03: Visual usage level indicator | SATISFIED | GradientColors 5-level color on menu bar text |
| MENU-04: Background app (no Dock) | SATISFIED | Info.plist LSUIElement=true |
| MENU-05: Percentage and limits | SATISFIED | UsageHeaderView (percentage) + UsageDetailView (limits) |
| MENU-06: Breakdown by source | SATISFIED | UsageDetailView switches between OAuth rows and JSONL token rows |
| USAGE-01: Current usage display | SATISFIED | UsageHeaderView big number + UsageDetailView rows |
| USAGE-02: Limits remaining | SATISFIED | UsageDetailView "Resets in" row + utilization rows |
| USAGE-03: Usage as percentage | SATISFIED | primaryPercentage from OAuth fiveHour.utilization |
| USAGE-04: Auto-refresh at interval | SATISFIED | Timer-based polling with configurable interval |
| USAGE-05: Manual refresh | SATISFIED | Refresh button in popover + "Refresh Now" in context menu |
| SET-01: Settings from popover | SATISFIED | Gear menu in popover footer opens SettingsWindowController |
| SET-03: Configure refresh interval | SATISFIED | RefreshSettings picker with 5 interval options |
| SET-05: Configure active data sources | SATISFIED | DataSourceSettings with OAuth/JSONL toggles |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| AppearanceSettings.swift | 24-25 | "coming soon" placeholder options | Info | Expected per plan -- Claude Logo and Gauge Meter deferred to future phases. Percentage mode fully functional. |
| JSONLParser.swift | 99 | `return []` | Info | Correct defensive behavior -- returns empty array when directory contents can't be listed. Not a stub. |

No TODOs, FIXMEs, XXX, HACK, or PLACEHOLDER comments found anywhere in the codebase.

### Human Verification Required

All 5 items previously verified by human and confirmed passed:

1. Menu bar icon shows token count (JSONL fallback working)
2. Left-click opens popover with big number, details, footer
3. Gear menu shows Settings... and Quit options
4. Settings window opens with 3 tabs (General, Data Sources, Appearance)
5. Background refresh updates menu bar automatically

Human verification passed per 01-03-SUMMARY.md Task 3 checkpoint.

### Build Verification

- `swift build` succeeds with zero errors (verified during this verification)
- 21 Swift source files totaling 2,081 lines of code
- 3 SPM dependencies resolve correctly (MenuBarExtraAccess, SettingsAccess, KeychainAccess)
- 9 feature commits in clean git history

### Deviations from Original Plan (Acceptable)

1. **SPM instead of .xcodeproj:** Xcode.app not installed; SPM provides equivalent build capability. No impact on functionality.
2. **SettingsWindowController instead of SwiftUI Settings scene:** SwiftUI Settings scene unreliable in LSUIElement apps. Custom NSWindow controller is a robust workaround.
3. **Gear dropdown menu instead of right-click only:** Right-click detection in menu bar was unreliable. The gear dropdown in the popover footer provides the same functionality (Settings, Quit). Right-click context menu also implemented as a bonus.
4. **DataSourceState uses String instead of Error:** Required for Sendable conformance in Swift 6 strict concurrency mode.

### Gaps Summary

No gaps found. All 5 success criteria from ROADMAP.md are verified through both automated code analysis and human testing. Every artifact exists, is substantive (no stubs), and is properly wired into the application architecture. The data pipeline flows correctly from Keychain -> TokenManager -> OAuthClient -> UsageMonitor -> UI (with JSONL fallback path). All 18 Phase 1 requirements are satisfied.

---

_Verified: 2026-02-13_
_Verifier: Claude (gsd-verifier)_
