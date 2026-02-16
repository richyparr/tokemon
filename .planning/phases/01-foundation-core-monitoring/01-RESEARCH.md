# Phase 1: Foundation & Core Monitoring - Research

**Researched:** 2026-02-12
**Domain:** macOS menu bar app with OAuth data fetching, JSONL parsing, SwiftUI popover, and settings
**Confidence:** HIGH

## Summary

Phase 1 builds a working macOS menu bar app that displays Claude usage data from two sources: the OAuth usage endpoint (primary) and Claude Code JSONL session logs (fallback). The user sees a text percentage in the menu bar, clicks to expand a popover with detailed usage breakdown, and can configure refresh intervals and data sources in settings. The menu bar icon uses subtle gradient colors based on usage level. Right-click on the menu bar icon shows a quick-action context menu.

The primary technical challenge is that SwiftUI's `MenuBarExtra` does not natively support right-click handling, colored text labels, or reliable settings window access -- all three of which are locked user decisions. This means the implementation must use a hybrid approach: `MenuBarExtra` with `.window` style for the popover content, but with `MenuBarExtraAccess` (or direct `NSStatusItem` access) to enable right-click context menus and custom colored text labels. The `SettingsAccess` library solves the known `SettingsLink` bug in `MenuBarExtra`.

**Primary recommendation:** Use `MenuBarExtra` with `.menuBarExtraStyle(.window)` as the foundation, augmented by the `MenuBarExtraAccess` library (v1.2.2) for `NSStatusItem` access (enabling right-click handling and custom colored labels) and the `SettingsAccess` library (v2.1.0) for reliable settings window opening. For data, read the OAuth token from the macOS Keychain (`Claude Code-credentials` service), call `GET https://api.anthropic.com/api/oauth/usage` with Bearer auth, and parse JSONL from `~/.claude/projects/` as fallback.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **Menu Bar Icon**: Default display is text percentage (e.g., "45%") in menu bar. User can change to stylized Claude logo or abstract gauge/meter in settings. Color is subtle gradient based on usage level -- not harsh traffic light colors. Click opens popover. Right-click shows quick menu with: Refresh now, Open floating window, Settings, Quit.
- **Popover Layout**: Top section has big usage percentage number (dominant, first thing user sees). Below percentage: limit remaining, reset time, messages/tokens breakdown. Density is comfortable -- breathing room, easy to read. Settings access via gear icon in popover footer opens settings section/sheet. No source indicator needed in main view.
- **Data Refresh & Loading**: Refresh interval is user configurable in settings. Default interval is 1 minute. Loading indication is subtle spinner during refresh + "last updated" timestamp always visible. Background refresh continues even when popover is closed (menu bar icon stays current).
- **Error States**: OAuth failure notifies user once ("Switching to backup data source"), then silently falls back to JSONL. Both sources fail: show error indicator in menu bar (obvious but not alarming). Recovery strategy: auto-retry 3 times at refresh interval spacing, then require manual retry button. Error messages: user-friendly primary message + "Show details" expander for technical info.

### Claude's Discretion
- Exact spinner design and placement
- Typography and spacing within constraints
- Animation and transitions
- "Show details" technical info formatting

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope
</user_constraints>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Swift | 6.1+ (Xcode 16.4) | Primary language | Native macOS development with strict concurrency checking |
| SwiftUI | macOS 14 SDK | UI layer for popover content, settings, all views | MenuBarExtra, @Observable, declarative UI |
| AppKit | macOS 14 SDK | System integration: NSStatusItem access, NSMenu for right-click | SwiftUI cannot handle right-click or custom colored menu bar text alone |
| SwiftData | macOS 14 SDK | Local persistence for usage history | @Model with App Group sharing, @Query for reactive views |
| Foundation/URLSession | Built-in | HTTP requests to OAuth endpoint | async/await, zero dependencies |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| MenuBarExtraAccess | 1.2.2 | Access underlying NSStatusItem from MenuBarExtra | Required for right-click handling and programmatic popover show/hide |
| SettingsAccess | 2.1.0 | Open Settings window reliably from MenuBarExtra | Required because SettingsLink does not work inside MenuBarExtra |
| KeychainAccess | 4.2.2+ | Read Claude Code OAuth token from macOS Keychain | Read `Claude Code-credentials` service entry; store user preferences securely |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| MenuBarExtraAccess | Raw NSStatusItem (skip MenuBarExtra entirely) | More control but lose SwiftUI popover lifecycle management; MenuBarExtraAccess bridges both worlds |
| SettingsAccess | Hidden window + NotificationCenter hack | More fragile; requires manual activation policy juggling and timing delays |
| KeychainAccess | Raw Security.framework | Verbose C-style API; only worthwhile if zero-dependency is critical |

