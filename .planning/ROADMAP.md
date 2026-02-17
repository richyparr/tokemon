# Roadmap: Tokemon

## Milestones

- **v1.0 MVP** -- Phases 1-5 (shipped 2026-02-14) -- [Archive](milestones/v1.0-ROADMAP.md)
- **v2.0 Pro Features** -- Phases 6-9 (shipped 2026-02-15) -- [Archive](milestones/v2.0-ROADMAP.md)
- **v3.0 Competitive Parity & Growth** -- Phases 11-17 (in progress)

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

### v3.0 Competitive Parity & Growth (In Progress)

**Milestone Goal:** Match Claude Usage Tracker feature-for-feature in the FREE tier, then differentiate with team/org PRO features that justify the subscription.

- [x] **Phase 11: Multi-Profile Foundation** (3/3 plans) -- completed 2026-02-17
- [ ] **Phase 12: Menu Bar Customization** -- Users can personalize the menu bar icon to match their workflow
- [ ] **Phase 13: Terminal Statusline** -- Users can see Claude usage directly in their terminal prompt
- [ ] **Phase 14: Distribution & Trust** -- Users can install via Homebrew, receive auto-updates, and trust the signed binary
- [ ] **Phase 15: Team Dashboard PRO** -- Team leads can view aggregated org usage in one place
- [ ] **Phase 16: Webhook Alerts PRO** -- Users can receive usage alerts in Slack and Discord
- [ ] **Phase 17: Budget & Forecasting PRO** -- Users can set spending limits and see predicted usage trajectories

## Phase Details

### Phase 11: Multi-Profile Foundation

**Goal:** Users can manage multiple Claude accounts with credential switching, replacing the removed v2.0 multi-account feature with a copy/switch architecture that works with Claude Code's keychain.
**Depends on:** Phase 10 (existing v2.0 codebase)
**Requirements:** PROF-01, PROF-02, PROF-03, PROF-04, PROF-05, PROF-06
**Success Criteria** (what must be TRUE):
  1. User can create a named profile and see it listed in the app
  2. User can sync credentials from the system keychain into a profile and enter manual session keys for secondary accounts
  3. User can switch active profile and the app writes that profile's credentials to the system keychain for Claude Code to use
  4. User can delete a profile they no longer need
  5. User can see usage summaries for all profiles simultaneously in the menu bar popover
**Plans:** 3 plans in 3 waves

Plans:
- [ ] 11-01-PLAN.md -- Profile model and ProfileManager service with copy/switch keychain operations (Wave 1)
- [ ] 11-02-PLAN.md -- Profile management UI (Settings tab + popover switcher) and app integration (Wave 2)
- [ ] 11-03-PLAN.md -- Multi-profile usage polling and simultaneous usage display in popover (Wave 3)

---

### Phase 12: Menu Bar Customization

**Goal:** Users can personalize the menu bar icon style and color to match their preferences and see usage status at a glance without opening the popover.
**Depends on:** Phase 10 (existing v2.0 codebase)
**Requirements:** MENU-01, MENU-02, MENU-03
**Success Criteria** (what must be TRUE):
  1. User can choose from 5 distinct icon styles (battery, progress bar, percentage text, icon+bar, compact) in Settings
  2. User can toggle monochrome mode so the icon blends with the native macOS menu bar
  3. Menu bar icon color automatically shifts from green to orange to red as usage increases
**Plans:** TBD

Plans:
- [ ] 12-01: TBD

---

### Phase 13: Terminal Statusline

**Goal:** Users can see their Claude usage directly in their terminal prompt, giving Claude Code users at-a-glance awareness without switching to the menu bar.
**Depends on:** Phase 10 (existing v2.0 codebase)
**Requirements:** TERM-01, TERM-02, TERM-03, TERM-04
**Success Criteria** (what must be TRUE):
  1. User can display session %, weekly %, and reset timer in their bash/zsh prompt
  2. User can customize the statusline format (choose which fields to show, adjust separators/colors)
  3. User can install the statusline integration with a single command (one-click install script)
**Plans:** TBD

Plans:
- [ ] 13-01: TBD
- [ ] 13-02: TBD

---

### Phase 14: Distribution & Trust

**Goal:** Users can install Tokemon via Homebrew, trust the code-signed and notarized binary, and receive automatic updates -- establishing distribution parity with competing tools.
**Depends on:** Phase 11, Phase 12, Phase 13 (all FREE features complete before distribution)
**Requirements:** DIST-01, DIST-02, DIST-03, DIST-04, DIST-05, AUTO-01
**Success Criteria** (what must be TRUE):
  1. User can install Tokemon via `brew install tokemon` from a Homebrew tap
  2. App opens without macOS Gatekeeper warnings (signed + notarized)
  3. App checks for updates on launch and user can install updates from within the app
  4. User sees in-app notification when a new version is available
  5. User can enable auto-start of a new session when their usage resets to 0%
