# Stack Research

**Domain:** Native macOS monitoring/utility app (menu bar + widget + floating window)
**Researched:** 2026-02-11
**Confidence:** HIGH

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Swift | 6.1+ (Xcode 16.4) or 6.2+ (Xcode 26) | Primary language | The only sensible choice for native macOS development. Swift 6 brings strict concurrency checking which prevents data races at compile time -- critical for an app polling multiple data sources. |
| SwiftUI | Framework (ships with macOS SDK) | UI layer for all views | Declarative UI with native macOS integration. MenuBarExtra, Charts, and WidgetKit all require SwiftUI. Pure SwiftUI for views with targeted AppKit for system integration (70/30 split). |
| AppKit | Framework (ships with macOS SDK) | System integration layer | NSPanel for floating windows, NSStatusItem fallback, window level management. SwiftUI alone cannot handle all macOS system integration points. |
| WidgetKit | Framework (ships with macOS SDK) | Notification Center widget | Apple's only supported widget framework. Runs in a separate process, communicates via App Groups and shared data stores. |
| Swift Charts | Framework (ships with macOS SDK) | Usage graphs and trend visualization | Apple's first-party charting framework, deeply integrated with SwiftUI. Supports LineMark, BarMark, AreaMark -- all needed for usage trends. No third-party dependency needed. |
| SwiftData | Framework (requires macOS 14+) | Local data persistence | Modern replacement for Core Data with native Swift syntax. Uses @Model macro, integrates directly with SwiftUI via @Query. Supports App Group sharing with WidgetKit via ModelConfiguration. |

### Minimum Deployment Target

| Target | Version | Rationale |
|--------|---------|-----------|
| macOS | 14.0 (Sonoma) | **This is the critical decision.** macOS 14 is the minimum for: SwiftData, @Observable macro (Observation framework), interactive WidgetKit on macOS, Swift Charts maturity. Targeting macOS 13 would require Core Data instead of SwiftData and lose @Observable. macOS 15+ would be ideal (gains .windowLevel(.floating) modifier, UtilityWindow scene) but cuts off too many users. |

**Confidence: HIGH** -- Apple documentation confirms these framework availability requirements.

### Xcode Version Strategy

| Scenario | Xcode Version | Swift Version | SDK |
|----------|---------------|---------------|-----|
| Current stable (recommended) | Xcode 16.4 | Swift 6.1 | macOS 15.5 SDK |
| Latest (if adopting Liquid Glass) | Xcode 26.2 | Swift 6.2.3 | macOS 26.2 SDK |

**Recommendation:** Start with Xcode 16.4 targeting macOS 14+. This gives the widest user base while accessing all needed frameworks. Adopt Xcode 26 and Liquid Glass as a future design phase after core features are stable.

**Confidence: HIGH** -- Verified from Apple release notes and xcodereleases.com.

### Networking & API Integration

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| URLSession | Built-in (Foundation) | HTTP API calls to Anthropic | Built-in, zero dependencies. async/await support since Swift 5.5. Handles all HTTP methods, authentication headers, JSON encoding/decoding natively. No reason to use Alamofire or similar for this project's simple API needs. |
| JSONDecoder/JSONEncoder | Built-in (Foundation) | API response parsing | Codable protocol with Anthropic's JSON API responses. Custom CodingKeys for snake_case mapping. |

### Data APIs (What ClaudeMon Monitors)

| Data Source | API/Method | Authentication | Refresh Strategy |
|-------------|-----------|---------------|------------------|
| **Claude API Usage** | `GET /v1/organizations/usage_report/messages` | Admin API key (`sk-ant-admin...`) | Poll every 5-15 min. Data available within 5 min of API request. Supports 1m/1h/1d buckets. |
| **Claude API Costs** | `GET /v1/organizations/cost_report` | Admin API key | Poll daily. Daily granularity only (`1d` buckets). Returns USD costs as decimal strings. |
| **Claude Code Analytics** | `GET /v1/organizations/usage_report/claude_code` | Admin API key | Poll daily. Daily aggregation with up to 1-hour delay. Returns per-user sessions, lines of code, commits, PRs, tool acceptance rates, model breakdown with estimated costs. |
| **Claude Code Local Logs** | Read `~/.claude/projects/` JSONL files | Local filesystem access (sandbox exception or bookmark) | Watch directory with FSEvents/DispatchSource. Parse JSONL for token counts per session. |
| **Claude.ai Web Usage** | No official API exists | N/A | **NOT FEASIBLE via API.** Claude.ai consumer usage has no programmatic endpoint. Options: (1) manual entry, (2) browser extension companion (out of scope), (3) skip this data source initially. |

