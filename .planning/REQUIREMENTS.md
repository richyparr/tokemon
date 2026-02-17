# Requirements: Tokemon

**Defined:** 2026-02-14
**Core Value:** Know your Claude usage at a glance before hitting limits.

## v2 Requirements (Shipped)

Requirements for v2 Pro release. All complete except shareable moments.

### Analytics & Reports

- [x] **ANALYTICS-01**: User can view weekly usage summary
- [x] **ANALYTICS-02**: User can view monthly usage summary
- [x] **ANALYTICS-03**: User can export usage report as PDF
- [x] **ANALYTICS-04**: User can export usage data as CSV
- [x] **ANALYTICS-05**: User can view 30-day usage history
- [x] **ANALYTICS-06**: User can view 90-day usage history
- [x] **ANALYTICS-07**: User can see project/folder breakdown

### Multi-Account (REMOVED)

*Removed post-ship due to Claude Code keychain architecture limitations.*

- [x] ~~ACCOUNT-01 through ACCOUNT-05~~ -- Replaced by PROF-* in v3

### Licensing

- [x] **LICENSE-01**: App shows trial status (X days remaining)
- [x] **LICENSE-02**: App prompts to purchase when trial expires
- [x] **LICENSE-03**: User can enter license key to activate
- [x] **LICENSE-04**: App validates license on launch
- [x] **LICENSE-05**: User can manage subscription (links to LemonSqueezy portal)

### Shareable Moments

- [x] **SHARE-01**: User can generate "usage card" image showing their stats
- [x] **SHARE-02**: User can copy image to clipboard for sharing
- [x] **SHARE-03**: Usage card includes Tokemon branding (viral marketing)

---

## v3.0 Requirements

Requirements for v3.0 Competitive Parity & Growth milestone.

### Multi-Profile (FREE)

- [x] **PROF-01**: User can create multiple profiles with custom names
- [x] **PROF-02**: User can sync CLI credentials from system keychain to profile
- [x] **PROF-03**: User can enter manual session keys for secondary accounts
- [x] **PROF-04**: User can switch between profiles (writes credentials to system keychain)
- [x] **PROF-05**: User can delete profiles
- [x] **PROF-06**: User can see all profiles' usage in menu bar simultaneously

### Menu Bar Customization (FREE)

- [ ] **MENU-01**: User can choose from 5 icon styles (battery, progress, percentage, icon+bar, compact)
- [ ] **MENU-02**: User can toggle monochrome mode
- [ ] **MENU-03**: Icon color reflects usage status (green/orange/red)

### Terminal Statusline (FREE)

- [ ] **TERM-01**: User can display usage in terminal statusline (bash/zsh prompt)
- [ ] **TERM-02**: Statusline shows session %, weekly %, reset timer
- [ ] **TERM-03**: User can customize statusline format
- [ ] **TERM-04**: One-click install script for statusline

### Distribution & Trust (FREE)

- [ ] **DIST-01**: App distributed via Homebrew tap (`brew install tokemon`)
- [ ] **DIST-02**: App signed with Apple Developer certificate
- [ ] **DIST-03**: App notarized for Gatekeeper
- [ ] **DIST-04**: Sparkle framework for automatic updates
- [ ] **DIST-05**: Update notifications in app

### Automation (FREE)

- [ ] **AUTO-01**: User can enable auto-start session when usage resets to 0%

### Team Dashboard (PRO)

- [ ] **TEAM-01**: User can view aggregated usage across org members (via Admin API)
- [ ] **TEAM-02**: User can see per-member usage breakdown
- [ ] **TEAM-03**: User can filter by date range

### Webhook Alerts (PRO)

- [ ] **HOOK-01**: User can configure Slack webhook URL
- [ ] **HOOK-02**: User can configure Discord webhook URL
- [ ] **HOOK-03**: User receives webhook notification at threshold
- [ ] **HOOK-04**: User can customize webhook message format

### Budget Tracking (PRO)

- [ ] **BUDG-01**: User can set monthly $ budget limit
- [ ] **BUDG-02**: User sees current spend vs budget
- [ ] **BUDG-03**: User receives alert at budget threshold (50%, 75%, 90%)
- [ ] **BUDG-04**: User can see cost attribution by project

### Usage Forecasting (PRO)

- [ ] **FORE-01**: User sees predicted time to limit based on usage patterns
- [ ] **FORE-02**: User sees "on pace" / "ahead" / "behind" indicator
- [ ] **FORE-03**: Prediction updates in real-time as usage changes

---

## Future Requirements (v4+)

### Localization

- **LOC-01**: App supports English, Spanish, French, German, Japanese
- **LOC-02**: All UI strings externalized for translation

### macOS Widgets

- **WIDG-01**: User can add usage widget to Notification Center
- **WIDG-02**: Widget shows session %, weekly %, reset timer

### iOS Companion

- **IOS-01**: User can view usage on iOS app
- **IOS-02**: User receives push notifications on iOS
- **IOS-03**: Settings sync via iCloud

### Integrations

- **INTEG-01**: Raycast extension for quick usage check
- **INTEG-02**: Alfred workflow for quick usage check

## Out of Scope

| Feature | Reason |
|---------|--------|
| Multi-provider (Copilot, Cursor, Gemini) | Claude-only for best-in-class experience |
| Mac App Store distribution | Sandbox blocks ~/.claude access |
| Open source | Closed source for monetization |
| Web interface | Focus on native Mac experience |
| Real-time widget | WidgetKit refresh budget too limiting |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| PROF-01 | Phase 11 | Complete |
| PROF-02 | Phase 11 | Complete |
| PROF-03 | Phase 11 | Complete |
| PROF-04 | Phase 11 | Complete |
| PROF-05 | Phase 11 | Complete |
| PROF-06 | Phase 11 | Complete |
| MENU-01 | Phase 12 | Pending |
| MENU-02 | Phase 12 | Pending |
| MENU-03 | Phase 12 | Pending |
| TERM-01 | Phase 13 | Pending |
| TERM-02 | Phase 13 | Pending |
| TERM-03 | Phase 13 | Pending |
| TERM-04 | Phase 13 | Pending |
| DIST-01 | Phase 14 | Pending |
| DIST-02 | Phase 14 | Pending |
| DIST-03 | Phase 14 | Pending |
| DIST-04 | Phase 14 | Pending |
| DIST-05 | Phase 14 | Pending |
| AUTO-01 | Phase 14 | Pending |
| TEAM-01 | Phase 15 | Pending |
| TEAM-02 | Phase 15 | Pending |
| TEAM-03 | Phase 15 | Pending |
| HOOK-01 | Phase 16 | Pending |
| HOOK-02 | Phase 16 | Pending |
| HOOK-03 | Phase 16 | Pending |
| HOOK-04 | Phase 16 | Pending |
| BUDG-01 | Phase 17 | Pending |
| BUDG-02 | Phase 17 | Pending |
| BUDG-03 | Phase 17 | Pending |
| BUDG-04 | Phase 17 | Pending |
| FORE-01 | Phase 17 | Pending |
| FORE-02 | Phase 17 | Pending |
| FORE-03 | Phase 17 | Pending |

**Coverage:**
- v3.0 requirements: 33 total
- Mapped to phases: 33
- Unmapped: 0

---
*Requirements defined: 2026-02-14*
*Last updated: 2026-02-17 after v3.0 roadmap creation*
