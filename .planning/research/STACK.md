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

### Data APIs (What Tokemon Monitors)

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
| @AppStorage | Built-in (SwiftUI) | User preferences (theme selection, refresh interval, notification thresholds) | Simple key-value persistence for settings. For App Group sharing with widget, use `@AppStorage("key", store: UserDefaults(suiteName: "group.com.yourteam.tokemon"))`. |

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
struct TokemonApp: App {
    var body: some Scene {
        MenuBarExtra {
            ContentView()
        } label: {
            Label("Tokemon", systemImage: "chart.bar")
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
    UtilityWindow("Tokemon", id: "floating") {
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
| Swift Charts | DGCharts (formerly ios-charts) | Only if you need chart types Swift Charts doesn't support (candlestick, radar, bubble). Swift Charts covers all Tokemon needs (line, bar, area). |
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
git clone https://github.com/youruser/Tokemon.git
cd Tokemon
open Tokemon.xcodeproj

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
- [Hacking with Swift: SwiftData in widgets](https://www.hackingwithswift.com/quick-start/swiftui/how-to-access-a-swiftdata-container-from-widgets) -- MEDIUM confidence, tutorial
- [KeychainAccess GitHub](https://github.com/kishikawakatsumi/KeychainAccess) -- HIGH confidence, direct source
- [swift-security GitHub](https://github.com/dm-zharov/swift-security) -- MEDIUM confidence, smaller community
- [ccusage: Claude Code local JSONL parser](https://github.com/ryoppippi/ccusage) -- LOW confidence for JSONL format stability (unofficial, could change)
- [Preslav Rachev: Claude Code token usage on macOS toolbar](https://preslav.me/2025/08/04/put-claude-code-token-usage-macos-toolbar/) -- LOW confidence, single source for local file format details
- [Apple: Applying Liquid Glass to custom views](https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views) -- HIGH confidence for glassEffect API, Apple official
- [Stats: macOS system monitor](https://github.com/exelban/stats) -- Reference architecture for menu bar monitoring apps

---

# v2 Pro Features: Stack Additions

**Researched:** 2026-02-14
**Scope:** Additions for v2 features (licensing, PDF export, CSV export, shareable images, multi-account)
**Overall Confidence:** HIGH

## Summary

Tokemon v2 requires **only ONE new external dependency** (LemonSqueezy licensing). All other features use native Apple frameworks or the existing KeychainAccess dependency.

| Feature | Approach | New Dependency? |
|---------|----------|-----------------|
| LemonSqueezy Licensing | Third-party Swift SDK | YES (1 package) |
| PDF Export | Native ImageRenderer + CGContext | NO |
| CSV Export | Native string manipulation | NO |
| Shareable Images | Native ImageRenderer | NO |
| Multi-Account | Existing KeychainAccess | NO |

---

## New Dependency: LemonSqueezy License Validation

**Package:** [swift-lemon-squeezy-license](https://github.com/kevinhermawan/swift-lemon-squeezy-license)

| Attribute | Value |
|-----------|-------|
| Version | 1.0.1 (October 2024) |
| SPM URL | `https://github.com/kevinhermawan/swift-lemon-squeezy-license.git` |
| Product Name | `LemonSqueezyLicense` |
| Confidence | MEDIUM |

**Why this library:**
- Only Swift SDK available for LemonSqueezy License API
- Covers all three required operations: activate, validate, deactivate
- Clean async/await API matching Tokemon's existing patterns
- Lightweight (single-purpose, minimal footprint)

**API Requirements:**
- Requests to `https://api.lemonsqueezy.com` over HTTPS
- Headers: `Accept: application/json`, `Content-Type: application/x-www-form-urlencoded`
- Rate limited: 60 requests/minute (sufficient for app usage)

**License Status Values:**
| Status | Meaning |
|--------|---------|
| `inactive` | Valid key with no activations |
| `active` | Has one or more activations |
| `expired` | Expiry date has passed |
| `disabled` | Manually disabled by admin |

**Implementation Strategy:**

```swift
// Store after activation
struct LicenseInfo: Codable {
    let licenseKey: String
    let instanceId: String
    let status: String
    let validatedAt: Date
}

// Cache in UserDefaults
UserDefaults.standard.set(encodedLicenseInfo, forKey: "licenseInfo")

// Validation schedule:
// 1. On app launch (if online)
// 2. Every 24 hours while running
// 3. 7-day grace period for offline users
```

**Fallback Plan:** If library becomes unmaintained, LemonSqueezy's License API is simple enough for direct URLSession implementation (~100 lines).

**Confidence Rationale:** MEDIUM because community-maintained with modest activity (5 commits, 2 releases). API stability is good since it wraps LemonSqueezy's documented public API.

---

## Native Framework: PDF Export

**Framework:** SwiftUI `ImageRenderer` + Core Graphics `CGContext`

| Attribute | Value |
|-----------|-------|
| Min macOS | 13.0 (Ventura) |
| Tokemon Target | 14.0 (exceeds requirement) |
| Dependency | None |
| Confidence | HIGH |

**Why native over TPPDF:**
- ImageRenderer directly renders SwiftUI views to PDF with vector quality
- Tokemon already uses SwiftUI for all UI components (charts, layouts)
- No third-party dependency needed
- Consistent styling with app's existing views

**Implementation Pattern:**

```swift
import SwiftUI

struct PDFExporter {
    static func exportReport(view: some View, to url: URL) throws {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0  // Retina quality

        renderer.render { size, context in
            var box = CGRect(origin: .zero, size: size)
            guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
            pdf.beginPDFPage(nil)
            context(pdf)
            pdf.endPDFPage()
            pdf.closePDF()
        }
    }
}

// Usage
let reportView = UsageReportView(data: usageData, dateRange: selectedRange)
let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
let pdfURL = documentsURL.appendingPathComponent("Tokemon-Report-\(Date().ISO8601Format()).pdf")
try PDFExporter.exportReport(view: reportView, to: pdfURL)
```

**Considerations:**
- ImageRenderer does NOT render WebViews or MapViews (not used in Tokemon)
- Set `renderer.scale` to 2.0+ for high-resolution output
- Swift Charts render correctly as vector graphics

---

## Native Framework: CSV Export

**Framework:** Foundation (standard string manipulation)

| Attribute | Value |
|-----------|-------|
| Dependency | None |
| Confidence | HIGH |

**Why no library:**
- CSV generation is trivial string concatenation
- Tokemon's usage data is simple tabular data (dates, numbers, model names)
- No complex features needed (no reading, no custom delimiters)
- Adding a library for <50 lines of code is over-engineering

**Implementation Pattern:**

```swift
struct CSVExporter {
    static func export(dataPoints: [UsageDataPoint]) -> String {
        var csv = "Date,Model,Input Tokens,Output Tokens,Total Cost\n"

        for point in dataPoints {
            let row = [
                point.date.ISO8601Format(),
                escapeField(point.model),
                String(point.inputTokens),
                String(point.outputTokens),
                String(format: "%.4f", point.cost)
            ].joined(separator: ",")
            csv += row + "\n"
        }
        return csv
    }

    private static func escapeField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return field
    }
}

// Usage with ShareLink
let csvContent = CSVExporter.export(dataPoints: usageHistory)
let csvURL = FileManager.default.temporaryDirectory.appendingPathComponent("usage.csv")
try csvContent.write(to: csvURL, atomically: true, encoding: .utf8)
```

---

## Native Framework: Shareable Usage Cards

**Framework:** SwiftUI `ImageRenderer`

| Attribute | Value |
|-----------|-------|
| Min macOS | 13.0 |
| Dependency | None |
| Confidence | HIGH |

**Why native:**
- ImageRenderer is purpose-built for this exact use case
- Renders any SwiftUI view hierarchy to NSImage/CGImage
- Maintains full fidelity of charts, gradients, and styled text
- Already available (macOS 14 target exceeds macOS 13 requirement)

**Implementation Pattern:**

```swift
struct ImageExporter {
    static func captureCard(view: some View) -> NSImage? {
        let renderer = ImageRenderer(content: view)
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2.0
        return renderer.nsImage
    }

    static func exportPNG(view: some View, to url: URL) throws {
        guard let nsImage = captureCard(view: view) else {
            throw ExportError.renderFailed
        }
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw ExportError.encodingFailed
        }
        try pngData.write(to: url)
    }
}

// Shareable card view
struct ShareableUsageCard: View {
    let usage: UsageSnapshot
    let theme: Theme

    var body: some View {
        VStack(spacing: 16) {
            Text("Claude Usage")
                .font(.headline)
            UsageChartView(data: usage.history)
                .frame(width: 400, height: 200)
            HStack {
                Text("Total: \(usage.totalTokens) tokens")
                Spacer()
                Text("Cost: $\(usage.totalCost, specifier: "%.2f")")
            }
            Text("Generated by Tokemon")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(12)
    }
}
```

**Features Supported:**
- Swift Charts render correctly
- Custom fonts and colors preserved
- Gradients and shadows work
- Scale factor configurable for high-resolution export

---

## Existing Dependency: Multi-Account Credentials

**Library:** KeychainAccess (already in Package.swift)

| Attribute | Value |
|-----------|-------|
| Version | 4.2.2 |
| Status | Already a dependency |
| Confidence | HIGH |

**Why no changes needed:**
- KeychainAccess already supports storing multiple items with different keys
- Tokemon's `TokenManager` uses `kSecAttrService` + `kSecAttrAccount` pattern
- Multi-account just requires different account keys per credential

**Implementation Pattern:**

```swift
// Account list stored in UserDefaults (Keychain lacks list APIs)
struct AccountManager {
    private let keychain = Keychain(service: "Tokemon")

    var accounts: [String] {
        get { UserDefaults.standard.stringArray(forKey: "savedAccounts") ?? [] }
        set { UserDefaults.standard.set(newValue, forKey: "savedAccounts") }
    }

    var currentAccountId: String? {
        get { UserDefaults.standard.string(forKey: "currentAccount") }
        set { UserDefaults.standard.set(newValue, forKey: "currentAccount") }
    }

    func saveCredentials(_ credentials: ClaudeCredentials, for accountId: String) throws {
        let data = try JSONEncoder().encode(credentials)
        let json = String(data: data, encoding: .utf8)!
        try keychain.set(json, key: "\(accountId)-credentials")

        if !accounts.contains(accountId) {
            accounts.append(accountId)
        }
    }

    func getCredentials(for accountId: String) throws -> ClaudeCredentials {
        guard let json = try keychain.getString("\(accountId)-credentials"),
              let data = json.data(using: .utf8) else {
            throw TokenError.noCredentials
        }
        return try JSONDecoder().decode(ClaudeCredentials.self, from: data)
    }

    func removeAccount(_ accountId: String) throws {
        try keychain.remove("\(accountId)-credentials")
        accounts.removeAll { $0 == accountId }
        if currentAccountId == accountId {
            currentAccountId = accounts.first
        }
    }
}
```

**Architecture Notes:**
- Account identifiers stored in UserDefaults (Keychain lacks enumeration APIs)
- Each account's OAuth credentials stored in Keychain with account-specific key
- Current active account ID stored in UserDefaults
- Extend existing `TokenManager` with account selection parameter

---

## Updated Package.swift

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Tokemon",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        // Existing dependencies
        .package(url: "https://github.com/orchetect/MenuBarExtraAccess.git", from: "1.2.2"),
        .package(url: "https://github.com/orchetect/SettingsAccess.git", from: "2.1.0"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),

        // NEW for v2: LemonSqueezy licensing
        .package(url: "https://github.com/kevinhermawan/swift-lemon-squeezy-license.git", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "Tokemon",
            dependencies: [
                "MenuBarExtraAccess",
                "SettingsAccess",
                "KeychainAccess",
                .product(name: "LemonSqueezyLicense", package: "swift-lemon-squeezy-license"),
            ],
            path: "Tokemon",
            exclude: ["Info.plist"]
        ),
    ]
)
```

---

## Integration Points with Existing Code

| Feature | Existing Code | Integration Approach |
|---------|---------------|---------------------|
| Licensing | N/A (new) | Create `LicenseManager` service alongside existing `TokenManager` |
| PDF Export | `UsageChartView`, `UsageDetailView`, `Theme` | Create `ReportView` composing existing views; render with ImageRenderer |
| CSV Export | `UsageDataPoint`, `UsageSnapshot` models | Add `CSVExporter` utility consuming existing models |
| Image Cards | `Theme`, `GradientColors`, `UsageChartView` | Create `ShareableCardView` using existing theme system and chart views |
| Multi-Account | `TokenManager`, `Constants.keychainService` | Add `AccountManager` for selection; extend `TokenManager` with account parameter |

---

## Dependencies NOT Recommended for v2

| Library | Why Not |
|---------|---------|
| TPPDF | Overkill for usage reports; ImageRenderer handles SwiftUI views natively |
| CSV.swift | Over-engineered for simple export; native string building sufficient |
| SwiftCSVExport | Same reasoning; no complex features needed |
| Custom LemonSqueezy client | LemonSqueezyLicense handles the API cleanly; fallback to URLSession only if unmaintained |

---

## Risk Assessment for v2 Additions

| Risk | Severity | Mitigation |
|------|----------|-----------|
| LemonSqueezyLicense unmaintained | Low | API is simple; can reimplement with URLSession if needed (~100 lines) |
| ImageRenderer limitations | Very Low | Tokemon doesn't use WebViews/Maps; all views are standard SwiftUI |
| Keychain conflicts between accounts | Low | Use unique service+account keys; thorough testing of account switching |
| Offline license validation | Medium | Cache license state; implement 7-day grace period before requiring re-validation |

---

## v2 Sources

### LemonSqueezy
- [swift-lemon-squeezy-license GitHub](https://github.com/kevinhermawan/swift-lemon-squeezy-license) - Swift SDK (v1.0.1) - MEDIUM confidence
- [LemonSqueezy License API Docs](https://docs.lemonsqueezy.com/api/license-api) - Official API reference - HIGH confidence
- [Validating License Keys Guide](https://docs.lemonsqueezy.com/guides/tutorials/license-keys) - Implementation guide - HIGH confidence

### PDF/Image Export
- [Apple ImageRenderer Documentation](https://developer.apple.com/documentation/swiftui/imagerenderer) - Official API - HIGH confidence
- [Hacking with Swift - SwiftUI View to PDF](https://www.hackingwithswift.com/quick-start/swiftui/how-to-render-a-swiftui-view-to-a-pdf) - Implementation guide - MEDIUM confidence
- [AppCoda - ImageRenderer PDF](https://www.appcoda.com/swiftui-imagerenderer-pdf/) - Practical examples - MEDIUM confidence
- [Swift with Majid - ImageRenderer](https://swiftwithmajid.com/2023/04/18/imagerenderer-in-swiftui/) - Scale and quality settings - MEDIUM confidence

### Multi-Account Keychain
- [KeychainAccess GitHub](https://github.com/kishikawakatsumi/KeychainAccess) - Already in use (v4.2.2) - HIGH confidence
- [Managing Multiple Accounts with Keychain](https://medium.com/@leekiereloo/seamlessly-manage-multiple-user-accounts-in-ios-with-keychain-9ed080638a25) - Pattern guidance - MEDIUM confidence

---

# v4.0 Raycast Extension: Stack Additions

**Researched:** 2026-02-18
**Scope:** Standalone Raycast extension for Claude usage monitoring
**Overall Confidence:** HIGH (verified via official Raycast documentation)

## Overview

This section covers the **standalone Raycast extension** that fetches Claude usage data directly via OAuth. The extension operates independently of Tokemon.app, sharing only the OAuth endpoints and data models conceptually.

**Key architectural constraint:** Raycast extensions run in Node.js, not Swift. The extension must reimplement OAuth flows and data fetching in TypeScript, not call Tokemon.app.

## Core Stack

| Technology | Version | Purpose | Why This Choice |
|------------|---------|---------|-----------------|
| **TypeScript** | 5.8+ | Primary language | Raycast requires TypeScript/JavaScript; TypeScript provides type safety matching existing Swift models |
| **React** | 19.x | UI framework | Raycast components are React-based; required by @raycast/api |
| **Node.js** | 22.14+ | Runtime | Raycast's required runtime version as of Feb 2026 |
| **@raycast/api** | ^1.104.x | Core extension API | Official Raycast components, OAuth, storage, preferences |
| **@raycast/utils** | ^1.17.x | Utilities | useFetch, useLocalStorage, OAuth utilities, caching |

## Package Dependencies

### Runtime Dependencies

```json
{
  "dependencies": {
    "@raycast/api": "^1.104.0",
    "@raycast/utils": "^1.17.0"
  }
}
```

**Rationale:**
- **@raycast/api**: Core requirement for all Raycast extensions. Provides `OAuth.PKCEClient`, `LocalStorage`, `MenuBarExtra`, `Form`, preferences API, and all UI components.
- **@raycast/utils**: Utility hooks (`useFetch`, `usePromise`, `useLocalStorage`) that significantly reduce boilerplate for data fetching and caching.

### Development Dependencies

```json
{
  "devDependencies": {
    "@raycast/eslint-config": "^2.1.1",
    "@types/node": "^22.x",
    "@types/react": "^19.x",
    "eslint": "^9.x",
    "prettier": "^3.5.x",
    "typescript": "^5.8.x"
  }
}
```

**Rationale:**
- **@raycast/eslint-config**: Official ESLint config with Raycast-specific rules; required for store submission.
- **TypeScript 5.8+**: Required for Node 22 compatibility and latest language features.
- **ESLint 9**: New flat config format used by Raycast since v1.48.8.

## Key Libraries by Feature

### OAuth & Authentication

| Library | Source | Purpose |
|---------|--------|---------|
| `OAuth.PKCEClient` | @raycast/api | PKCE OAuth flow with built-in overlay, redirect handling, token storage |
| `LocalStorage` | @raycast/api | Encrypted local storage for refresh tokens and credentials |
| Preferences API | @raycast/api | Password-type preferences for manual token entry fallback |

**Why native Raycast OAuth:**
1. Built-in PKCE support (required for Claude OAuth)
2. Automatic secure token storage in Raycast's encrypted database
3. Native OAuth overlay UI with provider branding
4. Handles redirect URIs automatically

### Data Fetching

| Library | Source | Purpose |
|---------|--------|---------|
| `useFetch` | @raycast/utils | HTTP requests with caching, loading states, error handling |
| `fetch` | Node.js native | Raw fetch for token refresh endpoint |
| `useLocalStorage` | @raycast/utils | Persist cached usage data between sessions |

**Why useFetch over raw fetch:**
- Stale-while-revalidate caching built-in
- Automatic loading/error state management
- `keepPreviousData` prevents UI flicker during refresh
- `failureToastOptions` for user-friendly error messages

### Menu Bar Integration

| Component | Source | Purpose |
|-----------|--------|---------|
| `MenuBarExtra` | @raycast/api | Menu bar icon and dropdown menu |
| `MenuBarExtra.Item` | @raycast/api | Individual menu items with actions |
| `MenuBarExtra.Section` | @raycast/api | Grouped menu sections |

**Configuration in package.json:**
```json
{
  "commands": [
    {
      "name": "menu-bar",
      "title": "Usage Menu Bar",
      "mode": "menu-bar",
      "interval": "5m"
    }
  ]
}
```

### User Preferences

| Type | Use Case | Storage |
|------|----------|---------|
| `textfield` | Display name, custom labels | Raycast preferences |
| `password` | Manual OAuth token entry | Raycast secure storage |
| `dropdown` | Alert threshold selection | Raycast preferences |
| `checkbox` | Enable/disable features | Raycast preferences |

## Integration Points

### Claude OAuth Endpoint (Existing)

The extension will call the same endpoints as Tokemon.app:

```typescript
// Usage endpoint
const USAGE_URL = "https://api.anthropic.com/api/oauth/usage";

// Token refresh endpoint
const TOKEN_REFRESH_URL = "https://console.anthropic.com/v1/oauth/token";

// OAuth client ID (Claude Code's official ID)
const CLIENT_ID = "9d1c250a-e61b-44d9-88ed-5944d1962f5e";
```

### Response Model (Port from Swift)

```typescript
interface OAuthUsageResponse {
  five_hour?: UsageWindow;
  seven_day?: UsageWindow;
  seven_day_oauth_apps?: UsageWindow;
  seven_day_opus?: UsageWindow;
  seven_day_sonnet?: UsageWindow;
  extra_usage?: ExtraUsage;
}

interface UsageWindow {
  utilization: number;  // 0-100
  resets_at?: string;   // ISO-8601
}

interface ExtraUsage {
  is_enabled: boolean;
  monthly_limit?: number;  // cents
  used_credits?: number;   // cents
  utilization?: number;    // 0-100
}
```

### Token Refresh Flow

```typescript
// Raycast PKCE client handles most of this, but for refresh:
async function refreshToken(refreshToken: string): Promise<TokenResponse> {
  const params = new URLSearchParams({
    grant_type: "refresh_token",
    refresh_token: refreshToken,
    client_id: CLIENT_ID,
  });

  const response = await fetch(TOKEN_REFRESH_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: params,
  });

  return response.json();
}
```

## File Structure

```
tokemon-raycast/
  package.json           # Manifest + dependencies
  tsconfig.json          # TypeScript config (auto-generated)
  eslint.config.js       # ESLint flat config
  .prettierrc            # Prettier rules
  assets/
    icon.png             # Extension icon (512x512)
    command-icon.png     # Command-specific icons
  src/
    usage-dashboard.tsx  # Main usage view command
    menu-bar.tsx         # MenuBarExtra command
    configure-alerts.tsx # Alert configuration form
    switch-profile.tsx   # Profile switcher command
    lib/
      oauth.ts           # OAuth client wrapper
      api.ts             # API calls (usage, refresh)
      types.ts           # TypeScript interfaces
      storage.ts         # LocalStorage helpers
```

## What NOT to Use

### DO NOT Include

| Technology | Reason |
|------------|--------|
| **Swift/SwiftUI** | Raycast extensions are Node.js only; cannot call native code |
| **Tokemon.app IPC** | Extension must be standalone; no dependency on app running |
| **keytar/node-keychain** | Raycast restricts direct Keychain access; use built-in OAuth/LocalStorage |
| **External HTTP libraries** (axios, got) | Native fetch + useFetch sufficient; avoid bundle bloat |
| **State management libraries** (Redux, Zustand) | React hooks + Raycast utilities sufficient for this scope |
| **Testing frameworks** | Raycast extensions don't have official testing story; manual testing required |
| **Database packages** (SQLite, better-sqlite3) | LocalStorage + file-based caching sufficient |

### Avoid These Patterns

| Pattern | Why Avoid | Instead |
|---------|-----------|---------|
| Reading Claude Code keychain directly | Raycast blocks Keychain Access requests for store submission | Use Raycast OAuth flow or manual token entry |
| Polling with setInterval | Raycast handles background refresh via `interval` in manifest | Configure `"interval": "5m"` in command |
| Complex state machines | Overkill for extension scope | React useState + useEffect |
| External config files | Raycast preferences are the standard | Define in package.json `preferences` |

## OAuth Strategy Decision

### Option A: Full OAuth PKCE Flow (Recommended)

Use Raycast's built-in `OAuth.PKCEClient` to authenticate directly with Claude.

**Pros:**
- Native UX with Raycast OAuth overlay
- Automatic token storage and refresh
- No manual token copying

**Cons:**
- Requires Claude to support PKCE redirect to Raycast (may need verification)
- More complex initial implementation

### Option B: Manual Token Entry (Fallback)

User copies OAuth token from Claude Code's keychain and pastes into Raycast preferences.

**Pros:**
- Guaranteed to work (no OAuth redirect dependency)
- Simpler implementation

**Cons:**
- Poor UX (token copying is tedious)
- Token expiry requires re-entry

### Recommendation

**Implement Option A with Option B as fallback.** Start with PKCE flow; if Claude's OAuth doesn't support Raycast redirect URIs, fall back to password preference for manual token entry.

## Installation Commands

```bash
# Create new extension (Raycast CLI)
npx create-raycast-extension tokemon-raycast

# Or manually:
mkdir tokemon-raycast && cd tokemon-raycast
npm init -y
npm install @raycast/api @raycast/utils
npm install -D @raycast/eslint-config @types/node @types/react eslint prettier typescript

# Development
npm run dev

# Build for store
npm run build
npm run lint
```

## Raycast Extension Sources

### Official Documentation (HIGH confidence)
- [Raycast API Introduction](https://developers.raycast.com) - Core API reference
- [OAuth | Raycast API](https://developers.raycast.com/api-reference/oauth) - PKCE flow, token storage
- [Menu Bar Commands | Raycast API](https://developers.raycast.com/api-reference/menu-bar-commands) - MenuBarExtra component
- [Storage | Raycast API](https://developers.raycast.com/api-reference/storage) - LocalStorage API
- [Security | Raycast API](https://developers.raycast.com/information/security) - Keychain restrictions
- [@raycast/utils Getting Started](https://developers.raycast.com/utilities/getting-started) - Utility hooks
- [useFetch | Raycast API](https://developers.raycast.com/utilities/react-hooks/usefetch) - Data fetching patterns
- [Preferences | Raycast API](https://developers.raycast.com/api-reference/preferences) - User preferences

### Package Versions (HIGH confidence)
- [@raycast/api npm](https://www.npmjs.com/package/@raycast/api) - v1.104.5 (Feb 2026)
- [@raycast/utils npm](https://www.npmjs.com/package/@raycast/utils) - Peer dependency on @raycast/api
- [@raycast/eslint-config npm](https://www.npmjs.com/package/@raycast/eslint-config) - v2.1.1

### Reference Extensions (MEDIUM confidence)
- [CCUsage Raycast Extension](https://www.raycast.com/nyatinte/ccusage) - Existing Claude usage extension using ccusage CLI
- [GitLab Raycast Extension](https://github.com/raycast/extensions/blob/main/extensions/gitlab/package.json) - Reference package.json structure

### Existing Tokemon Codebase (verified)
- `/Users/richardparr/Tokemon/Tokemon/Utilities/Constants.swift` - OAuth endpoints, client ID
- `/Users/richardparr/Tokemon/Tokemon/Models/OAuthUsageResponse.swift` - Response model structure
- `/Users/richardparr/Tokemon/Tokemon/Services/OAuthClient.swift` - Fetch + refresh flow

---
*Stack research for: Tokemon v4.0 Raycast Extension*
*Updated: 2026-02-18*