**Confidence: HIGH** for API endpoints (verified against official Anthropic docs). **MEDIUM** for local JSONL parsing (community tools confirm the format but Anthropic could change it without notice). **HIGH** for Claude.ai limitation (no API exists).

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| KeychainAccess | 4.2.2+ | Secure storage of API keys | Store Admin API keys securely. Simple Swift wrapper over Keychain Services. Battle-tested with 7k+ GitHub stars. Use over raw Security framework for cleaner API. |
| swift-security | 2.5.1 | **Alternative** to KeychainAccess | Choose if you want a more modern, type-safe API with no Objective-C legacy. Zero dependencies, supports SwiftUI integration. Less community adoption but cleaner Swift-native design. |

**Recommendation:** Use **KeychainAccess** for its maturity and community support. The Keychain API surface for this app is small (store/retrieve a few API keys), so either library works.

**Confidence: MEDIUM** -- Both libraries verified on GitHub/Swift Package Index but version pinning should be confirmed at project creation time.

### Notifications

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| UserNotifications | Built-in (macOS 10.14+) | Local notifications for usage limit warnings | Apple's standard notification framework. Supports actionable notifications, customizable content, and scheduled delivery. Request permission via UNUserNotificationCenter. |

### State Management

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| @Observable macro | macOS 14+ (Observation framework) | Reactive state for all view models | Replaces @ObservableObject/@StateObject/@ObservedObject with cleaner, more performant pull-based tracking. Views only re-render when properties they actually read change. Use @State for ownership, plain properties for injection. |
| @AppStorage | Built-in (SwiftUI) | User preferences (theme selection, refresh interval, notification thresholds) | Simple key-value persistence for settings. For App Group sharing with widget, use `@AppStorage("key", store: UserDefaults(suiteName: "group.com.yourteam.claudemon"))`. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| Xcode 16.4+ | IDE, build system, code signing | Use Xcode Previews extensively for SwiftUI iteration. Set up separate schemes for main app and widget extension. |
| Swift Package Manager | Dependency management | Built into Xcode. No CocoaPods or Carthage needed. Only 1-2 external packages required. |
| Instruments | Performance profiling | Monitor memory usage (menu bar apps must be lightweight), network request timing, and SwiftData query performance. |
| xcrun notarytool | App notarization for distribution | Required for distributing outside Mac App Store. GitHub releases need notarized .dmg or .zip. |

## Architecture Decisions

### Menu Bar Implementation

Use **MenuBarExtra** with `.menuBarExtraStyle(.window)` for the popover-style expanded view. This is the modern SwiftUI API (macOS 13+) and provides a window-style popover that can contain rich SwiftUI views including charts.

```swift
@main
struct ClaudeMonApp: App {
    var body: some Scene {
        MenuBarExtra {
            ContentView()
        } label: {
            Label("ClaudeMon", systemImage: "chart.bar")
        }
        .menuBarExtraStyle(.window)
    }
}
```

**Known limitation (MEDIUM confidence):** `SettingsLink` does not work reliably inside `MenuBarExtra`. Opening a settings window requires workarounds involving activation policy changes and hidden windows. This is a documented pain point as of 2025.

### Floating Window Implementation

For macOS 14 (minimum target), use an **NSPanel subclass** wrapped for SwiftUI. For users on macOS 15+, prefer the native `.windowLevel(.floating)` modifier and `UtilityWindow` scene.

**Strategy:** Build NSPanel approach first (works everywhere), add native SwiftUI floating window as a runtime check on macOS 15+.

```swift
// macOS 15+ path
if #available(macOS 15.0, *) {
    UtilityWindow("ClaudeMon", id: "floating") {
        FloatingView()
    }
    .windowLevel(.floating)
} else {
    // NSPanel fallback for macOS 14
}
```

### Widget Data Flow

```
Main App → SwiftData (App Group container) → Widget reads SwiftData
Main App → WidgetCenter.shared.reloadAllTimelines() → Widget refreshes
```

**Key requirements:**
- Both targets must be in the same App Group
- Widget creates its own ModelContainer (runs in separate process)
- Model files must have target membership in both app and widget extension
- Budget: ~40-70 refreshes per day (roughly every 15-60 min)

### Data Persistence Strategy