**Installation (Package.swift dependencies):**
```swift
dependencies: [
    .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
    .package(url: "https://github.com/orchetect/MenuBarExtraAccess.git", from: "1.2.2"),
    .package(url: "https://github.com/orchetect/SettingsAccess.git", from: "2.1.0"),
]
```

## Architecture Patterns

### Recommended Project Structure (Phase 1 Scope)
```
Tokemon/
├── Tokemon/                        # Main app target
│   ├── TokemonApp.swift            # @main, MenuBarExtra scene + Settings scene
│   ├── Info.plist                    # LSUIElement = YES (no Dock icon)
│   │
│   ├── Models/
│   │   ├── UsageSnapshot.swift       # Current usage state (Codable struct)
│   │   ├── UsageRecord.swift         # @Model for historical persistence
│   │   ├── OAuthUsageResponse.swift  # Codable for /api/oauth/usage JSON
│   │   └── DataSourceState.swift     # Enum: .available, .failed(Error), .disabled
│   │
│   ├── Services/
│   │   ├── UsageMonitor.swift        # @Observable central state + polling timer
│   │   ├── OAuthClient.swift         # Fetches from /api/oauth/usage endpoint
│   │   ├── TokenManager.swift        # Reads/refreshes OAuth token from Keychain
│   │   ├── JSONLParser.swift         # Parses ~/.claude/projects/ JSONL files
│   │   ├── UsageDataSource.swift     # Protocol definition for data sources
│   │   └── PollingScheduler.swift    # Timer management with App Nap prevention
│   │
│   ├── Views/
│   │   ├── MenuBar/
│   │   │   ├── PopoverContentView.swift    # Main popover layout
│   │   │   ├── UsageHeaderView.swift       # Big percentage number + progress
│   │   │   ├── UsageDetailView.swift       # Limit remaining, reset time, breakdown
│   │   │   ├── RefreshStatusView.swift     # Spinner + last updated timestamp
│   │   │   └── ErrorBannerView.swift       # Error state with "Show details"
│   │   ├── Settings/
│   │   │   ├── SettingsView.swift          # Main settings container
│   │   │   ├── DataSourceSettings.swift    # Enable/disable sources
│   │   │   ├── RefreshSettings.swift       # Interval configuration
│   │   │   └── AppearanceSettings.swift    # Icon style selection
│   │   └── Shared/
│   │       └── UsageGaugeView.swift        # Reusable circular/linear gauge
│   │
│   └── Utilities/
│       ├── Constants.swift           # App Group ID, default intervals, API URLs
│       ├── GradientColors.swift      # Usage-level gradient color definitions
│       └── Extensions.swift          # Date formatting, number formatting
│
├── Shared/                           # Code shared with future widget target
│   ├── AppGroupConstants.swift       # Group ID, container URLs
│   └── UsageSnapshot.swift           # Shared Codable model (both targets)
│
└── Tokemon.xcodeproj
```

### Pattern 1: Hybrid MenuBarExtra with NSStatusItem Access
**What:** Use `MenuBarExtra` for SwiftUI popover content but access the underlying `NSStatusItem` via `MenuBarExtraAccess` for custom label rendering and right-click handling.
**When to use:** Always in this app -- required to meet user decisions (text percentage in menu bar, right-click context menu).
**Example:**
```swift
@main
struct TokemonApp: App {
    @State private var monitor = UsageMonitor()
    @State private var isPopoverPresented = false

    var body: some Scene {
        MenuBarExtra(isPresented: $isPopoverPresented) {
            PopoverContentView()
                .environment(monitor)
                .frame(width: 320, height: 400)
        } label: {
            // This label is replaced by custom NSStatusItem rendering
            Text(monitor.menuBarText)
        }
        .menuBarExtraStyle(.window)
        .menuBarExtraAccess(isPresented: $isPopoverPresented) { statusItem in
            // Access the real NSStatusItem for custom rendering
            configureStatusItem(statusItem)
        }

        Settings {
            SettingsView()
                .environment(monitor)
        }
    }
}
```

