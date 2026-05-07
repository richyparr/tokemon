---
name: Tokemon SEO Product Brief
description: Foundation document for all SEO work on tokemon.ai — product, personas, value props, buyer language
created: 2026-05-07
target_domain: tokemon.ai
target_country: global (primary: us, secondary: gb, au)
---

# Tokemon — SEO Product Brief

## One-sentence description
A free, open-source macOS menu bar (and Raycast) app that monitors Claude API/Code usage in real time — burn rate, per-project costs, budget forecasts — so developers never hit a rate limit by surprise.

## Core features
- **Menu bar monitor** — live usage % with traffic-light/percentage/battery/progress-bar/icon+bar/compact icon styles
- **Burn rate tracking** — tokens-per-hour with trend, ETA to limit reset
- **Per-project cost breakdown** — auto-detects which projects/codebases consumed tokens via JSONL log parsing
- **Budget forecasting** — monthly limits, cost forecasts, 50/75/90% alerts
- **Team analytics** — org-wide cost via Admin API, member-by-member breakdown
- **Smart alerts** — configurable thresholds, Slack/Discord webhooks, macOS notifications
- **Floating window** — always-on-top compact panel (5h session, 7d rolling, 7d Sonnet)
- **Raycast extension** — usage dashboard + menu bar in Raycast launcher
- **Terminal statusline** — `~/.tokemon/statusline` for zsh/bash with ANSI colors
- **Multi-profile support** — multiple accounts, independent credentials & alerts
- **Export & reporting** — PDF / CSV / JSON, 30/90-day history, shareable usage cards
- **Sparkle auto-updates**, signed + notarized

## Target personas
1. **Claude Code power users** on Pro/Team/Enterprise who code daily with Claude and need rate-limit visibility
2. **Freelancers/agencies** billing clients for token usage who need per-project breakdowns
3. **Team leads & engineering managers** managing org-wide Claude spend with budget constraints
4. **AI power users** who treat Claude as their primary tool and want to pace their work

## Value propositions (verbatim where possible)
- "Never hit a rate limit by surprise again"
- "Track session limits, burn rate, project costs, and team budgets in real-time"
- "Know your tokens-per-hour rate and whether it is trending up or down"
- "Estimates exactly when you'll hit your limit at the current pace"
- "No API keys to configure, no manual setup. Just install and go"
- "All data stored locally on your Mac. No telemetry, tracking, or third-party services"
- "Save 7–15 hours per month vs manual spreadsheet tracking"
- "Show that 'refchecks' used 1.2B tokens" (per-project billing)

## Pricing & distribution
- **Free + open source (MIT)**
- Channels: Homebrew (`brew install --cask richyparr/tokemon/tokemon`), GitHub releases (.zip), Raycast Store, build from source
- Requires: macOS 26.0 (Tahoe)+, Claude Pro/Team/Enterprise
- Signed with Apple Developer ID + notarized

## Buyer/user language (verbatim)
- "Claude Code usage monitor"
- "Never hit a rate limit by surprise"
- "Flying blind with Claude Code"
- "Burning through tokens with no idea when you'll hit the wall"
- "Real-time visibility into your usage trend"
- "Track token limits, burn rate, per-project costs, and team budgets"
- "Built for developers who ship with Claude"
- "Loved by developers who ship with Claude"

## Competitive positioning
| Against | Tokemon's pitch |
|---------|----------------|
| Manual tracking / spreadsheets | Saves 15–30 min/day, automated, catches spikes |
| ClaudeBar | Deep analytics vs lightweight; per-project, burn rate, team, Raycast, terminal, export |
| Claude Console | Console has no built-in usage left, no token counter, vague warnings |
| Manual API header parsing | Auto-reads from Keychain/OAuth, no config |

Differentiators: Claude-specific, power-user focus, deep analytics, Raycast-native, open source, team features.

## Existing content inventory (tokemon.ai)
- `/` — homepage
- `/blog` — index
- `/blog/[slug]` — 8 posts: how-to-track-claude-code-usage, avoid-claude-rate-limits, claude-token-monitoring-guide, reduce-claude-api-costs, claude-rate-limits-explained, claude-code-cost-calculator, best-claude-code-tools, claude-max-vs-pro-vs-team
- `/blog/tag/[tag]`
- `/compare` — hub
- `/compare/[slug]` — 4 comparisons: tokemon-vs-manual-tracking, tokemon-vs-claudebar, tokemon-vs-ccusage, tokemon-vs-claude-console
- **Missing pages:** /pricing, /about, /docs, /help, /download, /changelog
