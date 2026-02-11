# Requirements: ClaudeMon

**Defined:** 2026-02-11
**Core Value:** Know your Claude usage at a glance before hitting limits.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Data Sources

- [ ] **DATA-01**: App fetches usage data from OAuth endpoint as primary source
- [ ] **DATA-02**: App displays clear message if OAuth endpoint fails or changes
- [ ] **DATA-03**: App falls back to Claude Code JSONL parsing when OAuth unavailable
- [ ] **DATA-04**: App can parse Claude Code logs from `~/.claude/projects/`
- [ ] **DATA-05**: User can optionally connect Admin API with organization key
- [ ] **DATA-06**: User can enable/disable each data source independently in settings

### Display - Menu Bar

- [ ] **MENU-01**: App displays status icon in macOS menu bar
- [ ] **MENU-02**: User can click menu bar icon to open popover with usage details
- [ ] **MENU-03**: Menu bar icon shows visual indicator of usage level (color/fill)
- [ ] **MENU-04**: App runs as background app (no Dock icon)
- [ ] **MENU-05**: Popover shows current usage percentage and limits remaining
- [ ] **MENU-06**: Popover shows usage breakdown by source (when multiple enabled)

### Display - Floating Window

- [ ] **FLOAT-01**: User can open a compact floating window from menu bar
- [ ] **FLOAT-02**: Floating window stays on top of other windows
- [ ] **FLOAT-03**: User can position floating window in any screen corner
- [ ] **FLOAT-04**: Floating window remembers its position between sessions
- [ ] **FLOAT-05**: Floating window shows minimal usage info (percentage, limit status)
- [ ] **FLOAT-06**: User can close floating window without quitting app

### Monitoring - Usage & Limits

- [ ] **USAGE-01**: App displays current usage (messages/tokens used this period)
- [ ] **USAGE-02**: App displays limits remaining before hitting cap
- [ ] **USAGE-03**: App displays usage as percentage of total limit
- [ ] **USAGE-04**: App refreshes usage data automatically at configurable interval
- [ ] **USAGE-05**: User can manually refresh usage data

### Monitoring - Alerts

- [ ] **ALERT-01**: App shows visual warning indicator when approaching limit threshold
- [ ] **ALERT-02**: App sends macOS notification when approaching limit threshold
- [ ] **ALERT-03**: User can configure alert threshold percentage (e.g., 80%, 90%)
- [ ] **ALERT-04**: User can enable/disable macOS notifications in settings
- [ ] **ALERT-05**: App shows critical alert when limit is reached

### Monitoring - Trends

- [ ] **TREND-01**: App stores historical usage data locally
- [ ] **TREND-02**: User can view usage graph over time (daily/weekly)
- [ ] **TREND-03**: Graph displays usage patterns with clear visualization
- [ ] **TREND-04**: User can see burn rate (current usage pace)
- [ ] **TREND-05**: App projects estimated time until limit hit at current pace

### Theming

- [ ] **THEME-01**: App supports Native macOS theme (follows system appearance)
- [ ] **THEME-02**: App supports Minimal dark theme
- [ ] **THEME-03**: App supports Anthropic-inspired theme (warm tones)
- [ ] **THEME-04**: User can switch themes in settings
- [ ] **THEME-05**: Theme applies consistently to menu bar popover and floating window

### Settings & Configuration

- [ ] **SET-01**: User can access settings from menu bar popover
- [ ] **SET-02**: User can configure app to launch at login
- [ ] **SET-03**: User can configure refresh interval
- [ ] **SET-04**: User can configure alert thresholds
- [ ] **SET-05**: User can configure which data sources are active

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### iOS App

- **IOS-01**: User can view usage on iOS companion app
- **IOS-02**: User receives push notifications on iOS when limits approached
- **IOS-03**: iOS app syncs with macOS app data

### Notification Center Widget

- **WIDGET-01**: User can add ClaudeMon widget to Notification Center
- **WIDGET-02**: Widget shows summary usage stats (refreshes periodically)

### Advanced Analytics

- **ANALYTICS-01**: User can see which agents/models consume most tokens
- **ANALYTICS-02**: User can see per-call cost breakdown
- **ANALYTICS-03**: App suggests alternative models for cost optimization
- **ANALYTICS-04**: App provides tips for reducing token usage

### Web Interface

- **WEB-01**: User can view usage via web dashboard
- **WEB-02**: Web interface syncs with macOS app

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Mac App Store distribution | Sandbox blocks ~/.claude access; distribute via GitHub |
| Real-time Notification Center widget | WidgetKit limited to 40-70 refreshes/day |
| Multi-provider monitoring | Focus on Claude-only for best-in-class experience |
| Claude.ai scraping | Too fragile; using OAuth endpoint instead |
| Automatic model switching | v2+ analytics feature |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| DATA-01 | Phase 1 | Pending |
| DATA-02 | Phase 1 | Pending |
| DATA-03 | Phase 1 | Pending |
| DATA-04 | Phase 1 | Pending |
| DATA-05 | Phase 3 | Pending |
| DATA-06 | Phase 1 | Pending |
| MENU-01 | Phase 1 | Pending |
| MENU-02 | Phase 1 | Pending |
| MENU-03 | Phase 1 | Pending |
| MENU-04 | Phase 1 | Pending |
| MENU-05 | Phase 1 | Pending |
| MENU-06 | Phase 1 | Pending |
| FLOAT-01 | Phase 4 | Pending |
| FLOAT-02 | Phase 4 | Pending |
| FLOAT-03 | Phase 4 | Pending |
| FLOAT-04 | Phase 4 | Pending |
| FLOAT-05 | Phase 4 | Pending |
| FLOAT-06 | Phase 4 | Pending |
| USAGE-01 | Phase 1 | Pending |
| USAGE-02 | Phase 1 | Pending |
| USAGE-03 | Phase 1 | Pending |
| USAGE-04 | Phase 1 | Pending |
| USAGE-05 | Phase 1 | Pending |
| ALERT-01 | Phase 2 | Pending |
| ALERT-02 | Phase 2 | Pending |
| ALERT-03 | Phase 2 | Pending |
| ALERT-04 | Phase 2 | Pending |
| ALERT-05 | Phase 2 | Pending |
| TREND-01 | Phase 3 | Pending |
| TREND-02 | Phase 3 | Pending |
| TREND-03 | Phase 3 | Pending |
| TREND-04 | Phase 3 | Pending |
| TREND-05 | Phase 3 | Pending |
| THEME-01 | Phase 5 | Pending |
| THEME-02 | Phase 5 | Pending |
| THEME-03 | Phase 5 | Pending |
| THEME-04 | Phase 5 | Pending |
| THEME-05 | Phase 5 | Pending |
| SET-01 | Phase 1 | Pending |
| SET-02 | Phase 2 | Pending |
| SET-03 | Phase 1 | Pending |
| SET-04 | Phase 2 | Pending |
| SET-05 | Phase 1 | Pending |

**Coverage:**
- v1 requirements: 43 total
- Mapped to phases: 43
- Unmapped: 0

---
*Requirements defined: 2026-02-11*
*Last updated: 2026-02-11 after roadmap creation*
