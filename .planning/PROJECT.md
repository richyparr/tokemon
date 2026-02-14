# ClaudeMon

## Current State

**Version:** v1.0 shipped 2026-02-14
**Status:** MVP complete, ready for user feedback

Native macOS menu bar utility for monitoring Claude usage at a glance. Shows live data from OAuth endpoint with JSONL fallback, configurable alerts, usage trends, floating window, and three themes.

**Codebase:** 3,948 LOC Swift | 5 phases | 12 plans

## What This Is

A native macOS app for monitoring Claude usage across all your sources — Claude Code CLI, Claude.ai, and the Claude API. Provides at-a-glance usage stats, limit warnings, and cost tracking through a lightweight, customizable interface. Open source for the Claude community.

## Core Value

**Know your Claude usage at a glance before hitting limits.**

## Requirements

### Validated (v1.0)

- Menu bar app with live OAuth + JSONL data
- Configurable alerts with macOS notifications
- Usage trend visualization with burn rate projections
- Always-on-top floating window
- Three themes (Native, Minimal Dark, Anthropic)
- Settings: refresh interval, data sources, thresholds, launch at login

### Active (v2)

_Not yet defined. Run `/gsd:new-milestone` to plan v2._

### Out of Scope

- Mac App Store distribution — sandbox blocks ~/.claude access
- Real-time Notification Center widget — WidgetKit refresh budget too limiting
- Multi-provider monitoring — Claude-only for best-in-class experience
- Claude.ai scraping — too fragile, using OAuth instead
- iOS app — v2+ consideration
- Web interface — v2+ consideration

## Constraints

- **Tech stack**: Native Swift/SwiftUI — no Electron or web wrappers
- **Platform**: macOS only for v1 (iOS in v2)
- **Distribution**: Open source on GitHub (not App Store)
- **Performance**: Lightweight — minimal CPU/memory footprint for background monitoring

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

---
*Last updated: 2026-02-14 after v1.0 milestone*