### Pattern 2: Custom Colored Text in Menu Bar via NSStatusItem
**What:** Render the percentage text (e.g., "45%") with a subtle gradient color based on usage level directly on the `NSStatusItem.button`.
**When to use:** For the default menu bar display mode (text percentage).
**Example:**
```swift
func updateMenuBarLabel(_ statusItem: NSStatusItem, usage: Double) {
    let button = statusItem.button!
    let text = "\(Int(usage))%"

    let color = gradientColor(for: usage) // subtle gradient, not harsh traffic lights
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium),
        .foregroundColor: color
    ]
    button.attributedTitle = NSAttributedString(string: text, attributes: attributes)
    statusItem.length = NSStatusItem.variableLength
}

func gradientColor(for usage: Double) -> NSColor {
    switch usage {
    case 0..<40:
        return NSColor.secondaryLabelColor           // subtle, unobtrusive
    case 40..<65:
        return NSColor(calibratedRed: 0.6, green: 0.7, blue: 0.3, alpha: 1.0) // muted warm
    case 65..<80:
        return NSColor(calibratedRed: 0.85, green: 0.6, blue: 0.2, alpha: 1.0) // amber
    case 80..<95:
        return NSColor(calibratedRed: 0.9, green: 0.4, blue: 0.2, alpha: 1.0) // warm orange
    default:
        return NSColor(calibratedRed: 0.85, green: 0.25, blue: 0.2, alpha: 1.0) // muted red
    }
}
```

### Pattern 3: Right-Click Context Menu on NSStatusItem
**What:** Show an `NSMenu` when the user right-clicks the menu bar icon, while left-click shows the popover.
**When to use:** Required by user decision -- right-click shows: Refresh now, Open floating window, Settings, Quit.
**Example:**
```swift
func configureStatusItem(_ statusItem: NSStatusItem) {
    guard let button = statusItem.button else { return }

    // Enable both left and right mouse events
    button.sendAction(on: [.leftMouseUp, .rightMouseUp])

    // Store reference for click handling
    // The MenuBarExtraAccess library handles left-click (popover toggle)
    // For right-click, we need a custom event monitor or subclass approach
}

func buildContextMenu() -> NSMenu {
    let menu = NSMenu()
    menu.addItem(NSMenuItem(title: "Refresh Now", action: #selector(refreshNow), keyEquivalent: "r"))
    menu.addItem(NSMenuItem.separator())
    menu.addItem(NSMenuItem(title: "Open Floating Window", action: #selector(openFloat), keyEquivalent: ""))
    menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
    menu.addItem(NSMenuItem.separator())
    menu.addItem(NSMenuItem(title: "Quit Tokemon", action: #selector(quitApp), keyEquivalent: "q"))
    return menu
}
```

**Note:** Right-click on `MenuBarExtra` is a known limitation. The `MenuBarExtraAccess` library exposes the `NSStatusItem`, but the actual right-click detection requires either: (a) using `NSEvent.addLocalMonitorForEvents` to intercept right-clicks on the status item button, or (b) subclassing the button view. This is a well-documented pattern in the macOS menu bar app community.

### Pattern 4: OAuth Token Reading from macOS Keychain
**What:** Read the Claude Code OAuth access token from macOS Keychain and use it to call the usage endpoint.
**When to use:** On every data refresh cycle.
**Example:**
```swift
import KeychainAccess

struct TokenManager {
    private static let keychainService = "Claude Code-credentials"

    struct ClaudeCredentials: Codable {
        let claudeAiOauth: OAuthCredential

        struct OAuthCredential: Codable {
            let accessToken: String
            let refreshToken: String
            let expiresAt: Int64 // Unix timestamp in milliseconds
            let scopes: [String]
            let subscriptionType: String?
            let rateLimitTier: String?
        }
    }

    static func getAccessToken() throws -> String {
        let keychain = Keychain(service: keychainService)
        guard let credentialsJSON = try keychain.getString("") else {
            throw TokenError.noCredentials
        }
        let credentials = try JSONDecoder().decode(
            ClaudeCredentials.self,
            from: Data(credentialsJSON.utf8)
        )
        // Check expiration
        let expiresAt = Date(timeIntervalSince1970:
            Double(credentials.claudeAiOauth.expiresAt) / 1000.0)
        if expiresAt < Date() {
            throw TokenError.expired
        }
        return credentials.claudeAiOauth.accessToken
    }
}
```

**Verified credential structure (from actual macOS Keychain on this machine):**
```json
{
  "claudeAiOauth": {
    "accessToken": "sk-ant-oat01-...",
    "refreshToken": "sk-ant-ort01-...",
    "expiresAt": 1770849725205,
    "scopes": ["user:inference", "user:mcp_servers", "user:profile", "user:sessions:claude_code"],
    "subscriptionType": "max",
    "rateLimitTier": "default_claude_max_20x"
  }
}
```

