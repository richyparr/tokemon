# tokemon

Monitor your Claude AI usage at a glance — right from Raycast.

## Features

- **Dashboard** — View your current Claude session usage and weekly limits at a glance
- **Setup** — Step-by-step guide to configure your Claude OAuth token
- Session tracking with reset timers
- Weekly usage monitoring against your plan limits

## Prerequisites

- [Raycast](https://raycast.com) installed
- Node.js 22.14 or later
- A Claude account at [claude.ai](https://claude.ai)

## Setup

1. Clone or download this extension
2. Install dependencies:
   ```bash
   npm install
   ```
3. Start the extension in development mode:
   ```bash
   npm run dev
   ```
4. Configure your token:
   - Open the **Setup** command in Raycast for step-by-step instructions, or
   - Go to **Raycast Preferences → Extensions → tokemon** and paste your Claude OAuth token

## Getting Your OAuth Token

1. Open [claude.ai](https://claude.ai) in your browser
2. Go to **Settings → API Keys**
3. Create or copy your OAuth access token
4. Paste it into the **Claude OAuth Token** field in Raycast Preferences

## Commands

| Command | Description |
| --- | --- |
| **Dashboard** | View your Claude session and weekly usage stats |
| **Setup** | Configure your Claude OAuth token with guided instructions |

## Full macOS App

For the full tokemon experience — menu bar app, usage alerts, profile switching, and more — visit [tokemon.app](https://tokemon.app).

## License

MIT