| Data Type | Storage | Why |
|-----------|---------|-----|
| Usage history (tokens, costs, sessions) | SwiftData | Structured, queryable, shareable with widget via App Group. Supports @Query for reactive SwiftUI binding. |
| API keys | Keychain (via KeychainAccess) | Encrypted, secure enclave protected. Never in UserDefaults or SwiftData. |
| User preferences (theme, intervals, thresholds) | UserDefaults (App Group suite) | Simple key-value pairs. @AppStorage for SwiftUI binding. Shared with widget for display preferences. |
| Cached API responses | SwiftData or in-memory | Short-lived cache for reducing API calls. SwiftData if persistence across launches matters. |

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| SwiftData | Core Data | Only if you need to support macOS 13 or earlier, or need heavyweight migration support. SwiftData is built on Core Data internally but provides dramatically simpler API. |
| Swift Charts | DGCharts (formerly ios-charts) | Only if you need chart types Swift Charts doesn't support (candlestick, radar, bubble). Swift Charts covers all ClaudeMon needs (line, bar, area). |
| MenuBarExtra (.window style) | NSStatusItem + NSPopover | Only if targeting macOS 12 or earlier. MenuBarExtra is the modern replacement and handles lifecycle correctly. |
| KeychainAccess | Raw Security framework | Only if you want zero dependencies at all costs. The raw Keychain API is verbose and error-prone with its C-style API. |
| @Observable | @ObservableObject | Only if targeting macOS 13. For macOS 14+, @Observable is strictly better (finer-grained updates, less boilerplate). |
| URLSession async/await | Combine publishers | Combine is not deprecated but async/await is the modern standard. Combine adds unnecessary complexity for straightforward HTTP requests. |
| SwiftData (App Group) | UserDefaults (App Group) for widget sharing | UserDefaults is simpler for small data. Use SwiftData when widget needs access to historical usage records (which it does for trend graphs). |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Electron / web-based wrappers | Massive memory footprint unacceptable for a menu bar app that runs 24/7. Native macOS app should use <30MB RAM. | Swift/SwiftUI native |
| Realm / SQLite directly | Unnecessary complexity. SwiftData provides the right abstraction for this use case with native SwiftUI integration. | SwiftData |
| Alamofire / Moya | Over-engineered for ~3 API endpoints with simple JSON responses. URLSession async/await handles this cleanly. | URLSession |
| CocoaPods / Carthage | Legacy dependency managers. SPM is built into Xcode and handles all needed packages. | Swift Package Manager |
| @ObservableObject / @StateObject | Legacy observation pattern. @Observable macro is more performant and less boilerplate on macOS 14+. | @Observable macro |
| Combine for networking | Adds publisher chain complexity when async/await is cleaner and more readable. Combine is fine for reactive UI bindings but unnecessary for HTTP calls. | async/await |
| NSUserNotificationCenter | Deprecated since macOS 11. | UNUserNotificationCenter (UserNotifications framework) |
| Storyboards / XIBs | Legacy UI approach. SwiftUI with targeted AppKit is the modern standard. | SwiftUI + AppKit interop where needed |

## Stack Patterns by Variant

**If distributing via Mac App Store:**
- App Sandbox is required (restricts filesystem access to ~/Library/Containers/)
- Reading `~/.claude/projects/` JSONL files requires a security-scoped bookmark or an explicit user grant via NSOpenPanel
- WidgetKit works without additional configuration
- App Group identifier uses `group.` prefix

**If distributing via GitHub releases (.dmg / Homebrew):**
- App Sandbox is optional but notarization is still required
- Hardened Runtime required for notarization
- Can read `~/.claude/` directly if not sandboxed (but should still request permission gracefully)
- Must sign with Developer ID certificate (not Mac App Store certificate)
- Use `xcrun notarytool` for notarization

**If supporting Liquid Glass (macOS 26+):**
- Use `.glassEffect(.regular)` modifier for translucent controls
- Wrap in `GlassEffectContainer` for grouped glass elements
- Use `#available(macOS 26, *)` checks -- do NOT make macOS 26 the minimum target yet
- Three glass types: `.regular`, `.clear`, `.identity`
- Can tint glass with `.tint(_:)` modifier

## Version Compatibility

| Component | Minimum macOS | Notes |
|-----------|---------------|-------|
| MenuBarExtra | macOS 13.0 | Core menu bar scene |
| MenuBarExtra .window style | macOS 13.0 | Popover-style rendering |
| SwiftData | macOS 14.0 | Full ORM with @Model, @Query |
| @Observable macro | macOS 14.0 | Modern observation framework |
| Swift Charts | macOS 13.0 | But gained significant features in macOS 14 (scrollable charts, selection) |
| WidgetKit (macOS) | macOS 14.0 | Interactive widgets on desktop |
| UserNotifications | macOS 10.14 | Well established |
| .windowLevel(.floating) | macOS 15.0 | Native SwiftUI floating windows |
| UtilityWindow | macOS 15.0 | Built-in utility window scene |
| Liquid Glass / .glassEffect | macOS 26.0 | New design language, opt-in |