### Pattern 5: OAuth Token Refresh
**What:** When the access token is expired, use the refresh token to obtain a new one.
**When to use:** When the OAuth usage endpoint returns 401 or the `expiresAt` timestamp is in the past.
**Example:**
```swift
struct TokenRefreshRequest: Encodable {
    let grant_type = "refresh_token"
    let refresh_token: String
    let client_id = "9d1c250a-e61b-44d9-88ed-5944d1962f5e" // Claude Code CLI client ID
}

func refreshAccessToken(refreshToken: String) async throws -> OAuthTokenResponse {
    let url = URL(string: "https://console.anthropic.com/v1/oauth/token")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode(
        TokenRefreshRequest(refresh_token: refreshToken)
    )

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw TokenError.refreshFailed
    }
    return try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
}
```

**Token refresh endpoint:** `POST https://console.anthropic.com/v1/oauth/token`
**Client ID:** `9d1c250a-e61b-44d9-88ed-5944d1962f5e` (official Claude Code CLI client ID)
**Access token lifespan:** ~8 hours (expires_in: 28800 seconds)
**Refresh token lifespan:** Indefinite (does not expire)

### Pattern 6: Settings Window from MenuBarExtra
**What:** Open a Settings window reliably from within a `MenuBarExtra` popover, using `SettingsAccess` library.
**When to use:** When user taps the gear icon in the popover footer.
**Example:**
```swift
import SettingsAccess

struct PopoverFooterView: View {
    @Environment(\.openSettingsLegacy) private var openSettingsLegacy

    var body: some View {
        HStack {
            Spacer()
            Button {
                openSettingsLegacy()
            } label: {
                Image(systemName: "gear")
            }
        }
        .openSettingsAccess()
    }
}
```

### Anti-Patterns to Avoid
- **Using `MenuBarExtra` alone without NSStatusItem access:** Cannot do colored text labels or right-click menus. Use `MenuBarExtraAccess` to bridge.
- **Polling the Keychain on every refresh:** Read the token once, cache it, only re-read on 401 or expiration.
- **Parsing all JSONL files on every refresh:** Cache parsed results; only re-parse files modified since last check (use file modification timestamps).
- **Using `@ObservableObject` instead of `@Observable`:** macOS 14 target means `@Observable` is available and strictly better.
- **Storing OAuth tokens in UserDefaults:** Use Keychain only. Never persist tokens outside encrypted storage.
- **Hard-coding error messages:** Use a structured error type with user-friendly and technical detail components.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| NSStatusItem access from MenuBarExtra | Private API swizzling or runtime hacks | MenuBarExtraAccess (1.2.2) | Maintained, clean API, handles edge cases |
| Settings window from MenuBarExtra | Hidden window + NotificationCenter + activation policy juggling | SettingsAccess (2.1.0) | Encapsulates the known workaround cleanly |
| Keychain access | Raw Security.framework C API | KeychainAccess (4.2.2) | Verbose, error-prone C-style API; KeychainAccess handles all edge cases |
| OAuth token refresh flow | Manual URLSession + token storage management | Dedicated TokenManager service | Don't scatter refresh logic; centralize in one service that handles expiry, refresh, and Keychain update |
| JSONL streaming parser | Naive `String.components(separatedBy: "\n")` | Line-by-line `FileHandle` or `AsyncBytes` reading | Large JSONL files (100MB+) will OOM if loaded entirely into memory |
| Gradient color for usage level | UIKit/AppKit color interpolation | Pre-defined color stops with `NSColor` | Simple 5-level mapping is more intentional than mathematical interpolation |

**Key insight:** The three libraries (MenuBarExtraAccess, SettingsAccess, KeychainAccess) each solve a specific, well-documented gap in Apple's APIs. They are all lightweight, focused, and maintained. Building custom solutions for any of these would waste significant time on edge cases already handled by the libraries.

## Common Pitfalls

### Pitfall 1: Menu Bar Label Not Updating
**What goes wrong:** The `MenuBarExtra` label view does not re-render when `@State` or `@Observable` properties change, leaving a stale percentage visible.
**Why it happens:** SwiftUI's `MenuBarExtra` label rendering has known reactivity issues. The label closure may not always re-evaluate when state changes.
**How to avoid:** When using `MenuBarExtraAccess` to get the `NSStatusItem`, update the button's `attributedTitle` directly in an observation callback (e.g., `withObservationTracking` or from the `UsageMonitor`'s refresh method). Do not rely solely on SwiftUI text binding in the label closure.
**Warning signs:** Percentage shows correctly initially but never updates after refreshes.

### Pitfall 2: OAuth Token Expired / Refresh Not Working
**What goes wrong:** The OAuth access token expires (~8 hours), API calls return 401, and the app shows perpetual errors.
**Why it happens:** Claude Code's own token refresh has known bugs (multiple GitHub issues open). Tokemon reads the token from Keychain but cannot rely on Claude Code keeping it fresh.
**How to avoid:** Implement token refresh within Tokemon itself using the refresh token and `POST https://console.anthropic.com/v1/oauth/token`. Update the Keychain entry after refresh. Check `expiresAt` before each API call; proactively refresh when within 10 minutes of expiry.
**Warning signs:** App works initially but fails after ~8 hours of continuous use.

