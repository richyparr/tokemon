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

### v3.0 Competitive Parity & Growth (2026-02-17)

**Phases:** 11-17 | **Plans:** 17 | **Requirements:** 33

Match Claude Usage Tracker feature-for-feature in FREE tier, then differentiate with team/org PRO features.

**Key Accomplishments:**
- Multi-profile support with copy/switch credential architecture
- Menu bar icon customization (5 styles) with monochrome mode
- Terminal statusline integration for Claude Code (bash/zsh)
- Distribution & trust (Homebrew tap, code signing, notarization, Sparkle)
- Team dashboard PRO (org-wide usage via Admin API)
- Slack/Discord webhook alerts PRO
- Budget tracking + usage forecasting PRO

**Stats:** 14,418 LOC Swift | 1 day (Feb 17)

**Archive:** [v3.0-ROADMAP.md](milestones/v3.0-ROADMAP.md) | [v3.0-REQUIREMENTS.md](milestones/v3.0-REQUIREMENTS.md)

---

## In Progress

### v4.0 Raycast Integration

**Phases:** 18+ | **Plans:** TBD | **Requirements:** TBD

Bring Tokemon's usage monitoring to Raycast as a standalone extension.

**Target Features:**
- Usage dashboard command (session %, weekly %, reset timer)
- Menu bar integration
- Alert configuration commands
- Profile switching from Raycast

**Architecture:** Standalone — fetches data directly via OAuth, no Tokemon.app required.

**Roadmap:** [ROADMAP.md](ROADMAP.md)
