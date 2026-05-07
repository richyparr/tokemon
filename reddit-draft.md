**Title:** Tokemon — open-source Claude usage monitor for macOS with project breakdowns, budget tracking, PDF reports, and Slack/Discord alerts

**Body:**

I kept getting rate-limited mid-flow with zero warning, so I built Tokemon. There are other menu bar tools that show a percentage — Tokemon does that too, but it goes a lot further.

**Real-time monitoring**
- Usage percentage lives in your menu bar (5 icon styles — percentage, battery, progress bar, etc.)
- Always-on-top floating window you can keep in the corner while you work
- Burn rate calculation — tells you how many hours/minutes you have left at your current pace
- Session reset notifications so you know the moment you can get back to work

**Analytics & reporting**
- Usage history charts over 7, 30, 90 days
- Project-by-project token breakdown (input, output, cache tokens)
- Weekly and monthly usage summaries with averages and peaks
- Export to PDF, CSV, or shareable PNG usage cards

**Budget tracking** (Admin API)
- Set monthly dollar limits with visual gauge
- Cost forecasting — predicts your month-end spend based on daily burn
- Auto-alerts at 50%, 75%, 90% of budget
- Cost breakdown by project/workspace

**Team management** (Admin API)
- See all team members and their individual usage
- Organization-wide metrics — total tokens, total cost
- Filter by time period

**Alerts & integrations**
- macOS system notifications at configurable thresholds
- Slack webhook alerts with Block Kit formatting
- Discord webhook alerts with embeds
- Terminal statusline integration — pipe usage into your shell prompt
- JSON status file for custom script integrations

**Multi-profile support**
- Switch between personal and work accounts instantly
- Per-profile alert thresholds and webhook settings

**Privacy-first**
- Everything runs locally. No cloud, no telemetry, no account required.
- Open source (MIT) — read the code or build it yourself
- Credentials stay in your macOS Keychain

Install: `brew install richyparr/tokemon/tokemon`
Website: tokemon.ai
GitHub: github.com/richyparr/tokemon