**The matrix confirms macOS 14 as the right minimum target.** It unlocks SwiftData, @Observable, and interactive WidgetKit while still covering Sonoma (Sep 2023), Sequoia (Sep 2024), and Tahoe (Sep 2025) users.

## Installation

```bash
# No npm -- this is a native Swift project

# Clone and open in Xcode
git clone https://github.com/youruser/ClaudeMon.git
cd ClaudeMon
open ClaudeMon.xcodeproj

# Or if using Swift Package structure:
swift build  # for CLI components if any
```

### Package.swift Dependencies (if using SPM manifest)

```swift
dependencies: [
    .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
]
```

### Xcode Project Setup

1. Create macOS App target (SwiftUI lifecycle, Swift language)
2. Set deployment target: macOS 14.0
3. Add Widget Extension target (WidgetKit)
4. Configure App Group capability on both targets
5. Add Keychain Sharing capability (for KeychainAccess)
6. Add User Notifications capability
7. Configure Hardened Runtime for notarization
8. Add KeychainAccess via File > Add Package Dependencies

## Sources

- [Anthropic Usage and Cost API](https://platform.claude.com/docs/en/build-with-claude/usage-cost-api) -- HIGH confidence, official docs, verified endpoint details and authentication requirements
- [Anthropic Claude Code Analytics API](https://platform.claude.com/docs/en/api/claude-code-analytics-api) -- HIGH confidence, official docs, verified response schema and available metrics
- [Apple MenuBarExtra Documentation](https://developer.apple.com/documentation/swiftui/menubarextra) -- HIGH confidence, Apple official
- [Apple WidgetKit: Keeping a Widget Up to Date](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date) -- HIGH confidence, Apple official
- [Apple SwiftData Documentation](https://developer.apple.com/documentation/swiftdata) -- HIGH confidence, Apple official
- [Apple Swift Charts Documentation](https://developer.apple.com/documentation/Charts) -- HIGH confidence, Apple official
- [Apple Observation Framework](https://developer.apple.com/documentation/Observation) -- HIGH confidence, Apple official
- [Xcode Releases](https://xcodereleases.com/) -- HIGH confidence, verified Xcode 16.4 ships Swift 6.1, Xcode 26.2 ships Swift 6.2.3
- [Nil Coalescing: Build a macOS menu bar utility in SwiftUI](https://nilcoalescing.com/blog/BuildAMacOSMenuBarUtilityInSwiftUI/) -- MEDIUM confidence, community tutorial
- [Polpiella: Floating window in macOS 15](https://www.polpiella.dev/creating-a-floating-window-using-swiftui-in-macos-15) -- MEDIUM confidence, community tutorial
- [Cindori: Floating panel in SwiftUI](https://cindori.com/developer/floating-panel) -- MEDIUM confidence, community tutorial
- [Peter Steinberger: Settings from menu bar items](https://steipete.me/posts/2025/showing-settings-from-macos-menu-bar-items) -- MEDIUM confidence, documents SettingsLink bug
- [Hacking with Swift: SwiftData in widgets](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-access-a-swiftdata-container-from-widgets) -- MEDIUM confidence, tutorial
- [KeychainAccess GitHub](https://github.com/kishikawakatsumi/KeychainAccess) -- HIGH confidence, direct source
- [swift-security GitHub](https://github.com/dm-zharov/swift-security) -- MEDIUM confidence, smaller community
- [ccusage: Claude Code local JSONL parser](https://github.com/ryoppippi/ccusage) -- LOW confidence for JSONL format stability (unofficial, could change)
- [Preslav Rachev: Claude Code token usage on macOS toolbar](https://preslav.me/2025/08/04/put-claude-code-token-usage-macos-toolbar/) -- LOW confidence, single source for local file format details
- [Apple: Applying Liquid Glass to custom views](https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views) -- HIGH confidence for glassEffect API, Apple official
- [Stats: macOS system monitor](https://github.com/exelban/stats) -- Reference architecture for menu bar monitoring apps

---
*Stack research for: ClaudeMon -- macOS Claude usage monitoring app*
*Researched: 2026-02-11*
