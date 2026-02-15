# ClaudeMon

## Current State

**Version:** v2.0 shipped 2026-02-15
**Status:** Feature complete, planning v3

Native macOS menu bar utility for monitoring Claude usage with live OAuth data, multi-account support, extended analytics, Pro licensing, and shareable usage cards.

**Codebase:** 7,706 LOC Swift | 9 phases | 23 plans

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
- Multi-account (add/switch/manage/remove accounts)
- Per-account alert thresholds
- Combined usage summary across accounts
- Weekly and monthly usage summaries
- 30-day and 90-day usage history
- Project/folder breakdown
- PDF and CSV export
- Shareable usage cards with clipboard copy

### Active (v3)

_None defined yet. Run `/gsd:new-milestone` to start v3 planning._

### Out of Scope

- Mac App Store distribution — sandbox blocks ~/.claude access
- Real-time Notification Center widget — WidgetKit refresh budget too limiting
- Multi-provider monitoring — Claude-only for best-in-class experience
- Claude.ai scraping — too fragile, using OAuth instead
- Open source — closed source for monetization

### Deferred (v3+)

- iOS companion app
- Web interface
- Raycast/Alfred extensions

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

---
*Last updated: 2026-02-15 after v2.0 milestone*
