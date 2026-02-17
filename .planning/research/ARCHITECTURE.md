# Architecture Research: Raycast Extension for Tokemon v4.0

**Domain:** Raycast extension for Claude usage monitoring
**Researched:** 2026-02-18
**Confidence:** HIGH (official Raycast docs + verified existing extensions)

## Executive Summary

A standalone Raycast extension for Claude usage monitoring that fetches data directly via OAuth, requiring no connection to Tokemon.app. The extension must handle credential input (since direct Keychain access is not permitted in Raycast Store extensions), token refresh, local caching, and background refresh for menu bar updates.

**Key architectural decision:** Raycast Store policy prohibits direct Keychain access. The extension must use Raycast's password preferences or OAuth PKCE flow for credential management instead of reading from Claude Code's Keychain entry.

## System Overview

```
+--------------------------------------------------------------------+
|                     RAYCAST EXTENSION                               |
|                                                                    |
|  +------------------+     +------------------+     +--------------+ |
|  | Usage Dashboard  |     | MenuBarExtra     |     | Preferences  | |
|  | Command (view)   |     | Command          |     | (password)   | |
|  +--------+---------+     +--------+---------+     +------+-------+ |
|           |                        |                      |         |
|           +------------------------+----------------------+         |
|                                    |                                |
|  +------------------+     +--------v---------+     +--------------+ |
|  | useCachedState   |<--->| UsageService     |<--->| OAuth Client | |
|  | (persist cache)  |     | (fetch/refresh)  |     | (token mgmt) | |
|  +------------------+     +------------------+     +--------------+ |
|                                    |                                |
+------------------------------------+--------------------------------+
                                     |
                                     v
                    +--------------------------------+
                    | api.anthropic.com/api/oauth/  |
                    | usage (with Bearer token)     |
                    +--------------------------------+
```

### Process Model

Unlike Tokemon.app (persistent process), Raycast extensions are **ephemeral**:

1. **Command invocation**: Raycast loads the extension, runs the command, then unloads
2. **Menu bar commands**: Stay loaded while displayed, unload after `isLoading: false`
3. **Background refresh**: Raycast wakes the command at configured intervals
4. **No persistent state**: All state must be persisted to LocalStorage or Cache between invocations

## Data Flow

### Primary Flow: Menu Bar Background Refresh

```
Raycast scheduler (interval: "5m")
    |
    v
MenuBarExtra command wakes
    |
    v
Check credentials in password preference
    |-- Missing? --> Show "Configure Extension" item
    |
    v (credentials present)
Check token expiry (from LocalStorage)
    |-- Expired? --> Refresh token via OAuth endpoint
    |              |
    |              v
    |         Store new tokens in LocalStorage
    |
    v
Fetch usage from api.anthropic.com/api/oauth/usage
    |
    v
Parse OAuthUsageResponse (same format as Tokemon)
    |
    v
Update useCachedState with new snapshot
    |
    v
Render MenuBarExtra with usage percentage
    |
    v
Set isLoading: false --> Raycast unloads command
```

### Secondary Flow: Dashboard Command

```
User invokes "Claude Usage" command
    |
    v
Read cached data from useCachedState (instant display)
    |
    v
Start background fetch (useFetch with stale-while-revalidate)
    |
    v
Display List with usage details:
    - Session (5-hour) utilization
    - Weekly (7-day) utilization
    - Model-specific (Opus/Sonnet) limits
    - Reset countdown timers
    - Extra usage billing (if enabled)
    |
    v
User can trigger manual refresh (Cmd+R)
```

### Token Refresh Flow

```
Before API call, check expiresAt timestamp
    |-- Valid (> 10 min buffer)? --> Use accessToken
    |
    v (expired or near-expiry)
POST to console.anthropic.com/v1/oauth/token
    Body: {
        grant_type: "refresh_token",
        refresh_token: <stored_refresh_token>,
        client_id: "9d1c250a-e61b-44d9-88ed-5944d1962f5e"
    }
    |
    v
Parse OAuthTokenResponse: {
    access_token, refresh_token, expires_in, token_type
}
    |
    v
Store updated tokens in LocalStorage (encrypted)
    |
    v
Proceed with API call using new accessToken
```

