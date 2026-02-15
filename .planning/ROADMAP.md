# Roadmap: ClaudeMon

## Milestones

- **v1.0 MVP** — Phases 1-5 (shipped 2026-02-14) — [Archive](milestones/v1.0-ROADMAP.md)
- **v2.0 Pro Features** — Phases 6-9 (in progress)

## Phases

<details>
<summary>v1.0 MVP (Phases 1-5) — SHIPPED 2026-02-14</summary>

- [x] Phase 1: Foundation & Core Monitoring (3/3 plans) — completed 2026-02-12
- [x] Phase 2: Alerts & Notifications (2/2 plans) — completed 2026-02-13
- [x] Phase 3: Usage Trends & API Integration (3/3 plans) — completed 2026-02-13
- [x] Phase 4: Floating Window (2/2 plans) — completed 2026-02-14
- [x] Phase 5: Theming & Design Polish (2/2 plans) — completed 2026-02-14

See [v1.0-ROADMAP.md](milestones/v1.0-ROADMAP.md) for full details.

</details>

### v2.0 Pro Features (In Progress)

**Milestone Goal:** Transform ClaudeMon into a paid product with licensing, multi-account support, extended analytics, and viral sharing features.

- [x] **Phase 6: Licensing Foundation** — LemonSqueezy integration with trial and Pro gating — completed 2026-02-14
- [x] **Phase 7: Multi-Account** — Multiple Claude accounts with per-account alerts — completed 2026-02-14
- [ ] **Phase 8: Analytics & Export** — Extended history, summaries, PDF/CSV export
- [ ] **Phase 9: Shareable Moments** — Usage card generation for social sharing

## Phase Details

### Phase 6: Licensing Foundation
**Goal**: Users can trial the app and purchase/activate a Pro subscription
**Depends on**: Phase 5 (v1.0 complete)
**Requirements**: LICENSE-01, LICENSE-02, LICENSE-03, LICENSE-04, LICENSE-05
**Success Criteria** (what must be TRUE):
  1. User sees trial status with days remaining in menu bar/settings
  2. User is prompted to purchase when trial expires (app remains functional with limited features)
  3. User can enter a license key and see "Pro" status after successful activation
  4. App validates license on launch without blocking the UI
  5. User can click a link to manage subscription in LemonSqueezy portal
**Plans**: 3 plans in 3 waves

Plans:
- [x] 06-01-PLAN.md — LemonSqueezy integration, LicenseState model, LicenseManager service (Wave 1)
- [x] 06-02-PLAN.md — Trial banner, purchase prompt, LicenseSettings tab (Wave 2)
- [x] 06-03-PLAN.md — FeatureAccessManager and Pro gating UI (Wave 3)

### Phase 7: Multi-Account
**Goal**: Users can manage multiple Claude accounts and see usage across all of them
**Depends on**: Phase 6 (licensing gates Pro features)
**Requirements**: ACCOUNT-01, ACCOUNT-02, ACCOUNT-03, ACCOUNT-04, ACCOUNT-05
**Success Criteria** (what must be TRUE):
  1. User can add a second Claude account via OAuth
  2. User can switch between accounts from the menu bar popover
  3. User can remove an account from settings
  4. User can set different alert thresholds per account
  5. User can view combined usage summary across all accounts
**Plans**: 3 plans in 3 waves

Plans:
- [x] 07-01-PLAN.md — Account/AccountSettings models, AccountManager service, TokenManager extensions (Wave 1)
- [x] 07-02-PLAN.md — AccountSwitcherView in popover, AccountsSettings tab, app integration (Wave 2)
- [x] 07-03-PLAN.md — Per-account alerts, CombinedUsageView, per-account HistoryStore (Wave 3)

### Phase 8: Analytics & Export
**Goal**: Users can view extended usage history and export reports
**Depends on**: Phase 6 (licensing gates Pro features)
**Requirements**: ANALYTICS-01, ANALYTICS-02, ANALYTICS-03, ANALYTICS-04, ANALYTICS-05, ANALYTICS-06, ANALYTICS-07
**Success Criteria** (what must be TRUE):
  1. User can view weekly and monthly usage summaries with totals and breakdowns
  2. User can export a PDF report of their usage (with charts and breakdowns)
  3. User can export raw usage data as CSV
  4. User can view 30-day and 90-day usage history graphs
  5. User can see which projects/folders consumed the most tokens
**Plans**: 3 plans in 3 waves

Plans:
- [ ] 08-01-PLAN.md — Extended HistoryStore with 90-day retention and hourly downsampling (Wave 1)
- [ ] 08-02-PLAN.md — AnalyticsEngine, usage summaries, project breakdown, Analytics tab (Wave 2)
- [ ] 08-03-PLAN.md — PDF and CSV export with ExportManager (Wave 3)

### Phase 9: Shareable Moments
**Goal**: Users can generate and share branded usage cards for social engagement
**Depends on**: Phase 8 (uses analytics data for card content)
**Requirements**: SHARE-01, SHARE-02, SHARE-03
**Success Criteria** (what must be TRUE):
  1. User can generate a "usage card" image showing their stats
  2. User can copy the card image to clipboard with one click
  3. Usage card includes ClaudeMon branding (logo/URL)
**Plans**: TBD

Plans:
- [ ] 09-01: ShareableCardView templates
- [ ] 09-02: Image generation and share sheet integration

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation & Core Monitoring | v1.0 | 3/3 | Complete | 2026-02-12 |
| 2. Alerts & Notifications | v1.0 | 2/2 | Complete | 2026-02-13 |
| 3. Usage Trends & API Integration | v1.0 | 3/3 | Complete | 2026-02-13 |
| 4. Floating Window | v1.0 | 2/2 | Complete | 2026-02-14 |
| 5. Theming & Design Polish | v1.0 | 2/2 | Complete | 2026-02-14 |
| 6. Licensing Foundation | v2.0 | 3/3 | Complete | 2026-02-14 |
| 7. Multi-Account | v2.0 | 3/3 | Complete | 2026-02-14 |
| 8. Analytics & Export | v2.0 | 0/3 | Planned | - |
| 9. Shareable Moments | v2.0 | 0/2 | Not started | - |

---

*v2 roadmap created: 2026-02-14*
*Phase 6 completed: 2026-02-14*
*Phase 7 completed: 2026-02-14*
*Phase 8 planned: 2026-02-15*
