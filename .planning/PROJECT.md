# Tokemon

## Current State

**Version:** v4.0 shipped 2026-02-24
**Status:** v4.0 complete — planning next steps

Native macOS menu bar utility + Raycast extension for monitoring Claude usage with live OAuth data, extended analytics, Pro licensing, multi-profile support, terminal statusline, and team features.

**Codebase:** 14,418 LOC Swift + 1,453 LOC TypeScript/React | 21 phases | 50 plans

<details>
<summary>v4.0 Raycast Integration (shipped 2026-02-24)</summary>

**Raycast Extension (standalone, no Tokemon.app dependency):**
- [x] Usage dashboard command (session %, weekly %, reset timer, pace indicator)
- [x] Menu bar integration (colored icon, 5-min background refresh)
- [x] Alert configuration (threshold settings, showHUD notifications, per-window dedup)
- [x] Profile switching (add/switch/delete, cross-command sync)
- [x] Setup wizard with token validation

**Architecture:** TypeScript/React with @raycast/api. OAuth token via password preference. vitest for testing (48 tests).

</details>

<details>
<summary>v3.0 Competitive Parity & Growth (shipped 2026-02-17)</summary>

**FREE tier (competitive parity):**
- [x] Multi-profile support (copy/switch credential architecture)
- [x] Menu bar icon customization (5 styles)
- [x] Terminal statusline integration for Claude Code
- [x] Homebrew tap distribution
- [x] Apple Developer code signing + notarization
- [x] Sparkle auto-updates
- [x] Auto-start sessions on reset

**PRO tier (differentiation):**
- [x] Team dashboard (aggregate org usage via Admin API)
- [x] Slack/Discord webhook alerts
- [x] Budget tracking with $ limits
- [x] Usage forecasting (pace indicators, time-to-limit predictions)

</details>

## What This Is

A native macOS app and Raycast extension for monitoring Claude usage across all your sources — Claude Code CLI, Claude.ai, and the Claude API. Provides at-a-glance usage stats, limit warnings, cost tracking, and extended analytics through a lightweight, customizable interface. Paid Pro features with 2-week trial. Raycast extension works standalone without Tokemon.app.

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

**v3.0 (shipped 2026-02-17):**
- Multi-profile, menu bar customization, terminal statusline, Homebrew, code signing, Sparkle, auto-start (FREE)
- Team dashboard, webhooks, budget tracking, forecasting (PRO)

**v4.0 (shipped 2026-02-24):**
- Raycast extension with dashboard, menu bar, profiles, and alerts
- 18/18 requirements complete

### Active

None — between milestones.

### Out of Scope

- Mac App Store distribution — sandbox blocks ~/.claude access
- Real-time Notification Center widget — WidgetKit refresh budget too limiting
- Multi-provider monitoring (Copilot, Cursor, Gemini) — Claude-only for best-in-class experience
- Claude.ai scraping — too fragile, using OAuth instead
- Open source — closed source for monetization

### Deferred

- Web dashboard interface
- Alfred extension
- Localization (8 languages)
- iOS companion app

## Constraints

- **Tech stack**: Native Swift/SwiftUI (macOS app) + TypeScript/React (Raycast extension)
- **Platform**: macOS only (iOS deferred)
- **Distribution**: Paid via GitHub + LemonSqueezy (not App Store); Raycast via Store
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
| Multi-profile via copy/switch | Claude Usage Tracker approach — copy credentials to app storage, write back on switch | Good |
| Homebrew tap for distribution | Developer trust requirement, industry standard | Good |
| Apple code signing | User security requirement, enables notarization | Good |
| ForecastingEngine static methods | Follows BurnRateCalculator pattern — stateless, testable | Good |
| Custom ArcShape gauge | Full visual control vs system Gauge, 270-degree arc | Good |
| Standalone Raycast extension | No Tokemon.app dependency — works independently via OAuth | Good |
| Password preference for token | Keychain access causes Raycast Store rejection | Good |
| vitest over jest | Zero-config TypeScript, ESM-native, lightweight | Good |
| useCachedState for profile sync | Cross-command sync without LocalStorage polling | Good |
| showHUD for background alerts | More visible than Toast during background refresh | Good |
| Memoized TokenSource | Prevents useCachedPromise re-triggering on render | Good |

---
*Last updated: 2026-02-24 after v4.0 milestone shipped*
