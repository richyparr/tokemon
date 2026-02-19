# Roadmap: Tokemon

## Milestones

- **v1.0 MVP** -- Phases 1-5 (shipped 2026-02-14) -- [Archive](milestones/v1.0-ROADMAP.md)
- **v2.0 Pro Features** -- Phases 6-9 (shipped 2026-02-15) -- [Archive](milestones/v2.0-ROADMAP.md)
- **v3.0 Competitive Parity & Growth** -- Phases 11-17 (shipped 2026-02-17) -- [Archive](milestones/v3.0-ROADMAP.md)
- **v4.0 Raycast Integration** -- Phases 18-21 (in progress)

## Phases

<details>
<summary>v1.0 MVP (Phases 1-5) -- SHIPPED 2026-02-14</summary>

- [x] Phase 1: Foundation & Core Monitoring (3/3 plans) -- completed 2026-02-12
- [x] Phase 2: Alerts & Notifications (2/2 plans) -- completed 2026-02-13
- [x] Phase 3: Usage Trends & API Integration (3/3 plans) -- completed 2026-02-13
- [x] Phase 4: Floating Window (2/2 plans) -- completed 2026-02-14
- [x] Phase 5: Theming & Design Polish (2/2 plans) -- completed 2026-02-14

See [v1.0-ROADMAP.md](milestones/v1.0-ROADMAP.md) for full details.

</details>

<details>
<summary>v2.0 Pro Features (Phases 6-9) -- SHIPPED 2026-02-15</summary>

- [x] Phase 6: Licensing Foundation (3/3 plans) -- completed 2026-02-14
- [x] Phase 7: Multi-Account (3/3 plans) -- completed 2026-02-14
- [x] Phase 8: Analytics & Export (3/3 plans) -- completed 2026-02-15
- [x] Phase 9: Shareable Moments (2/2 plans) -- completed 2026-02-15

See [v2.0-ROADMAP.md](milestones/v2.0-ROADMAP.md) for full details.

</details>

<details>
<summary>v3.0 Competitive Parity & Growth (Phases 11-17) -- SHIPPED 2026-02-17</summary>

- [x] Phase 11: Multi-Profile Foundation (3/3 plans) -- completed 2026-02-17
- [x] Phase 12: Menu Bar Customization (2/2 plans) -- completed 2026-02-17
- [x] Phase 13: Terminal Statusline (2/2 plans) -- completed 2026-02-17
- [x] Phase 14: Distribution & Trust (4/4 plans) -- completed 2026-02-17
- [x] Phase 15: Team Dashboard PRO (2/2 plans) -- completed 2026-02-17
- [x] Phase 16: Webhook Alerts PRO (2/2 plans) -- completed 2026-02-17
- [x] Phase 17: Budget & Forecasting PRO (2/2 plans) -- completed 2026-02-17

See [v3.0-ROADMAP.md](milestones/v3.0-ROADMAP.md) for full details.

</details>

---

## Phase 17.1: Automated Testing (INSERTED)

**Goal:** Build XCTest and XCUITest infrastructure to catch UI bugs, especially height/layout issues, with snapshot testing for visual regression detection.

**Depends on:** Phase 17 (v3.0 complete)
**Scope:** Swift/macOS app only (not Raycast extension)

**Success Criteria** (what must be TRUE):
1. XCTest target configured in Xcode project
2. XCUITest target configured for UI automation
3. Snapshot testing infrastructure in place (Point-Free SnapshotTesting)
4. Critical UI components have snapshot tests
5. Height/layout issues identified and documented
6. CI-ready test commands work (`swift test` or `xcodebuild test`)

**Plans:** 3 plans

Plans:
- [x] 17.1-01-PLAN.md -- Add SnapshotTesting dependency, create test helpers and mock factories, fix existing tests
- [x] 17.1-02-PLAN.md -- Extract popover height calculator, snapshot tests for leaf views (Header, Detail, FloatingWindow)
- [x] 17.1-03-PLAN.md -- Snapshot tests for composite views (Popover, Settings tabs, ProfileSwitcher)