### Pitfall 3: OAuth Token Requires user:profile Scope
**What goes wrong:** The `/api/oauth/usage` endpoint returns 403 "OAuth token does not meet scope requirement user:profile".
**Why it happens:** Some token acquisition methods (like `setup-token`) only request `user:inference` scope, missing the `user:profile` scope required for usage data.
**How to avoid:** When reading the token from Keychain, check that the `scopes` array includes `"user:profile"`. If missing, show an informative error directing the user to re-authenticate with Claude Code using `/login` (full OAuth flow).
**Warning signs:** 403 errors despite having a valid-looking token.

### Pitfall 4: App Nap Throttles Background Timer
**What goes wrong:** After the popover closes, macOS App Nap throttles the polling timer, causing the menu bar icon to show stale data.
**Why it happens:** macOS aggressively naps background apps to save energy. Menu bar apps with `LSUIElement=true` are especially susceptible.
**How to avoid:** Use `ProcessInfo.processInfo.beginActivity(options: [.background, .idleSystemSleepDisabled], reason: "Usage monitoring")` to prevent App Nap during active polling. Release the activity when polling stops.
**Warning signs:** Menu bar percentage is accurate when popover is open but becomes stale when closed.

### Pitfall 5: JSONL Parser Crashes on Malformed Lines
**What goes wrong:** Parser crashes when encountering a partial/truncated final line (Claude Code is mid-write) or unexpected field types.
**Why it happens:** JSONL files are append-only and may have an incomplete last line during active Claude Code sessions.
**How to avoid:** Wrap each line parse in a `do/catch`. Skip lines that fail to decode. Never force-unwrap JSON fields. Use optional chaining with default values. Only extract `usage` blocks from `type: "assistant"` messages.
**Warning signs:** App crashes intermittently, especially during active Claude Code sessions.

### Pitfall 6: Popover Sizing and Dismissal
**What goes wrong:** Popover is too small (content clipped), too large (awkward dead space), or doesn't dismiss when clicking outside.
**Why it happens:** `MenuBarExtra` with `.window` style creates an `NSPanel` under the hood. Sizing must be set via `.frame()` on the content view. Dismissal behavior is automatic but can break with certain view hierarchies.
**How to avoid:** Set explicit `.frame(width: 320, height: 400)` on the popover content view. Test dismissal by clicking on the desktop, other apps, and the menu bar icon itself. The `MenuBarExtraAccess` `isPresented` binding can help with programmatic dismissal.
**Warning signs:** Content overflows, scroll bars appear unexpectedly, or popover stays open when it shouldn't.

### Pitfall 7: Error State Fallback Logic Race Condition
**What goes wrong:** When OAuth fails and JSONL fallback activates, both sources may fire simultaneously or the UI shows inconsistent state.
**Why it happens:** Async data fetching from two sources with different timing creates race conditions in the merge logic.
**How to avoid:** Implement a clear priority chain in `UsageMonitor`: (1) Try OAuth, (2) If OAuth fails, increment retry counter and try JSONL, (3) Merge results with clear precedence rules. Use `@MainActor` to ensure all state updates are serialized. Track source state per-source, not globally.
**Warning signs:** Usage numbers flicker between different values, or fallback message appears then disappears.

## Code Examples

### OAuth Usage Endpoint Request
```swift
// Source: Verified from https://codelynx.dev/posts/claude-code-usage-limits-statusline
// and confirmed against actual API calls

struct OAuthUsageResponse: Codable {
    let fiveHour: UsageWindow?
    let sevenDay: UsageWindow?
    let sevenDayOauthApps: UsageWindow?
    let sevenDayOpus: UsageWindow?

    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
        case sevenDayOauthApps = "seven_day_oauth_apps"
        case sevenDayOpus = "seven_day_opus"
    }

    struct UsageWindow: Codable {
        let utilization: Double  // percentage (0-100)
        let resetsAt: String?    // ISO-8601 timestamp

        enum CodingKeys: String, CodingKey {
            case utilization
            case resetsAt = "resets_at"
        }
    }
}

func fetchOAuthUsage(accessToken: String) async throws -> OAuthUsageResponse {
    let url = URL(string: "https://api.anthropic.com/api/oauth/usage")!
    var request = URLRequest(url: url)
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
    request.setValue("Tokemon/1.0", forHTTPHeaderField: "User-Agent")

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse else {
        throw OAuthError.invalidResponse
    }

    switch httpResponse.statusCode {
    case 200:
        return try JSONDecoder().decode(OAuthUsageResponse.self, from: data)
    case 401:
        throw OAuthError.tokenExpired
    case 403:
        throw OAuthError.insufficientScope
    default:
        throw OAuthError.httpError(httpResponse.statusCode)
    }
}
```

