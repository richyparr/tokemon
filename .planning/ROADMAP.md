# Roadmap: Tokemon

## Milestones

- **v1.0 MVP** -- Phases 1-5 (shipped 2026-02-14) -- [Archive](milestones/v1.0-ROADMAP.md)
- **v2.0 Pro Features** -- Phases 6-9 (shipped 2026-02-15) -- [Archive](milestones/v2.0-ROADMAP.md)
- **v3.0 Competitive Parity & Growth** -- Phases 11-17 (shipped 2026-02-17) -- [Archive](milestones/v3.0-ROADMAP.md)
- **v4.0 Raycast Integration** -- Phases 18-21 (shipped 2026-02-24) -- [Archive](milestones/v4.0-ROADMAP.md)

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

<details>
<summary>v3.0+ Automated Testing (Phase 17.1) -- COMPLETE 2026-02-19</summary>

- [x] Phase 17.1: Automated Testing (3/3 plans) -- completed 2026-02-19

</details>

<details>
<summary>v4.0 Raycast Integration (Phases 18-21) -- SHIPPED 2026-02-24</summary>

- [x] Phase 18: Extension Foundation (2/2 plans) -- completed 2026-02-19
- [x] Phase 19: Dashboard Command (2/2 plans) -- completed 2026-02-22
- [x] Phase 20: Menu Bar Command (1/1 plan) -- completed 2026-02-22
- [x] Phase 21: Multi-Profile & Alerts (2/2 plans) -- completed 2026-02-24

See [v4.0-ROADMAP.md](milestones/v4.0-ROADMAP.md) for full details.

</details>

---

### Phase 22: Security Hardening

**Goal:** Harden security posture by moving profile credentials from UserDefaults to Keychain, sanitizing error logging, enforcing HTTPS-only webhook URLs, evaluating app sandboxing, and resolving Keychain write-back conflicts with Claude Code.
**Depends on:** Phase 21
**Plans:** 2 plans

Plans:
- [ ] 22-01-PLAN.md -- Migrate profile credentials to Keychain, disable TokenManager write-back
- [ ] 22-02-PLAN.md -- Replace print() with OSLog.Logger, enforce HTTPS webhooks, document sandboxing

---

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 17.1. Automated Testing | v3.0+ | 3/3 | ✓ Complete | 2026-02-19 |
| 18. Extension Foundation | v4.0 | 2/2 | ✓ Complete | 2026-02-19 |
| 19. Dashboard Command | v4.0 | 2/2 | ✓ Complete | 2026-02-22 |
| 20. Menu Bar Command | v4.0 | 1/1 | ✓ Complete | 2026-02-22 |
| 21. Multi-Profile & Alerts | v4.0 | 2/2 | ✓ Complete | 2026-02-24 |
| 22. Security Hardening | - | 0/2 | Planned | - |

## Future Backlog

Ideas discussed but deferred for future milestones:

- **User Accounts + Insights Platform** -- Full account system with rich profile data, telemetry with consent, benchmarks & personalized insights, potentially monetizable data asset. Requires: auth system, backend infrastructure, GDPR compliance. (Discussed 2026-02-16, deferred in favor of shipping clean)

---

*v1.0 shipped: 2026-02-14*
*v2.0 shipped: 2026-02-15*
*v3.0 shipped: 2026-02-17*
*v4.0 shipped: 2026-02-24*
