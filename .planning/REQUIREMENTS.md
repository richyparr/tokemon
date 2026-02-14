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

- [ ] **ACCOUNT-01**: User can add multiple Claude accounts
- [ ] **ACCOUNT-02**: User can switch between accounts
- [ ] **ACCOUNT-03**: User can remove an account
- [ ] **ACCOUNT-04**: User can set per-account alert thresholds
- [ ] **ACCOUNT-05**: User can see combined usage across all accounts

### Licensing

- [ ] **LICENSE-01**: App shows trial status (X days remaining)
- [ ] **LICENSE-02**: App prompts to purchase when trial expires
- [ ] **LICENSE-03**: User can enter license key to activate
- [ ] **LICENSE-04**: App validates license on launch
- [ ] **LICENSE-05**: User can manage subscription (links to LemonSqueezy portal)

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
| ANALYTICS-01 | TBD | Pending |
| ANALYTICS-02 | TBD | Pending |
| ANALYTICS-03 | TBD | Pending |
| ANALYTICS-04 | TBD | Pending |
| ANALYTICS-05 | TBD | Pending |
| ANALYTICS-06 | TBD | Pending |
| ANALYTICS-07 | TBD | Pending |
| ACCOUNT-01 | TBD | Pending |
| ACCOUNT-02 | TBD | Pending |
| ACCOUNT-03 | TBD | Pending |
| ACCOUNT-04 | TBD | Pending |
| ACCOUNT-05 | TBD | Pending |
| LICENSE-01 | TBD | Pending |
| LICENSE-02 | TBD | Pending |
| LICENSE-03 | TBD | Pending |
| LICENSE-04 | TBD | Pending |
| LICENSE-05 | TBD | Pending |
| SHARE-01 | TBD | Pending |
| SHARE-02 | TBD | Pending |
| SHARE-03 | TBD | Pending |

**Coverage:**
- v2 requirements: 20 total
- Mapped to phases: 0
- Unmapped: 20

---
*Requirements defined: 2026-02-14*
*Last updated: 2026-02-14 after v2 milestone start*