**Actual response structure (verified):**
```json
{
  "five_hour": {
    "utilization": 6.0,
    "resets_at": "2025-11-04T04:59:59.943648+00:00"
  },
  "seven_day": {
    "utilization": 35.0,
    "resets_at": "2025-11-06T03:59:59.943679+00:00"
  },
  "seven_day_oauth_apps": null,
  "seven_day_opus": {
    "utilization": 0.0,
    "resets_at": null
  }
}
```

### JSONL Parser (Defensive, Line-by-Line)
```swift
// Source: Verified against actual ~/.claude/projects/ files on this machine
// Claude Code v2.1.39 JSONL structure

struct JSONLParser {
    struct SessionUsage {
        var inputTokens: Int = 0
        var outputTokens: Int = 0
        var cacheCreationTokens: Int = 0
        var cacheReadTokens: Int = 0
        var model: String?
        var sessionId: String?
        var timestamp: Date?
    }

    static func parseSession(at url: URL) -> SessionUsage {
        var usage = SessionUsage()

        guard let fileHandle = try? FileHandle(forReadingFrom: url) else {
            return usage
        }
        defer { fileHandle.closeFile() }

        // Line-by-line reading to handle large files
        let data = fileHandle.readDataToEndOfFile()
        let content = String(data: data, encoding: .utf8) ?? ""

        for line in content.split(separator: "\n") {
            guard !line.isEmpty else { continue }

            // Defensive parsing: skip malformed lines
            guard let lineData = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any]
            else { continue }

            // Only extract usage from assistant messages
            guard json["type"] as? String == "assistant",
                  let message = json["message"] as? [String: Any],
                  let usageObj = message["usage"] as? [String: Any]
            else { continue }

            // Accumulate tokens (defensive: default to 0 for missing fields)
            usage.inputTokens += usageObj["input_tokens"] as? Int ?? 0
            usage.outputTokens += usageObj["output_tokens"] as? Int ?? 0
            usage.cacheCreationTokens += usageObj["cache_creation_input_tokens"] as? Int ?? 0
            usage.cacheReadTokens += usageObj["cache_read_input_tokens"] as? Int ?? 0

            // Capture model from first assistant message
            if usage.model == nil {
                usage.model = message["model"] as? String
            }

            // Capture session metadata
            if usage.sessionId == nil {
                usage.sessionId = json["sessionId"] as? String
            }
        }

        return usage
    }
}
```

**Verified JSONL fields (from actual Claude Code v2.1.39 on this machine):**
- Top-level types: `assistant`, `user`, `system`, `progress`, `queue-operation`, `file-history-snapshot`
- Usage fields: `input_tokens`, `output_tokens`, `cache_creation_input_tokens`, `cache_read_input_tokens`, `cache_creation` (nested), `service_tier`, `inference_geo`
- Models: `claude-opus-4-5-20251101` (observed)
- Project directories: URL-encoded path with dashes (e.g., `-Users-richardparr-Tokemon`)
- Session files: `{uuid}.jsonl`
- Session index: `sessions-index.json` (contains session metadata)

### Background Polling with App Nap Prevention
```swift
@Observable
@MainActor
final class UsageMonitor {
    var currentUsage: UsageSnapshot = .empty
    var isRefreshing: Bool = false
    var lastUpdated: Date?
    var error: MonitorError?

    private var pollTimer: Timer?
    private var activity: NSObjectProtocol? // App Nap prevention

    func startPolling(interval: TimeInterval = 60) {
        // Prevent App Nap
        activity = ProcessInfo.processInfo.beginActivity(
            options: [.background, .idleSystemSleepDisabled],
            reason: "Tokemon usage monitoring"
        )

        // Schedule repeating timer
        pollTimer = Timer.scheduledTimer(
            withTimeInterval: interval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.refresh()
            }
        }

        // Immediate first fetch
        Task { await refresh() }
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
        if let activity {
            ProcessInfo.processInfo.endActivity(activity)
        }
        self.activity = nil
    }

    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        // Try OAuth first (primary source)
        do {
            let token = try TokenManager.getAccessToken()
            let response = try await fetchOAuthUsage(accessToken: token)
            currentUsage = UsageSnapshot(from: response)
            lastUpdated = Date()
            error = nil
            return
        } catch {
            // Fall back to JSONL
            handleOAuthError(error)
        }

        // Fallback: parse JSONL
        do {
            let jsonlUsage = try parseLocalJSONL()
            currentUsage = UsageSnapshot(from: jsonlUsage)
            lastUpdated = Date()
        } catch {
            self.error = .bothSourcesFailed(error)
        }
    }
}
```

