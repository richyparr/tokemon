# Milestones: Tokemon

## Shipped

### v1.0 MVP (2026-02-14)

**Phases:** 1-5 | **Plans:** 12 | **Requirements:** 43

Native macOS menu bar utility for monitoring Claude usage at a glance. Live data from OAuth endpoint with JSONL fallback, configurable alerts, usage trend visualization, always-on-top floating window, and three customizable themes.

**Key Accomplishments:**
- Menu bar app with live usage data from OAuth endpoint + JSONL fallback
- macOS system notifications with configurable thresholds and launch at login
- Swift Charts visualization with burn rate calculator and time-to-limit projection
- Always-on-top floating window with compact usage display
- Three customizable themes (Native, Minimal Dark, Anthropic)

**Stats:** 3,948 LOC Swift | 3 days (Feb 11-14)

**Archive:** [v1.0-ROADMAP.md](milestones/v1.0-ROADMAP.md) | [v1.0-REQUIREMENTS.md](milestones/v1.0-REQUIREMENTS.md)

---

### v2.0 Pro Features (2026-02-15)

**Phases:** 6-9 | **Plans:** 11 | **Requirements:** 20

Transform Tokemon into a paid product with licensing, multi-account support, extended analytics, and viral sharing features.

**Key Accomplishments:**
- LemonSqueezy licensing integration with 2-week trial, Pro subscription, and offline/grace period support
- Multi-account support with account CRUD, switching, and per-account alert settings
- Extended analytics with 90-day history, hourly downsampling, weekly/monthly summaries, and project breakdown
- PDF and CSV export functionality for usage reports
- Shareable usage cards with Tokemon branding for viral marketing

**Stats:** 7,706 LOC Swift | 2 days (Feb 14-15)

**Archive:** [v2.0-ROADMAP.md](milestones/v2.0-ROADMAP.md) | [v2.0-REQUIREMENTS.md](milestones/v2.0-REQUIREMENTS.md)

---

## In Progress

### v3.0 Competitive Parity & Growth

**Phases:** 11-17 | **Plans:** TBD | **Requirements:** 33

Match Claude Usage Tracker (1.2k stars) feature-for-feature in FREE tier, then differentiate with team/org PRO features.

**FREE Tier (Competitive Parity):**
- Phase 11: Multi-profile support (copy/switch credential architecture)
- Phase 12: Menu bar icon customization (5 styles)
- Phase 13: Terminal statusline integration for Claude Code
- Phase 14: Distribution & trust (Homebrew, code signing, Sparkle auto-updates)

**PRO Tier (Differentiation):**
- Phase 15: Team dashboard (aggregate org usage via Admin API)
- Phase 16: Slack/Discord webhook alerts
- Phase 17: Budget tracking + usage forecasting

**Roadmap:** [ROADMAP.md](ROADMAP.md)
