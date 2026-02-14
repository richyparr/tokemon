# Roadmap: ClaudeMon

## Overview

ClaudeMon delivers a native macOS menu bar utility for monitoring Claude usage at a glance. The roadmap builds from a working menu bar app with live data (Phase 1) through alerts, trends, and a floating window, ending with visual polish across all display modes. Each phase delivers a complete, independently verifiable capability -- the app is useful from the end of Phase 1 onward.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Foundation & Core Monitoring** - Working menu bar app with live usage data from OAuth/JSONL sources
- [x] **Phase 2: Alerts & Notifications** - Warning system when approaching usage limits
- [x] **Phase 3: Usage Trends & API Integration** - Historical usage tracking, projections, and optional Admin API
- [x] **Phase 4: Floating Window** - Always-on-top compact usage display
- [ ] **Phase 5: Theming & Design Polish** - Three themes with consistent visual refinement across all display modes

## Phase Details

### Phase 1: Foundation & Core Monitoring
**Goal**: User can see their current Claude usage at a glance from the menu bar, with live data from OAuth endpoint and Claude Code logs
**Depends on**: Nothing (first phase)
**Requirements**: DATA-01, DATA-02, DATA-03, DATA-04, DATA-06, MENU-01, MENU-02, MENU-03, MENU-04, MENU-05, MENU-06, USAGE-01, USAGE-02, USAGE-03, USAGE-04, USAGE-05, SET-01, SET-03, SET-05
**Success Criteria** (what must be TRUE):
  1. App runs as a background process with a status icon visible in the macOS menu bar (no Dock icon)
  2. Clicking the menu bar icon opens a popover showing current usage (messages/tokens used, percentage of limit, limits remaining) broken down by source
  3. Menu bar icon color reflects usage level (green/orange/red) so user can assess status without clicking
  4. Usage data refreshes automatically at a configurable interval and user can manually trigger a refresh
  5. User can enable/disable individual data sources in settings, and the app shows a clear message when a data source fails
**Plans:** 3 plans

Plans:
- [x] 01-01-PLAN.md -- Xcode project foundation, menu bar app shell with popover, data models, and mock polling
- [x] 01-02-PLAN.md -- Real data layer: OAuth client, Keychain token manager, JSONL parser, live data in UsageMonitor
- [x] 01-03-PLAN.md -- Popover UI polish, settings window, right-click context menu, error states, human verification

### Phase 2: Alerts & Notifications
**Goal**: User receives timely warnings when approaching Claude usage limits, with configurable thresholds and delivery preferences
**Depends on**: Phase 1
**Requirements**: ALERT-01, ALERT-02, ALERT-03, ALERT-04, ALERT-05, SET-02, SET-04
**Success Criteria** (what must be TRUE):
  1. App shows a visual warning indicator in the menu bar and popover when usage crosses a configurable threshold (e.g., 80%)
  2. App sends a macOS system notification when approaching the limit, and user can enable/disable these notifications in settings
  3. App shows a distinct critical alert when the usage limit is fully reached
  4. User can configure the alert threshold percentage and the app can be set to launch at login
**Plans:** 2 plans

Plans:
- [x] 02-01-PLAN.md -- AlertManager service with threshold checking, visual warning indicators in menu bar and popover
- [x] 02-02-PLAN.md -- macOS system notifications, Alerts settings tab with threshold config, notification toggle, launch at login

### Phase 3: Usage Trends & API Integration
**Goal**: User can understand their usage patterns over time and project when they will hit limits, with optional API-based cost tracking for org admins
**Depends on**: Phase 2
**Requirements**: TREND-01, TREND-02, TREND-03, TREND-04, TREND-05, DATA-05
**Success Criteria** (what must be TRUE):
  1. User can view a usage graph showing daily and weekly trends with clear visualization
  2. User can see their current burn rate (usage pace) and an estimate of when they will hit their limit at that pace
  3. Historical usage data persists across app launches (stored locally)
  4. User can optionally connect an Admin API organization key to access cost and usage data from the Anthropic API
**Plans:** 3 plans

Plans:
- [x] 03-01-PLAN.md -- Historical data storage with HistoryStore actor, UsageDataPoint model, JSON persistence, wire to UsageMonitor
- [x] 03-02-PLAN.md -- Swift Charts visualization, BurnRateCalculator for pace/projection, UsageChartView and BurnRateView in popover
- [x] 03-03-PLAN.md -- Optional Admin API integration with AdminAPIClient, Keychain storage, AdminAPISettings tab

### Phase 4: Floating Window
**Goal**: User can keep a compact, always-visible usage display on screen while working
**Depends on**: Phase 1
**Requirements**: FLOAT-01, FLOAT-02, FLOAT-03, FLOAT-04, FLOAT-05, FLOAT-06
**Success Criteria** (what must be TRUE):
  1. User can open a compact floating window from the menu bar that stays on top of other windows
  2. User can position the floating window in any screen corner and it remembers its position between sessions
  3. Floating window shows minimal usage info (percentage, limit status) drawn from the same live data as the menu bar
  4. User can close the floating window without quitting the app
**Plans:** 2 plans

Plans:
- [x] 04-01-PLAN.md -- FloatingPanel NSPanel subclass, FloatingWindowController service, NSWindow position extension
- [x] 04-02-PLAN.md -- FloatingWindowView UI with live data, context menu integration, human verification

### Phase 5: Theming & Design Polish
**Goal**: App looks polished and professional with three distinct theme options applied consistently across all display modes
**Depends on**: Phase 4
**Requirements**: THEME-01, THEME-02, THEME-03, THEME-04, THEME-05
**Success Criteria** (what must be TRUE):
  1. User can choose between three themes in settings: Native macOS (follows system appearance), Minimal dark, and Anthropic-inspired (warm tones)
  2. Selected theme applies consistently to both the menu bar popover and the floating window
  3. Colors, spacing, typography, and component styling (gauges, charts, badges, buttons) are visually cohesive within each theme
**Plans**: TBD

Plans:
- [ ] 05-01: TBD
- [ ] 05-02: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4 -> 5

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation & Core Monitoring | 3/3 | Complete | 2026-02-12 |
| 2. Alerts & Notifications | 2/2 | Complete | 2026-02-13 |
| 3. Usage Trends & API Integration | 3/3 | Complete | 2026-02-13 |
| 4. Floating Window | 2/2 | Complete | 2026-02-14 |
| 5. Theming & Design Polish | 0/2 | Not started | - |
