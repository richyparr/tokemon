# ClaudeMon

## What This Is

A native macOS app for monitoring Claude usage across all your sources — Claude Code CLI, Claude.ai, and the Claude API. Provides at-a-glance usage stats, limit warnings, and cost tracking through a lightweight, customizable interface. Open source for the Claude community.

## Core Value

**Know your Claude usage at a glance before hitting limits.**

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Monitor usage from Claude Code CLI
- [ ] Monitor usage from Claude.ai
- [ ] Monitor usage from Claude API
- [ ] Display in menu bar app (click to expand)
- [ ] Display in Notification Center widget
- [ ] Display as floating window
- [ ] Show current usage (tokens/messages in period)
- [ ] Show limits remaining
- [ ] Show cost tracking (API usage)
- [ ] Show usage trends over time
- [ ] Theme: Native macOS
- [ ] Theme: Minimal dark
- [ ] Theme: Anthropic-inspired
- [ ] Visual indicators when approaching limits (color change/warning icon)
- [ ] macOS notifications when approaching limits (optional)
- [ ] User can enable/disable each data source independently

### Out of Scope

- Web interface — v2+
- iOS app — v2+
- Agent tracking — v2+ analytics
- Per-call cost breakdown — v2+ analytics
- Model suggestions — v2+ analytics
- Tips for lowering usage — v2+ analytics
- Mac App Store distribution — open source via GitHub

## Context

**Problem:** Claude users across CLI, web, and API have no unified way to see their usage. Limits get hit unexpectedly, costs accumulate invisibly, and there's no way to track patterns over time.

**Target users:** Claude power users who use multiple interfaces (especially Claude Code developers) and want visibility into their usage.

**Data sources to research:**
- Claude Code CLI: Likely local logs/state files
- Claude.ai: May require scraping or may have undocumented endpoints
- Claude API: Has usage/billing endpoints via Anthropic API

**macOS integration points:**
- Menu bar: Standard status item pattern
- Notification Center: WidgetKit (iOS 14+ / macOS 11+)
- Floating window: NSPanel or NSWindow with appropriate level

## Constraints

- **Tech stack**: Native Swift/SwiftUI — no Electron or web wrappers
- **Platform**: macOS only for v1 (iOS in v2)
- **Distribution**: Open source on GitHub (not App Store)
- **Performance**: Lightweight — minimal CPU/memory footprint for background monitoring

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Swift/SwiftUI over Electron | True native performance, proper widget support, macOS integration | — Pending |
| Three display modes in v1 | User requested all modes from start | — Pending |
| Core monitoring before analytics | Ship usable v1 faster, add analytics in v2 | — Pending |
| Open source distribution | Community benefit, no App Store constraints | — Pending |

---
*Last updated: 2026-02-11 after initialization*
