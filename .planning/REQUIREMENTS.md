# Requirements: ClaudeMon

**Defined:** 2026-02-14
**Core Value:** Know your Claude usage at a glance before hitting limits.

## v2 Requirements

Requirements for v2 Pro release. Each maps to roadmap phases.

### Analytics & Reports

- [ ] **ANALYTICS-01**: User can view weekly usage summary
- [ ] **ANALYTICS-02**: User can view monthly usage summary
- [ ] **ANALYTICS-03**: User can export usage report as PDF
- [ ] **ANALYTICS-04**: User can export usage data as CSV
- [ ] **ANALYTICS-05**: User can view 30-day usage history
- [ ] **ANALYTICS-06**: User can view 90-day usage history
- [ ] **ANALYTICS-07**: User can see project/folder breakdown (which projects used most tokens)

### Multi-Account

- [x] **ACCOUNT-01**: User can add multiple Claude accounts
- [x] **ACCOUNT-02**: User can switch between accounts
- [x] **ACCOUNT-03**: User can remove an account
- [x] **ACCOUNT-04**: User can set per-account alert thresholds
- [x] **ACCOUNT-05**: User can see combined usage across all accounts

### Licensing

- [x] **LICENSE-01**: App shows trial status (X days remaining)
- [x] **LICENSE-02**: App prompts to purchase when trial expires
- [x] **LICENSE-03**: User can enter license key to activate
- [x] **LICENSE-04**: App validates license on launch
- [x] **LICENSE-05**: User can manage subscription (links to LemonSqueezy portal)

### Shareable Moments

- [ ] **SHARE-01**: User can generate "usage card" image showing their stats
- [ ] **SHARE-02**: User can copy image to clipboard for sharing
- [ ] **SHARE-03**: Usage card includes ClaudeMon branding (viral marketing)

## v3 Requirements

Deferred to future release. Tracked but not in current roadmap.

### iOS Companion

- **IOS-01**: User can view usage on iOS app
- **IOS-02**: User receives push notifications on iOS
- **IOS-03**: Settings sync via iCloud

### Integrations

- **INTEG-01**: Raycast extension for quick usage check
- **INTEG-02**: Alfred workflow for quick usage check
- **INTEG-03**: Shortcuts integration for automation

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Mac App Store distribution | Sandbox blocks ~/.claude access; need JSONL for project breakdown |
| Open source | Closed source for monetization |
| Web interface | Focus on native Mac experience |
| Multi-provider (OpenAI, etc.) | Claude-only for best-in-class experience |
| Real-time widget | WidgetKit refresh budget too limiting |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| LICENSE-01 | Phase 6 | Complete |
| LICENSE-02 | Phase 6 | Complete |
| LICENSE-03 | Phase 6 | Complete |
| LICENSE-04 | Phase 6 | Complete |
| LICENSE-05 | Phase 6 | Complete |
| ACCOUNT-01 | Phase 7 | Complete |
| ACCOUNT-02 | Phase 7 | Complete |
| ACCOUNT-03 | Phase 7 | Complete |
| ACCOUNT-04 | Phase 7 | Complete |
| ACCOUNT-05 | Phase 7 | Complete |
| ANALYTICS-01 | Phase 8 | Pending |
| ANALYTICS-02 | Phase 8 | Pending |
| ANALYTICS-03 | Phase 8 | Pending |
| ANALYTICS-04 | Phase 8 | Pending |
| ANALYTICS-05 | Phase 8 | Pending |
| ANALYTICS-06 | Phase 8 | Pending |
| ANALYTICS-07 | Phase 8 | Pending |
| SHARE-01 | Phase 9 | Pending |
| SHARE-02 | Phase 9 | Pending |
| SHARE-03 | Phase 9 | Pending |

**Coverage:**
- v2 requirements: 20 total
- Mapped to phases: 20
- Unmapped: 0

---
*Requirements defined: 2026-02-14*
*Last updated: 2026-02-14 after v2 roadmap creation*
