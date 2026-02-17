# Tokemon

## Current State

**Version:** v2.0 shipped 2026-02-15 (multi-account removed post-ship)
**Status:** Planning v3.0 — Competitive Parity & Growth

Native macOS menu bar utility for monitoring Claude usage with live OAuth data, extended analytics, Pro licensing, and shareable usage cards.

**Codebase:** 7,706 LOC Swift | 10 phases | 26 plans

## Current Milestone: v3.0 Competitive Parity & Growth

**Goal:** Match Claude Usage Tracker (1.2k stars) feature-for-feature in FREE tier, then differentiate with team/org PRO features.

**FREE tier (competitive parity):**
- Multi-profile support (copy/switch credential architecture)
- Menu bar icon customization (5 styles)
- Terminal statusline integration for Claude Code
- Homebrew tap distribution
- Apple Developer code signing + notarization
- Sparkle auto-updates
- Auto-start sessions on reset

**PRO tier (differentiation):**
- Team dashboard (aggregate org usage via Admin API)
- Slack/Discord webhook alerts
- Budget tracking with $ limits
- Usage forecasting (ML-based limit predictions)

## What This Is

A native macOS app for monitoring Claude usage across all your sources — Claude Code CLI, Claude.ai, and the Claude API. Provides at-a-glance usage stats, limit warnings, cost tracking, and extended analytics through a lightweight, customizable interface. Paid Pro features with 2-week trial.

## Core Value

**Know your Claude usage at a glance before hitting limits.**

## Requirements

### Validated

**v1.0 (shipped 2026-02-14):**
- Menu bar app with live OAuth + JSONL data
- Configurable alerts with macOS notifications
- Usage trend visualization with burn rate projections
- Always-on-top floating window
- Three themes (Native, Minimal Dark, Anthropic)
- Settings: refresh interval, data sources, thresholds, launch at login

**v2.0 (shipped 2026-02-15):**
- LemonSqueezy licensing with 2-week trial, Pro subscription, offline/grace support
- ~~Multi-account (add/switch/manage/remove accounts)~~ — removed post-ship (Claude Code keychain architecture)
- Weekly and monthly usage summaries
- 30-day and 90-day usage history
- Project/folder breakdown
- PDF and CSV export
- Shareable usage cards with clipboard copy

### Active (v3.0)

**FREE Tier:**
- [ ] Multi-profile support with credential copy/switch
- [ ] Menu bar icon customization (5 styles)
- [ ] Terminal statusline integration
- [ ] Homebrew tap distribution
- [ ] Apple Developer code signing
- [ ] Sparkle auto-updates
- [ ] Auto-start sessions on usage reset

**PRO Tier:**
- [ ] Team dashboard (org-wide usage aggregation)
- [ ] Slack/Discord webhook alerts
- [ ] Budget tracking with $ limits
- [ ] Usage forecasting

### Out of Scope

- Mac App Store distribution — sandbox blocks ~/.claude access
- Real-time Notification Center widget — WidgetKit refresh budget too limiting
- Multi-provider monitoring (Copilot, Cursor, Gemini) — Claude-only for best-in-class experience
- Claude.ai scraping — too fragile, using OAuth instead
- Open source — closed source for monetization
- iOS companion app — deferred to v4+

### Deferred (v4+)

- Web dashboard interface
- Raycast/Alfred extensions
- Localization (8 languages)

## Constraints

- **Tech stack**: Native Swift/SwiftUI — no Electron or web wrappers
- **Platform**: macOS only (iOS deferred to v3)
- **Distribution**: Paid via GitHub + LemonSqueezy (not App Store)
- **Performance**: Lightweight — minimal CPU/memory footprint for background monitoring
- **Monetization**: $3/mo or $29/yr subscription with 2-week trial

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Swift/SwiftUI over Electron | True native performance, proper widget support, macOS integration | Good |
| OAuth endpoint as primary | More reliable than scraping, provides percentage data | Good |
| JSONL fallback | Works when OAuth unavailable, shows token counts | Good |
| SPM executable target | Xcode not required for builds | Good |
| Custom SettingsWindowController | SwiftUI Settings scene broken in LSUIElement apps | Good |
| Actor for HistoryStore | Swift concurrency native, no DispatchQueue needed | Good |
| ThemeColors semantic resolution | Themes can adapt to system light/dark mode | Good |
| Three display modes (menu bar, floating, trends) | User requested all modes from start | Good |
| @preconcurrency import for LemonSqueezy | Swift 6 Sendable compliance for third-party library | Good |
| Separate keychain service for accounts | Never modifies Claude Code's credentials keychain | Good |
| HMAC-signed trial storage | Prevents casual date tampering | Good |
| Hourly downsampling for 90-day history | Reduces storage from ~25MB to ~2.4MB per account | Good |
| Solid colors only in ImageRenderer views | Workaround for macOS gradient rendering bug | Good |
| NSSavePanel standalone presentation | LSUIElement apps have no reliable key window | Good |

| Multi-profile via copy/switch | Claude Usage Tracker approach — copy credentials to app storage, write back on switch | — Pending |
| Homebrew tap for distribution | Developer trust requirement, industry standard | — Pending |
| Apple code signing | User security requirement, enables notarization | — Pending |

---
*Last updated: 2026-02-17 after v3.0 milestone start*