## Raycast APIs to Use

### Core APIs

| API | Purpose | Usage in Extension |
|-----|---------|-------------------|
| **MenuBarExtra** | Display usage in Raycast menu bar | Primary UI surface with percentage/icon |
| **LocalStorage** | Persist tokens and cached data | Store OAuth tokens (encrypted by Raycast) |
| **useCachedState** | Stateful persistence across invocations | Cache usage snapshot between runs |
| **useFetch** | Data fetching with SWR caching | Fetch usage data with automatic revalidation |
| **getPreferenceValues** | Read user-configured secrets | Access OAuth tokens from password preference |
| **Background Refresh** | Auto-update menu bar | 5-minute interval for menu bar command |

### API Details

**MenuBarExtra Component:**
```typescript
import { MenuBarExtra, open } from "@raycast/api";

export default function MenuBarUsage() {
  const [usage, setUsage] = useCachedState<UsageSnapshot>("usage");
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    fetchUsage().then(setUsage).finally(() => setIsLoading(false));
  }, []);

  return (
    <MenuBarExtra
      icon={{ source: "gauge.png", tintColor: getStatusColor(usage) }}
      title={usage ? `${Math.round(usage.fiveHour)}%` : "..."}
      tooltip="Claude Usage"
      isLoading={isLoading}
    >
      <MenuBarExtra.Item title={`Session: ${usage?.fiveHour ?? 0}%`} />
      <MenuBarExtra.Item title={`Weekly: ${usage?.sevenDay ?? 0}%`} />
      <MenuBarExtra.Separator />
      <MenuBarExtra.Item
        title="Open Dashboard"
        onAction={() => open("raycast://extensions/tokemon/claude-usage")}
      />
    </MenuBarExtra>
  );
}
```

**Background Refresh Configuration (package.json):**
```json
{
  "commands": [
    {
      "name": "menu-bar",
      "title": "Claude Usage",
      "mode": "menu-bar",
      "interval": "5m"
    }
  ]
}
```

**Password Preference for Tokens:**
```json
{
  "preferences": [
    {
      "name": "accessToken",
      "type": "password",
      "required": true,
      "title": "Access Token",
      "description": "OAuth access token from Claude Code keychain"
    },
    {
      "name": "refreshToken",
      "type": "password",
      "required": true,
      "title": "Refresh Token",
      "description": "OAuth refresh token for automatic renewal"
    }
  ]
}
```

## Credential Handling

### The Keychain Access Problem

**Critical constraint:** Raycast Store rejects extensions that request direct Keychain access. This means the extension **cannot** read Claude Code's credentials from `"Claude Code-credentials"` keychain service directly.