---

## v4.0 Raycast Integration (Phases 18-21)

**Milestone Goal:** Bring Tokemon's usage monitoring to Raycast as a standalone TypeScript/React extension, reaching developers where they already work.

**Architecture:** Standalone extension fetching data directly via OAuth. Works without Tokemon.app running. New codebase in `raycast-extension/` directory.

**Total Requirements:** 18 | **Phases:** 4

### Phase 18: Extension Foundation

**Goal:** Scaffold a working Raycast extension with credential handling and custom branding
**Depends on:** Nothing (first phase of v4.0)
**Requirements:** EXT-01, EXT-02, EXT-03, EXT-04

**Success Criteria** (what must be TRUE):
1. User can install extension via `npm install && npm run dev`
2. Extension appears in Raycast with Tokemon icon
3. User can enter OAuth token via setup wizard
4. Extension stores credentials securely in Raycast LocalStorage

**Plans:** 2 plans

Plans:
- [x] 18-01-PLAN.md -- Scaffold project, export icon, configure manifest, MIT license, README
- [x] 18-02-PLAN.md -- Setup wizard command, API constants, token validation, stub dashboard

### Phase 19: Dashboard Command

**Goal:** Users can view their Claude usage stats in a Raycast command
**Depends on:** Phase 18
**Requirements:** DASH-01, DASH-02, DASH-03, DASH-04, DASH-05

**Success Criteria** (what must be TRUE):
1. User sees session usage percentage in dashboard
2. User sees weekly usage percentage in dashboard
3. User sees reset countdown timer
4. User sees pace indicator (on track / ahead / behind)
5. User can manually refresh data with Cmd+R

**Plans:** TBD

### Phase 20: Menu Bar Command

**Goal:** Usage percentage persists in Raycast menu bar with automatic refresh
**Depends on:** Phase 19
**Requirements:** MENU-01, MENU-02, MENU-03

**Success Criteria** (what must be TRUE):
1. Usage percentage displays in Raycast menu bar
2. Menu bar updates automatically without user action
3. Menu bar color reflects usage level (green/orange/red)

**Plans:** TBD

### Phase 21: Multi-Profile & Alerts

**Goal:** Power users can manage multiple accounts and configure threshold alerts
**Depends on:** Phase 20
**Requirements:** PROF-01, PROF-02, PROF-03, ALRT-01, ALRT-02, ALRT-03

**Success Criteria** (what must be TRUE):
1. User can add multiple profiles with different OAuth tokens
2. User can switch between profiles
3. User can delete profiles
4. User can configure usage threshold percentage for alerts
5. User receives Raycast notification when threshold is reached
6. User can test alert from settings command

**Plans:** TBD

---

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 17.1. Automated Testing | v3.0+ | 3/3 | ✓ Complete | 2026-02-19 |
| 18. Extension Foundation | v4.0 | 2/2 | ✓ Complete | 2026-02-19 |
| 19. Dashboard Command | v4.0 | 0/TBD | Not started | - |
| 20. Menu Bar Command | v4.0 | 0/TBD | Not started | - |
| 21. Multi-Profile & Alerts | v4.0 | 0/TBD | Not started | - |

## Future Backlog

Ideas discussed but deferred for future milestones:

- **User Accounts + Insights Platform** -- Full account system with rich profile data, telemetry with consent, benchmarks & personalized insights, potentially monetizable data asset. Requires: auth system, backend infrastructure, GDPR compliance. (Discussed 2026-02-16, deferred in favor of shipping clean)

---

*v1.0 shipped: 2026-02-14*
*v2.0 shipped: 2026-02-15*
*v3.0 shipped: 2026-02-17*
*v4.0 roadmap created: 2026-02-18*