**Plans:** TBD

Plans:
- [ ] 14-01: TBD
- [ ] 14-02: TBD

---

### Phase 15: Team Dashboard PRO

**Goal:** Team leads and org admins can view aggregated usage across all org members, enabling proactive capacity management.
**Depends on:** Phase 14 (distribution pipeline established for PRO features)
**Requirements:** TEAM-01, TEAM-02, TEAM-03
**Success Criteria** (what must be TRUE):
  1. User can view a dashboard showing total org-wide Claude usage aggregated from the Admin API
  2. User can drill down to see per-member usage breakdown
  3. User can filter the team dashboard by date range to analyze usage over specific periods
**Plans:** TBD

Plans:
- [ ] 15-01: TBD
- [ ] 15-02: TBD

---

### Phase 16: Webhook Alerts PRO

**Goal:** Users can receive Claude usage alerts directly in Slack and Discord channels, enabling team-wide awareness without everyone needing the app open.
**Depends on:** Phase 15 (team context established)
**Requirements:** HOOK-01, HOOK-02, HOOK-03, HOOK-04
**Success Criteria** (what must be TRUE):
  1. User can configure a Slack webhook URL in Settings and receive threshold alerts in their Slack channel
  2. User can configure a Discord webhook URL in Settings and receive threshold alerts in their Discord channel
  3. User can customize the webhook message format (choose fields, adjust template)
**Plans:** TBD

Plans:
- [ ] 16-01: TBD
- [ ] 16-02: TBD

---

### Phase 17: Budget & Forecasting PRO

**Goal:** Users can set dollar-based spending limits and see ML-driven usage predictions, turning reactive monitoring into proactive budget management.
**Depends on:** Phase 15 (team dashboard provides cost data foundation)
**Requirements:** BUDG-01, BUDG-02, BUDG-03, BUDG-04, FORE-01, FORE-02, FORE-03
**Success Criteria** (what must be TRUE):
  1. User can set a monthly dollar budget limit and see current spend vs. budget as a visual gauge
  2. User receives alerts at 50%, 75%, and 90% of their budget threshold
  3. User can see cost attribution broken down by project
  4. User sees a predicted time-to-limit based on historical usage patterns, with an "on pace" / "ahead" / "behind" indicator
  5. Prediction updates in real-time as usage changes throughout the day
**Plans:** TBD

Plans:
- [ ] 17-01: TBD
- [ ] 17-02: TBD
- [ ] 17-03: TBD

---

## Progress

**Execution Order:**
Phases 11-13 can be built in parallel (independent FREE features). Phase 14 follows all FREE features. Phases 15-17 are sequential PRO features.

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation & Core Monitoring | v1.0 | 3/3 | Complete | 2026-02-12 |
| 2. Alerts & Notifications | v1.0 | 2/2 | Complete | 2026-02-13 |
| 3. Usage Trends & API Integration | v1.0 | 3/3 | Complete | 2026-02-13 |
| 4. Floating Window | v1.0 | 2/2 | Complete | 2026-02-14 |
| 5. Theming & Design Polish | v1.0 | 2/2 | Complete | 2026-02-14 |
| 6. Licensing Foundation | v2.0 | 3/3 | Complete | 2026-02-14 |
| 7. Multi-Account | v2.0 | 3/3 | Complete | 2026-02-14 |
| 8. Analytics & Export | v2.0 | 3/3 | Complete | 2026-02-15 |
| 9. Shareable Moments | v2.0 | 2/2 | Complete | 2026-02-15 |
| 10. Enhanced Export | Post-v2.0 | 3/3 | Complete | 2026-02-16 |
| 11. Multi-Profile Foundation | v3.0 | 3/3 | Complete | 2026-02-17 |
| 12. Menu Bar Customization | v3.0 | 0/0 | Not started | - |
| 13. Terminal Statusline | v3.0 | 0/0 | Not started | - |
| 14. Distribution & Trust | v3.0 | 0/0 | Not started | - |
| 15. Team Dashboard PRO | v3.0 | 0/0 | Not started | - |
| 16. Webhook Alerts PRO | v3.0 | 0/0 | Not started | - |
| 17. Budget & Forecasting PRO | v3.0 | 0/0 | Not started | - |

---

## Future Backlog

Ideas discussed but deferred for future milestones:

- **User Accounts + Insights Platform** -- Full account system with rich profile data, telemetry with consent, benchmarks & personalized insights, potentially monetizable data asset. Requires: auth system, backend infrastructure, GDPR compliance. (Discussed 2026-02-16, deferred in favor of shipping clean)

---

*v1.0 shipped: 2026-02-14*
*v2.0 shipped: 2026-02-15*
*v3.0 roadmap created: 2026-02-17*
