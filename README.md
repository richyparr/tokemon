# Tokemon

Monitor your Claude Code usage from the macOS menu bar.

## Features

- **Real-time usage tracking** - See session and weekly usage at a glance
- **Multi-profile support** - Manage multiple Claude accounts
- **Menu bar customization** - 5 icon styles, monochrome mode, color-coded status
- **Terminal statusline** - Display usage in your bash/zsh prompt
- **Floating window** - Always-on-top usage display
- **Usage alerts** - Get notified before hitting limits
- **Analytics & export** - PDF reports, CSV export, usage history

## Installation

### Homebrew (Recommended)

```bash
brew tap richyparr/tokemon
brew install --cask tokemon
```

### Direct Download

Download the latest DMG from [Releases](https://github.com/richyparr/tokemon/releases).

### First Launch - Gatekeeper Warning

Since Tokemon is not yet signed with an Apple Developer certificate, macOS will show a warning on first launch:

> "Tokemon" Not Opened - Apple could not verify "Tokemon" is free of malware

**To open the app:**

1. Click **Done** on the warning dialog
2. Open **System Settings → Privacy & Security**
3. Scroll down to find "Tokemon was blocked"
4. Click **Open Anyway**

Or: **Right-click** on Tokemon.app in Applications and select **Open**

## Requirements

- macOS 14.0 (Sonoma) or later
- Claude Code CLI with active session

## License

Tokemon is free for personal use. Pro features require a license.

## Support

- [Report issues](https://github.com/richyparr/tokemon/issues)
- Website: [tokemon.app](https://tokemon.app)