**Verified via official docs:**
> "Extensions requesting Keychain Access will be rejected due to security concerns."
> -- [Raycast Security Documentation](https://developers.raycast.com/information/security)

### Solution Options (Ranked)

#### Option 1: Manual Token Entry via Preferences (RECOMMENDED)

Users manually copy tokens from Keychain Access.app or use the Tokemon.app helper command to display their current tokens.

**Pros:**
- Works with Raycast Store distribution
- No external dependencies
- Tokens stored securely in Raycast's encrypted preference storage

**Cons:**
- Requires manual setup step
- Token expiry requires re-entry (unless refresh token works)

**Implementation:**
1. User opens Keychain Access.app, searches "Claude Code-credentials"
2. Copies the JSON blob to clipboard
3. Pastes into Raycast extension preferences (or individual token fields)
4. Extension parses and stores tokens

#### Option 2: Helper Script via `open` URL Scheme

Tokemon.app registers a URL scheme (`tokemon://export-token`) that:
1. Reads current OAuth token from Keychain
2. Opens Raycast with pre-filled preference values

**Pros:**
- Better UX than manual copy
- One-click setup if Tokemon.app is installed

**Cons:**
- Requires Tokemon.app installation (defeats "standalone" goal)
- Complex URL scheme registration

#### Option 3: OAuth PKCE Flow via Raycast

Use Raycast's built-in OAuth PKCE support to authenticate directly with Anthropic.

**Pros:**
- No manual token copying
- Standard OAuth flow

**Cons:**
- Anthropic may not have a public OAuth authorization endpoint for third-party apps
- Claude Code uses internal OAuth client ID (`9d1c250a-e61b-44d9-88ed-5944d1962f5e`)
- Using this client ID in a third-party extension may violate ToS

**Status:** NOT VIABLE -- Anthropic's OAuth is internal to Claude Code

### Recommended Approach: Manual Entry + Token Refresh

1. **Initial setup:** User enters tokens manually via preferences
2. **Token storage:** Raycast's encrypted LocalStorage
3. **Auto-refresh:** Extension refreshes tokens before expiry using refresh_token
4. **Re-auth prompt:** If refresh fails, prompt user to re-enter tokens

**Token persistence structure:**
```typescript
interface StoredCredentials {
  accessToken: string;
  refreshToken: string;
  expiresAt: number; // Unix timestamp (ms)
  lastUpdated: number;
}

// Store in LocalStorage
await LocalStorage.setItem("credentials", JSON.stringify(credentials));

// Read from LocalStorage
const stored = await LocalStorage.getItem<string>("credentials");
const credentials = stored ? JSON.parse(stored) : null;
```

## Caching Strategy

### Multi-Layer Cache

```
Layer 1: useCachedState (React state + disk)
    |-- Instant UI on command open
    |-- Persists between command invocations
    |
Layer 2: LocalStorage (explicit persistence)
    |-- OAuth tokens (long-lived, refreshed)
    |-- Usage history (for trend display)
    |-- User preferences (alert thresholds)
    |
Layer 3: useFetch (stale-while-revalidate)
    |-- Returns cached data immediately
    |-- Revalidates in background
    |-- Automatic error handling
```

### Cache Keys

| Key | Content | TTL |
|-----|---------|-----|
| `credentials` | OAuth tokens (access, refresh, expiry) | Until refresh needed |
| `usage-snapshot` | Current usage data | 5 minutes (refresh interval) |
| `usage-history` | Last 24 hours of data points | 24 hours rolling |
| `last-fetch` | Timestamp of last successful fetch | Indefinite |

### Stale-While-Revalidate Pattern

```typescript
function useUsageData() {
  const [cached, setCached] = useCachedState<UsageSnapshot>("usage-snapshot");

  const { data, isLoading, revalidate } = useFetch<OAuthUsageResponse>(
    "https://api.anthropic.com/api/oauth/usage",
    {
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "anthropic-beta": "oauth-2025-04-20"
      },
      keepPreviousData: true,
      execute: !!accessToken,
      onData: (response) => {
        const snapshot = parseResponse(response);
        setCached(snapshot);
      }
    }
  );

  return {
    data: cached,
    isLoading: isLoading && !cached,
    revalidate
  };
}
```

## Component Architecture

### Directory Structure

```
tokemon-raycast/
  |
  +-- src/
  |     +-- index.tsx              # Main dashboard command
  |     +-- menu-bar.tsx           # MenuBarExtra command
  |     +-- configure-alerts.tsx   # Alert threshold settings
  |     +-- switch-profile.tsx     # Profile switching (future)
  |     |
  |     +-- api/
  |     |     +-- oauth-client.ts   # Token refresh logic
  |     |     +-- usage-client.ts   # Fetch usage data
  |     |     +-- types.ts          # OAuthUsageResponse, etc.
  |     |
  |     +-- hooks/
  |     |     +-- useUsageData.ts   # SWR-based usage fetching
  |     |     +-- useCredentials.ts # Token management
  |     |
  |     +-- components/
  |     |     +-- UsageList.tsx     # Dashboard list items
  |     |     +-- UsageDetail.tsx   # Detail view for each metric
  |     |
  |     +-- utils/
  |           +-- format.ts         # Percentage, time formatting
  |           +-- colors.ts         # Status color mapping
  |
  +-- assets/
  |     +-- icon.png               # Extension icon
  |     +-- gauge-*.png            # Menu bar status icons
  |
  +-- package.json
  +-- tsconfig.json
```

### Component Responsibilities

| Component | Purpose | Raycast API |
|-----------|---------|-------------|
| **menu-bar.tsx** | Menu bar usage display | MenuBarExtra, useCachedState |
| **index.tsx** | Full dashboard with all metrics | List, Detail, useFetch |
| **oauth-client.ts** | Token refresh, expiry check | LocalStorage, fetch |
| **useUsageData.ts** | Central data fetching hook | useFetch, useCachedState |
| **useCredentials.ts** | Credential validation/refresh | getPreferenceValues, LocalStorage |

## Integration Points

### Tokemon.app Integration (Optional)

If Tokemon.app is installed, the Raycast extension can:

1. **Read shared state** via `~/.tokemon/raycast-bridge.json` (written by Tokemon.app)
2. **Trigger app actions** via URL scheme (`tokemon://refresh`, `tokemon://switch-profile`)

**Bridge file format:**
```json
{
  "version": 1,
  "usage": {
    "fiveHour": 45.2,
    "sevenDay": 23.1,
    "resetsAt": "2026-02-18T15:30:00Z"
  },
  "profiles": [
    { "id": "default", "name": "Personal", "active": true },
    { "id": "work", "name": "Work", "active": false }
  ],
  "lastUpdated": "2026-02-18T10:25:00Z"
}
```

**Detection logic:**
```typescript
async function checkTokemonApp(): Promise<boolean> {
  const bridgePath = `${os.homedir()}/.tokemon/raycast-bridge.json`;
  try {
    await fs.access(bridgePath);
    return true;
  } catch {
    return false;
  }
}
```

### External APIs

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `api.anthropic.com/api/oauth/usage` | GET | Fetch current usage data |
| `console.anthropic.com/v1/oauth/token` | POST | Refresh OAuth tokens |

### API Request Headers

```typescript
const headers = {
  "Authorization": `Bearer ${accessToken}`,
  "Accept": "application/json",
  "anthropic-beta": "oauth-2025-04-20",
  "User-Agent": "Tokemon-Raycast/1.0"
};
```

## Build Order

Based on dependencies, the recommended implementation order:

### Phase 1: Foundation (Days 1-2)

1. **Project scaffolding**
   - `npm init raycast-extension`
   - Package.json with commands and preferences
   - TypeScript configuration

2. **Type definitions**
   - `OAuthUsageResponse` (match Tokemon's model)
   - `UsageSnapshot` for caching
   - `StoredCredentials` for token storage

3. **Credential management**
   - Password preference for token entry
   - LocalStorage read/write helpers
   - Token expiry checking

### Phase 2: Core Functionality (Days 3-4)

4. **OAuth client**
   - Token refresh implementation
   - Error handling (401 -> prompt re-auth)
   - Retry logic with backoff

5. **Usage fetching**
   - `useFetch` hook with proper headers
   - Response parsing to `UsageSnapshot`
   - Cache management with `useCachedState`

6. **Basic dashboard command**
   - List view with usage metrics
   - Detail view for each metric
   - Manual refresh action (Cmd+R)

### Phase 3: Menu Bar (Days 5-6)

7. **MenuBarExtra command**
   - Icon with dynamic tint color
   - Title showing session percentage
   - Dropdown with detailed metrics

8. **Background refresh**
   - 5-minute interval configuration
   - `LaunchType` detection
   - Proper `isLoading` lifecycle

### Phase 4: Polish (Days 7-8)

9. **Error states**
   - Token expired prompts
   - Network failure handling
   - Empty state when no credentials

10. **Alert configuration** (stretch goal)
    - Threshold preferences
    - In-app notification via `showHUD`

## Anti-Patterns to Avoid

### Anti-Pattern 1: Attempting Direct Keychain Access

**What happens:** Extension uses `node-keychain` or `security` CLI to read Claude Code credentials.

**Why it fails:** Raycast Store rejects the extension during review. Even if self-distributed, the approach is fragile and platform-specific.

**Do instead:** Use Raycast's password preferences for token storage.

### Anti-Pattern 2: Polling in Command Body

**What happens:** Dashboard command runs `setInterval` to refresh data.

**Why it fails:** Raycast unloads the command when user navigates away. The interval dies. CPU waste while command is open.

**Do instead:** Use `useFetch` with stale-while-revalidate for the dashboard. Use background refresh interval for menu bar.

### Anti-Pattern 3: Storing Tokens in Plain LocalStorage

**What happens:** `LocalStorage.setItem("accessToken", token)` without encryption.

**Why it fails:** LocalStorage values are JSON-serializable strings. While Raycast encrypts the database, the tokens are visible in memory and logs.

**Do instead:** Use password preferences for initial entry. Store structured credentials object with minimal exposure.

### Anti-Pattern 4: Synchronous Operations in MenuBarExtra

**What happens:** Blocking API calls in the component body before returning JSX.

**Why it fails:** Menu bar appears frozen. Raycast may terminate the command.

**Do instead:** Return immediately with `isLoading: true`, fetch async, update state, set `isLoading: false`.

### Anti-Pattern 5: Ignoring Launch Type

**What happens:** Full UI rendering on background refresh triggers.

**Why it fails:** Unnecessary work. May cause visual flicker. Wastes resources.

**Do instead:** Check `environment.launchType === LaunchType.Background` and skip UI-intensive operations.

## Comparison: Tokemon.app vs Raycast Extension

| Aspect | Tokemon.app (Swift) | Raycast Extension (TypeScript) |
|--------|---------------------|-------------------------------|
| **Credential access** | Direct Keychain read via KeychainAccess | Manual entry via preferences |
| **Token refresh** | Auto-refresh via OAuthClient | Same logic, different storage |
| **Background polling** | Timer with App Nap prevention | Raycast scheduler (interval) |
| **State persistence** | @Observable + UserDefaults | useCachedState + LocalStorage |
| **Menu bar** | Native NSStatusItem via MenuBarExtra | Raycast MenuBarExtra component |
| **Process model** | Persistent background app | Ephemeral, loaded on demand |
| **Distribution** | Homebrew tap + direct download | Raycast Store |

## Existing Extensions Reference

Two existing Raycast extensions for Claude usage monitoring provide implementation patterns:

### raycast-llm-usage (markhudsonn)

- **Approach:** Reads directly from macOS Keychain (not in Raycast Store)
- **Features:** Menu bar display, pace prediction, cost tracking
- **Limitation:** Requires macOS Keychain access permission

### Claude Code Usage (ccusage)

- **Approach:** Uses `ccusage` CLI tool for data
- **Features:** Session history, model breakdown, custom npx path
- **Limitation:** Requires separate CLI tool installation

**Tokemon Raycast differentiation:**
- No CLI dependency
- Self-contained OAuth token management
- Optional Tokemon.app integration for enhanced features

## Sources

### Official Raycast Documentation (HIGH confidence)
- [OAuth API Reference](https://developers.raycast.com/api-reference/oauth)
- [Storage API Reference](https://developers.raycast.com/api-reference/storage)
- [Menu Bar Commands](https://developers.raycast.com/api-reference/menu-bar-commands)
- [Background Refresh](https://developers.raycast.com/information/lifecycle/background-refresh)
- [useCachedState Hook](https://developers.raycast.com/utilities/react-hooks/usecachedstate)
- [useFetch Hook](https://developers.raycast.com/utilities/react-hooks/usefetch)
- [Security Policies](https://developers.raycast.com/information/security)
- [Preferences API](https://developers.raycast.com/api-reference/preferences)

### Existing Extensions (MEDIUM confidence)
- [raycast-llm-usage (GitHub)](https://github.com/markhudsonn/raycast-llm-usage) -- Keychain approach (not Store-compatible)
- [ccusage (Raycast Store)](https://www.raycast.com/nyatinte/ccusage) -- CLI-based approach

### Tokemon.app Codebase (HIGH confidence)
- OAuthClient.swift -- API endpoint and response format
- TokenManager.swift -- Token refresh logic
- Constants.swift -- OAuth client ID, endpoint URLs
- OAuthUsageResponse.swift -- Response data model

---
*Architecture research for: Tokemon v4.0 Raycast Integration*
*Researched: 2026-02-18*