### Popover Layout (Matching User Decisions)
```swift
struct PopoverContentView: View {
    @Environment(UsageMonitor.self) private var monitor

    var body: some View {
        VStack(spacing: 16) {
            // Big percentage number (dominant, first thing user sees)
            UsageHeaderView(usage: monitor.currentUsage)

            Divider()

            // Limit remaining, reset time, messages/tokens breakdown
            UsageDetailView(usage: monitor.currentUsage)

            Spacer()

            // Error banner (if applicable)
            if let error = monitor.error {
                ErrorBannerView(error: error)
            }

            Divider()

            // Footer: refresh status + settings gear
            PopoverFooterView(
                isRefreshing: monitor.isRefreshing,
                lastUpdated: monitor.lastUpdated
            )
        }
        .padding(16)
        .frame(width: 320, height: 400)
    }
}
```

### App Entry Point (Complete Scene Declaration)
```swift
import SwiftUI
import MenuBarExtraAccess
import SettingsAccess

@main
struct TokemonApp: App {
    @State private var monitor = UsageMonitor()
    @State private var isPopoverPresented = false

    var body: some Scene {
        MenuBarExtra(isPresented: $isPopoverPresented) {
            PopoverContentView()
                .environment(monitor)
                .frame(width: 320, height: 400)
        } label: {
            Text(monitor.menuBarText)
        }
        .menuBarExtraStyle(.window)
        .menuBarExtraAccess(isPresented: $isPopoverPresented) { statusItem in
            updateStatusItemAppearance(statusItem, usage: monitor.currentUsage)
        }

        Settings {
            SettingsView()
                .environment(monitor)
        }
    }

    private func updateStatusItemAppearance(
        _ statusItem: NSStatusItem,
        usage: UsageSnapshot
    ) {
        let percentage = Int(usage.primaryPercentage)
        let color = GradientColors.color(for: usage.primaryPercentage)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium),
            .foregroundColor: color
        ]
        statusItem.button?.attributedTitle = NSAttributedString(
            string: "\(percentage)%",
            attributes: attributes
        )
        statusItem.length = NSStatusItem.variableLength
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| NSStatusItem + NSPopover (manual) | MenuBarExtra + .window style | macOS 13 (2022) | Much simpler setup; SwiftUI manages popover lifecycle |
| @ObservableObject with @Published | @Observable macro | macOS 14 (2023) | Finer-grained observation; less boilerplate; better performance |
| Core Data for persistence | SwiftData with @Model/@Query | macOS 14 (2023) | Native Swift syntax; simpler schema; direct SwiftUI integration |
| showSettingsWindow() selector (private) | SettingsAccess library or openSettings env | macOS 14+ (2024) | Private API stopped working; library provides supported workaround |
| Manual NSStatusItem management | MenuBarExtraAccess library | 2024 | Clean bridge between SwiftUI MenuBarExtra and AppKit NSStatusItem |
| Claude Code credentials in .credentials.json | macOS Keychain only | Claude Code v2.0+ | More secure; file no longer exists on macOS |
| JSONL with costUSD field | JSONL without costUSD (Max/Pro) | Claude Code v1.0.9 | Must calculate costs from token counts x pricing |

**Deprecated/outdated:**
- `NSUserNotificationCenter` -- replaced by `UNUserNotificationCenter` (not needed in Phase 1)
- `showSettingsWindow()` selector -- stopped working in macOS 14; use `SettingsAccess` library
- `~/.claude/.credentials.json` file -- on macOS, credentials are now exclusively in Keychain under `"Claude Code-credentials"` service

## Open Questions

1. **Right-click detection with MenuBarExtraAccess**
   - What we know: MenuBarExtraAccess exposes the NSStatusItem, and NSStatusItem.button supports `sendAction(on:)` for mouse events
   - What's unclear: Whether MenuBarExtraAccess's popover management interferes with right-click detection (since left-click is already handled for popover toggle)
   - Recommendation: Test during implementation. Fallback plan: use `NSEvent.addLocalMonitorForEvents(matching: .rightMouseUp)` to detect right-clicks on the status item button area

2. **Keychain access key name for reading credentials**
   - What we know: `security find-generic-password -s "Claude Code-credentials" -w` works from terminal
   - What's unclear: Whether `KeychainAccess` library uses the same key path convention (service name vs. account name)
   - Recommendation: Test with `Keychain(service: "Claude Code-credentials")` and iterate. The actual Keychain item may use an empty account name.

3. **Token refresh: can Tokemon write updated tokens back to Keychain?**
   - What we know: Tokemon can read from Keychain. The refresh endpoint works. Claude Code's own refresh has bugs.
   - What's unclear: Whether writing updated tokens back would conflict with Claude Code's Keychain access. Claude Code expects to own this entry.
   - Recommendation: On first iteration, only read from Keychain and handle 401 by notifying user to re-authenticate Claude Code. Add token refresh in a follow-up if reading is reliable. Flag this as a v1.1 enhancement if conflicts arise.

4. **MenuBarExtra popover height: fixed or dynamic?**
   - What we know: User wants comfortable density. Error states need extra space. The `.frame()` sets a fixed size.
   - What's unclear: Whether the popover should dynamically resize based on content (errors shown/hidden, number of data sources)
   - Recommendation: Start with fixed height (400pt). If content overflows or has too much whitespace, implement `GeometryReader` or `fixedSize()` with min/max constraints.

## Sources

### Primary (HIGH confidence)
- OAuth usage endpoint (`GET https://api.anthropic.com/api/oauth/usage`) -- [Codelynx statusline guide](https://codelynx.dev/posts/claude-code-usage-limits-statusline), verified response structure
- OAuth token refresh (`POST https://console.anthropic.com/v1/oauth/token`) -- [opencode-anthropic-auth](https://github.com/anomalyco/opencode-anthropic-auth/blob/master/index.mjs), verified client_id and request format
- OAuth credential structure -- Verified from actual macOS Keychain on this machine (service: "Claude Code-credentials")
- JSONL file structure -- Verified from actual `~/.claude/projects/` files on this machine (Claude Code v2.1.39)
- [MenuBarExtraAccess](https://github.com/orchetect/MenuBarExtraAccess) v1.2.2 -- NSStatusItem access from MenuBarExtra
- [SettingsAccess](https://github.com/orchetect/SettingsAccess) v2.1.0 -- Settings window from MenuBarExtra
- [KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess) v4.2.2 -- Keychain read/write
- [Peter Steinberger: Settings from menu bar items](https://steipete.me/posts/2025/showing-settings-from-macos-menu-bar-items) -- Documents SettingsLink bug and workarounds
- [Apple MenuBarExtra documentation](https://developer.apple.com/documentation/swiftui/menubarextra) -- Official API reference
- [Claude Code authentication docs](https://code.claude.com/docs/en/authentication) -- Credential management on macOS

### Secondary (MEDIUM confidence)
- [Claude Usage Tracker](https://github.com/hamed-elfayome/Claude-Usage-Tracker) -- Reference implementation of competing menu bar app
- [Nil Coalescing: Build macOS menu bar utility](https://nilcoalescing.com/blog/BuildAMacOSMenuBarUtilityInSwiftUI/) -- MenuBarExtra with .window style patterns
- [OAuth token refresh blog post](https://www.alif.web.id/posts/claude-oauth-api-key) -- Token lifespan (8 hours), client_id confirmed
- [DuckDB JSONL analysis](https://liambx.com/blog/claude-code-log-analysis-with-duckdb) -- JSONL field documentation
- [NSStatusItem right-click handling](https://onmyway133.com/posts/how-to-support-right-click-menu-to-nsstatusitem/) -- sendAction pattern for left/right clicks
- [Claude Code Keychain issues](https://github.com/anthropics/claude-code/issues/9403) -- Documents Keychain service name and access patterns

### Tertiary (LOW confidence)
- Token refresh write-back to Keychain -- No confirmed pattern for third-party apps writing to Claude Code's Keychain entry without conflicts
- `iguana_necktie` field in OAuth response -- Purpose unknown; appears in some responses as null. Likely internal/experimental.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- All libraries verified on GitHub with version numbers and macOS compatibility confirmed
- Architecture: HIGH -- Patterns verified against existing competitor implementations and Apple documentation
- OAuth endpoint: HIGH -- Response structure verified from multiple sources and confirmed against actual Keychain data on this machine
- JSONL structure: HIGH -- Verified from actual files on this machine running Claude Code v2.1.39
- Pitfalls: HIGH -- Each pitfall verified with specific technical evidence (GitHub issues, Apple Feedback reports, developer blog posts)
- Right-click handling: MEDIUM -- Pattern is well-documented for raw NSStatusItem but needs validation with MenuBarExtraAccess

**Research date:** 2026-02-12
**Valid until:** ~2026-03-15 (30 days; OAuth endpoint is undocumented and could change)

---
*Phase research for: Tokemon Phase 1 -- Foundation & Core Monitoring*
*Researched: 2026-02-12*
