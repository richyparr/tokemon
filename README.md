# Tokemon

A macOS menu bar app that monitors your Claude AI usage in real-time so you never hit a rate limit by surprise.

![macOS 14+](https://img.shields.io/badge/macOS-14.0%2B-blue)
![Swift 6](https://img.shields.io/badge/Swift-6.0-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## What it does

Tokemon sits in your menu bar and shows your current Claude usage at a glance. It reads your session data automatically — no API keys to configure, no manual setup. Just install and go.

**Who it's for:** Developers on Claude Pro, Team, or Enterprise plans who use Claude Code or claude.ai and want to keep an eye on their rate limits.

## Features

### Menu bar monitoring
- Live usage percentage in your menu bar with color-coded severity (green/orange/red)
- 5 icon styles: percentage text, battery, progress bar, icon + bar, compact number
- Optional monochrome mode to match native macOS menu bar styling
- Click to see detailed usage breakdown with reset timer

### Floating window
- Always-on-top compact window showing usage percentage
- Configurable rows: 5-hour session, 7-day rolling, 7-day Sonnet
- Remembers position between sessions
- Toggle from the right-click context menu

### Alerts & notifications
- Configurable warning thresholds (50–90%)
- macOS system notifications when approaching limits
- Session reset notifications when usage drops back to 0%
- Webhook alerts to **Slack** and **Discord** with customizable templates

### Multi-profile support
- Manage multiple Claude accounts/profiles
- Switch between profiles from the popover
- Per-profile alert thresholds
- Credentials synced from system Keychain or entered manually

### Analytics & export
- Usage trend charts with burn rate calculation
- 30/90-day usage history
- Project-by-project token breakdown (via Claude Code JSONL logs)
- Export to PDF, CSV, or shareable usage cards

### Budget tracking (Admin API)
- Organization admins can connect an Admin API key
- Monthly budget gauge with cost forecasting
- Per-project cost breakdown
- Auto-alerts at 50%, 75%, 90% of budget
- Team member usage visibility

### Terminal integration
- Export usage to `~/.tokemon/statusline` for shell prompt integration
- JSON status at `~/.tokemon/status.json` for custom scripts
- Configurable format with ANSI colors
- One-click shell integration (zsh/bash)

### Theming
- Native (follows system light/dark), Light, or Dark theme
- Dark theme uses warm Anthropic-inspired orange accents

## Installation

### Download (recommended)

1. Download `Tokemon.zip` from the [latest release](https://github.com/richyparr/tokemon/releases/latest)
2. Unzip and move `Tokemon.app` to `/Applications`
3. The app is not yet notarized, so you need to remove the quarantine flag:
   ```bash
   xattr -cr /Applications/Tokemon.app
   ```
4. Double-click to open

### Build from source

Requires Xcode 15+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
git clone https://github.com/richyparr/tokemon.git
cd tokemon
xcodegen generate
xcodebuild build -scheme Tokemon -destination 'platform=macOS,arch=arm64' -configuration Release
```

The built app will be in your Xcode DerivedData directory.

## How it works

Tokemon reads your Claude usage through two data sources:

1. **OAuth API** (primary) — Queries Anthropic's usage endpoint using credentials from your macOS Keychain. This gives you accurate 5-hour session percentages, 7-day rolling usage, and reset timers. Credentials are picked up automatically if you're signed into Claude Code.

2. **JSONL logs** (fallback) — Parses Claude Code's local conversation logs in `~/.claude/projects/` to estimate token usage when OAuth isn't available.

No data leaves your machine except API calls to Anthropic's own endpoints. No telemetry, no analytics, no accounts.

## Requirements

- macOS 14.0 (Sonoma) or later
- A Claude Pro, Team, or Enterprise subscription
- For budget/team features: an Anthropic Admin API key

## Settings

Right-click the menu bar icon or press Cmd+, to access settings:

| Tab | What it configures |
|-----|--------------------|
| **Profiles** | Add/manage Claude accounts, sync from Keychain |
| **General** | Refresh interval, data sources, launch at login |
| **Appearance** | Theme, menu bar icon style, monochrome mode |
| **Notifications** | Alert thresholds, Slack/Discord webhooks |
| **Terminal** | Statusline export format, shell integration |
| **Analytics** | Usage history charts, PDF/CSV export |
| **Budget** | Monthly spending limits, cost forecasting |
| **Admin** | Admin API key connection |

## Privacy

- All data is stored locally on your Mac
- Credentials are stored in the macOS Keychain
- The only network calls are to `api.anthropic.com` (usage data) and `console.anthropic.com` (token refresh)
- No telemetry, tracking, or third-party services
- The app is not sandboxed (it needs access to `~/.claude` for JSONL parsing)

## Support

- [Report issues](https://github.com/richyparr/tokemon/issues)
- Website: [tokemon.app](https://tokemon.app)

## License

MIT
