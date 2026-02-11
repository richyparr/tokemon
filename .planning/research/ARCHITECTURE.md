# Architecture Research

**Domain:** macOS menu bar utility with WidgetKit and floating window
**Researched:** 2026-02-11
**Confidence:** HIGH

## System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                           │
│                                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────────┐     │
│  │  MenuBarExtra │  │   Floating   │  │   WidgetKit Extension  │     │
│  │  (popover)   │  │    Window    │  │   (separate process)   │     │
│  └──────┬───────┘  └──────┬───────┘  └────────────┬───────────┘     │
│         │                 │                        │                 │
├─────────┴─────────────────┴────────────────────────┼─────────────────┤
│                   SHARED STATE LAYER                │                 │
│                                                    │                 │
│  ┌──────────────────────────────────────────┐      │                 │
│  │          @Observable UsageMonitor        │      │                 │
│  │  (singleton, @MainActor, owns all data)  │      │                 │
│  └──────────────────┬───────────────────────┘      │                 │
│                     │                              │                 │
├─────────────────────┴──────────────────────────────┼─────────────────┤
│                   SERVICE LAYER                    │                 │
│                                                    │                 │
│  ┌──────────┐  ┌──────────┐  ┌─────────────┐      │                 │
│  │  LogFile │  │ ClaudeAI │  │  Claude API  │      │                 │
│  │  Parser  │  │  Scraper │  │   Client     │      │                 │
│  └──────────┘  └──────────┘  └─────────────┘      │                 │
│                                                    │                 │
├────────────────────────────────────────────────────┼─────────────────┤
│                   PERSISTENCE LAYER                │                 │
│                                                    │                 │
│  ┌────────────────────────────────────────────┐    │                 │
│  │          SwiftData ModelContainer          │    │                 │
│  │   (in App Group shared container)          │◄───┘                 │
│  └────────────────────────────────────────────┘  (reads via         │
│                                                   App Group)        │
│  ┌──────────────────────┐                                           │
│  │  UserDefaults (suite) │  (lightweight config shared w/ widget)   │
│  └──────────────────────┘                                           │
└─────────────────────────────────────────────────────────────────────┘
```

### Process Boundaries (Critical)

The system runs across **two separate processes**:

1. **Main App Process** -- contains the MenuBarExtra, floating window, all services, the @Observable state, SwiftData writes, notification scheduling, and polling timers. This is the "brain."

2. **Widget Extension Process** -- a separate process managed by the OS. It can only read from the shared App Group container. It cannot call into the main app's code. Communication is one-directional: the main app writes data, the widget reads it.

This process boundary is the single most important architectural constraint. The widget cannot subscribe to @Observable objects, cannot hold references to the main app's services, and runs on its own schedule controlled by WidgetKit's timeline system.

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| **App (entry point)** | Declares scenes (MenuBarExtra, WindowGroup), owns top-level @Observable state | `@main struct ClaudeMonApp: App` with `@State var monitor = UsageMonitor()` |
| **MenuBarExtra** | Primary UI surface; shows status icon + popover with usage summary | SwiftUI `MenuBarExtra` with `.menuBarExtraStyle(.window)` |
| **Floating Window** | Optional always-on-top compact usage display | `WindowGroup` with `.windowLevel(.floating)` (macOS 15+) or NSPanel subclass |
| **Widget Extension** | Notification Center widget showing usage at a glance | Separate target, `TimelineProvider`, reads from App Group |
| **UsageMonitor** | Central state: current usage, limits, history; drives all UI | `@Observable @MainActor class`, singleton owned by App |
| **Data Services** | Fetch raw data from Claude Code logs, Claude.ai, Claude API | Protocol-based, injected into UsageMonitor |
| **SwiftData Store** | Historical usage records, persistent across launches | `ModelContainer` in App Group shared container |
| **Notification Manager** | Schedules/fires macOS notifications at thresholds | Wraps `UNUserNotificationCenter` |

## Recommended Project Structure

```
ClaudeMon/
├── ClaudeMon/                    # Main app target
│   ├── ClaudeMonApp.swift        # @main, declares scenes
│   ├── Info.plist                # LSUIElement = YES
│   │
│   ├── Models/                   # SwiftData models (shared with widget)
│   │   ├── UsageRecord.swift     # @Model for historical data
│   │   ├── UsageSnapshot.swift   # Current state codable struct
│   │   └── ThemeConfig.swift     # Theme definitions
│   │
│   ├── Services/                 # Data fetching & business logic
│   │   ├── UsageMonitor.swift    # @Observable central state
│   │   ├── LogFileParser.swift   # Reads ~/.claude/ JSONL logs
│   │   ├── ClaudeAPIClient.swift # Claude API usage endpoint
│   │   ├── WebUsageService.swift # Claude.ai usage (if available)
│   │   ├── PollingScheduler.swift# Timer-based refresh coordination
│   │   └── NotificationManager.swift # UNUserNotificationCenter wrapper
│   │
│   ├── Views/                    # SwiftUI views
│   │   ├── MenuBar/
│   │   │   ├── MenuBarView.swift         # Content of MenuBarExtra popover
│   │   │   ├── UsageSummaryView.swift    # Compact usage display
│   │   │   └── StatusIconView.swift      # Dynamic menu bar icon
│   │   ├── FloatingWindow/
│   │   │   ├── FloatingWindowView.swift  # Compact floating overlay
│   │   │   └── FloatingPanel.swift       # NSPanel subclass (pre-macOS 15)
│   │   ├── Settings/
│   │   │   ├── SettingsView.swift        # Main settings container
│   │   │   ├── ThresholdSettings.swift   # Notification thresholds
│   │   │   └── AppearanceSettings.swift  # Theme selection
│   │   └── Shared/
│   │       ├── UsageGauge.swift          # Reusable usage gauge
│   │       └── UsageChart.swift          # Historical chart
│   │
│   ├── Theme/                    # Theming system
│   │   ├── Theme.swift           # Theme protocol + implementations
│   │   └── ThemeManager.swift    # @Observable theme state
│   │
│   └── Utilities/
│       ├── Constants.swift       # App Group ID, polling intervals
│       └── Extensions.swift      # Date, Number formatting
│
├── ClaudeMonWidget/              # Widget extension target
│   ├── ClaudeMonWidget.swift     # Widget definition + configuration
│   ├── ClaudeMonWidgetBundle.swift # Widget bundle entry point
│   ├── UsageTimelineProvider.swift # TimelineProvider implementation
│   ├── WidgetViews/
│   │   ├── SmallWidgetView.swift
│   │   ├── MediumWidgetView.swift
│   │   └── UsageEntryView.swift  # Shared entry rendering
│   └── Info.plist
│
├── Shared/                       # Code shared between BOTH targets
│   ├── Models/                   # SwiftData models (added to both targets)
│   │   └── UsageRecord.swift     # (same file, both targets)
│   ├── SharedDefaults.swift      # UserDefaults(suiteName:) wrapper
│   └── AppGroupConstants.swift   # Group ID, container URLs
│
└── ClaudeMon.xcodeproj
```

### Structure Rationale

- **ClaudeMon/ (main target):** Contains all app logic, services, and views. This is the only target that writes data and runs services. Keeping services here prevents the widget from accidentally trying to poll APIs.
- **ClaudeMonWidget/ (extension target):** Minimal code -- only reads shared data and renders it. No business logic, no networking, no polling.
- **Shared/:** SwiftData model files and App Group constants that must compile into both targets. Keep this minimal; only data definitions belong here.

## Architectural Patterns

### Pattern 1: Single @Observable State Owner

**What:** One `@Observable` class (`UsageMonitor`) owns all mutable usage state. All views read from it. All services write to it. No scattered state.

**When to use:** Always. This is the core pattern. The menu bar view, floating window, and settings all observe the same instance.

**Trade-offs:** Simple, predictable, easy to debug. Could become bloated if not decomposed. Mitigate by having UsageMonitor delegate to focused service objects.

**Example:**
```swift
@Observable
@MainActor
final class UsageMonitor {
    // Current state
    var currentUsage: UsageSnapshot = .empty
    var isPolling: Bool = false
    var lastUpdated: Date?

    // Services (injected)
    private let logParser: LogFileParser
    private let apiClient: ClaudeAPIClient
    private let store: ModelContainer

    // Polling
    private var pollTimer: Timer?

    func startPolling(interval: TimeInterval = 300) {
        pollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { await self?.refresh() }
        }
        Task { await refresh() } // Immediate first fetch
    }

    func refresh() async {
        isPolling = true
        defer { isPolling = false }

        // Gather from all sources
        let logUsage = await logParser.currentUsage()
        let apiUsage = try? await apiClient.fetchUsage()

        // Merge and update
        currentUsage = merge(logUsage, apiUsage)
        lastUpdated = Date()

        // Persist for widget
        try? writeToSharedContainer(currentUsage)

        // Trigger widget refresh
        WidgetCenter.shared.reloadAllTimelines()

        // Check notification thresholds
        NotificationManager.shared.evaluateThresholds(currentUsage)
    }
}
```

### Pattern 2: App Group Shared Container for Widget Communication

**What:** The main app writes usage data to a shared App Group container. The widget extension reads from it during timeline generation. No direct IPC.

**When to use:** Always, for any data the widget needs. This is the only supported communication channel between the main app and widget extension.

**Trade-offs:** Simple, reliable, Apple-blessed. Data can be slightly stale (widget refreshes on its own schedule). Mitigate with `WidgetCenter.shared.reloadAllTimelines()` after writes.

**Example:**
```swift
// Shared/AppGroupConstants.swift (both targets)
enum AppGroup {
    static let identifier = "group.com.yourname.claudemon"

    static var containerURL: URL {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: identifier
        )!
    }

    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: identifier)!
    }
}

// Main app writes:
func writeToSharedContainer(_ snapshot: UsageSnapshot) throws {
    let data = try JSONEncoder().encode(snapshot)
    let url = AppGroup.containerURL.appendingPathComponent("current_usage.json")
    try data.write(to: url)

    // Also write to UserDefaults for lightweight access
    AppGroup.sharedDefaults.set(snapshot.percentUsed, forKey: "percentUsed")
    AppGroup.sharedDefaults.set(Date().timeIntervalSince1970, forKey: "lastUpdated")
}

// Widget reads:
struct UsageTimelineProvider: TimelineProvider {
    func getTimeline(in context: Context, completion: @escaping (Timeline<UsageEntry>) -> Void) {
        let url = AppGroup.containerURL.appendingPathComponent("current_usage.json")
        let snapshot = try? JSONDecoder().decode(UsageSnapshot.self, from: Data(contentsOf: url))

        let entry = UsageEntry(date: Date(), usage: snapshot ?? .empty)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}
```

### Pattern 3: LSUIElement Agent App with Hybrid Window Management

**What:** The app runs as a background agent (no Dock icon) with MenuBarExtra as the primary UI. A floating window and settings window can be summoned on demand, requiring activation policy toggling.

**When to use:** For menu-bar-primary apps that occasionally need windows.

**Trade-offs:** Clean UX (no Dock clutter), but toggling `NSApp.setActivationPolicy()` between `.accessory` and `.regular` is necessary when showing/hiding windows to ensure proper focus behavior. This is fiddly but well-documented.

**Example:**
```swift
@main
struct ClaudeMonApp: App {
    @State private var monitor = UsageMonitor()
    @State private var showFloatingWindow = false

    var body: some Scene {
        // Primary: menu bar popover
        MenuBarExtra {
            MenuBarView()
                .environment(monitor)
        } label: {
            StatusIconView(usage: monitor.currentUsage)
        }
        .menuBarExtraStyle(.window)

        // Optional: floating window (macOS 15+)
        WindowGroup(id: "floating", for: UUID.self) { _ in
            FloatingWindowView()
                .environment(monitor)
        }
        .windowLevel(.floating)
        .windowStyle(.plain)
        .windowResizability(.contentSize)

        // Settings
        Settings {
            SettingsView()
                .environment(monitor)
        }
    }
}
```

### Pattern 4: Protocol-Based Data Source Abstraction

**What:** Each data source (Claude Code logs, Claude.ai, Claude API) conforms to a common protocol. The UsageMonitor doesn't know or care which sources are active.

**When to use:** Always. This makes it trivial to add/remove data sources and to mock them in tests/previews.

**Trade-offs:** Slight indirection. Worth it for testability and future extensibility.

**Example:**
```swift
protocol UsageDataSource: Sendable {
    var name: String { get }
    var isAvailable: Bool { get async }
    func fetchUsage() async throws -> RawUsageData
}

struct ClaudeCodeLogSource: UsageDataSource {
    let name = "Claude Code"
    var isAvailable: Bool {
        get async {
            FileManager.default.fileExists(atPath:
                NSHomeDirectory() + "/.claude/projects")
        }
    }
    func fetchUsage() async throws -> RawUsageData {
        // Parse JSONL files from ~/.claude/projects/
    }
}
```

## Data Flow

### Primary Data Flow (Polling Cycle)

```
Timer fires (every N minutes)
    |
    v
UsageMonitor.refresh()
    |
    ├──> LogFileParser.fetchUsage()     ──> Reads ~/.claude/projects/*.jsonl
    ├──> ClaudeAPIClient.fetchUsage()   ──> GET /api/usage (if API key set)
    └──> WebUsageService.fetchUsage()   ──> Scrape/parse claude.ai (if configured)
         |
         v
    Merge results into UsageSnapshot
         |
         ├──> Update @Observable properties  ──> MenuBarExtra re-renders
         │                                   ──> Floating Window re-renders
         │
         ├──> Persist to SwiftData           ──> Historical record stored
         │
         ├──> Write to App Group container   ──> Widget can read on next timeline
         │         |
         │         v
         │    WidgetCenter.shared.reloadAllTimelines()
         │         |
         │         v
         │    Widget extension wakes, reads shared container, renders
         │
         └──> NotificationManager.evaluateThresholds()
                   |
                   v
              UNUserNotificationCenter.add() (if threshold crossed)
```

### Widget Data Flow (Independent Process)

```
System wakes widget extension (timeline expired or reload requested)
    |
    v
UsageTimelineProvider.getTimeline()
    |
    v
Read current_usage.json from App Group container
    |
    v
Create TimelineEntry with usage data
    |
    v
Return Timeline with entries + next refresh policy
    |
    v
WidgetKit renders view statically (no live @Observable)
```

### User Action Flows

```
User clicks menu bar icon
    |
    v
MenuBarExtra popover appears (reads from @Observable UsageMonitor)
    |
    ├──> User clicks "Refresh" ──> UsageMonitor.refresh() ──> (polling cycle)
    ├──> User clicks "Settings" ──> Open Settings window
    ├──> User toggles floating window ──> openWindow(id: "floating")
    └──> User clicks "Quit" ──> NSApp.terminate(nil)
```

### Notification Flow

```
UsageMonitor.refresh() completes
    |
    v
NotificationManager.evaluateThresholds(snapshot)
    |
    ├── usage >= criticalThreshold (e.g., 90%)
    │       └──> Schedule UNNotification with .critical sound
    │
    ├── usage >= warningThreshold (e.g., 75%)
    │       └──> Schedule UNNotification with .default sound
    │
    └── usage < warningThreshold
            └──> No notification (clear any pending)
```

### Key Data Flows Summary

1. **Polling -> State Update:** Timer-driven refresh gathers data from all sources, updates the single @Observable, triggers UI re-renders automatically via SwiftUI observation.
2. **Main App -> Widget:** One-directional. Main app writes JSON/UserDefaults to App Group container, calls `reloadAllTimelines()`. Widget reads on its own schedule.
3. **State -> Notifications:** After each refresh, the notification manager compares current usage against user-configured thresholds and fires local notifications as needed.
4. **State -> Persistence:** Every refresh writes a `UsageRecord` to SwiftData for historical charting. SwiftData container lives in the App Group so the widget could also query history.

## Scaling Considerations

This is a single-user desktop app, so "scaling" means handling data volume and system resource usage gracefully.

| Concern | Day 1 | After 6 months | After 2+ years |
|---------|-------|-----------------|-----------------|
| SwiftData records | Hundreds | Tens of thousands | Hundreds of thousands |
| Polling overhead | Negligible | Negligible | Negligible |
| Log file parsing | Fast (small files) | Slower (large JSONL files) | Needs pruning/indexing |
| Memory footprint | < 20 MB | < 30 MB | Could grow if history loaded eagerly |

### Scaling Priorities

1. **First bottleneck: Log file growth.** Claude Code JSONL logs grow indefinitely. Parse only recent/relevant files, not the entire history. Use file modification dates to skip unchanged files. Cache parsed results.

2. **Second bottleneck: SwiftData query performance.** After months of hourly records, chart queries could slow down. Use date-range predicates, pre-aggregate daily/weekly summaries, and consider a retention policy (delete records older than N months).

3. **Third bottleneck: Widget refresh budget.** WidgetKit limits how often widgets can refresh. Don't rely on high-frequency widget updates. The menu bar view is the real-time surface; the widget is a convenience glance.

## Anti-Patterns

### Anti-Pattern 1: Putting Business Logic in the Widget Extension

**What people do:** Fetch API data, parse logs, or run polling timers inside the widget extension code.
**Why it's wrong:** The widget extension is a separate process with severe runtime constraints. It runs briefly when WidgetKit requests a timeline, then is suspended. Long-running tasks will be killed. Network requests may timeout. File parsing is wasteful because results can't be cached across invocations.
**Do this instead:** All data fetching and processing happens in the main app. The main app writes pre-computed results to the shared container. The widget reads and displays -- nothing more.

### Anti-Pattern 2: Using @ObservableObject Instead of @Observable

**What people do:** Use the older `ObservableObject` protocol with `@Published` properties, or mix both patterns.
**Why it's wrong:** `@Observable` (introduced in Swift 5.9 / macOS 14) provides finer-grained observation -- views only re-render when properties they actually read change. `ObservableObject` re-renders every subscriber when any `@Published` property changes, causing unnecessary work. Mixing both patterns creates confusion.
**Do this instead:** Use `@Observable` exclusively. Requires macOS 14+ deployment target, which is reasonable for a new app in 2026.

### Anti-Pattern 3: Sharing Live State with the Widget via In-Memory Objects

**What people do:** Try to pass `@Observable` objects or shared singletons to the widget, or use NotificationCenter/DistributedNotificationCenter for real-time updates.
**Why it's wrong:** The widget runs in a completely separate process. It cannot access the main app's memory space. DistributedNotificationCenter is unreliable for this purpose and not how WidgetKit is designed.
**Do this instead:** Write to the App Group shared container (file or UserDefaults). Trigger `WidgetCenter.shared.reloadAllTimelines()`. Accept that the widget will always show slightly stale data.

### Anti-Pattern 4: Sandboxing the App

**What people do:** Enable the App Sandbox because Xcode defaults to it or because they plan to distribute via the Mac App Store.
**Why it's wrong:** ClaudeMon needs to read `~/.claude/projects/` which is in the user's real home directory. A sandboxed app's `NSHomeDirectory()` returns the app's container, not the real home. You cannot add an entitlement to read arbitrary paths outside the sandbox. A sandboxed app fundamentally cannot read Claude Code's log files without user-initiated file selection via NSOpenPanel for each session -- terrible UX.
**Do this instead:** Distribute outside the Mac App Store. Disable App Sandbox. Use Hardened Runtime + Notarization for security. Distribute via GitHub releases + Sparkle for updates.

### Anti-Pattern 5: Tight Coupling Between Data Sources

**What people do:** Hardcode all three data sources (logs, API, web) into a single monolithic refresh function with no abstraction.
**Why it's wrong:** Not all users will have all sources configured. The Claude API client may not exist yet. Claude.ai scraping may break. Hardcoding makes it impossible to gracefully degrade or add new sources.
**Do this instead:** Use the protocol-based data source pattern. Each source is independent. The monitor iterates available sources and merges results.

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| **Claude Code logs** | File system read (`~/.claude/projects/`) | JSONL format. Requires non-sandboxed app. Files are per-project, URL-encoded directory names. Parse session files for token counts. |
| **Claude API** | REST API via URLSession | Requires user-provided API key. Usage endpoint provides token counts and billing data. Store key in Keychain. |
| **Claude.ai web** | TBD (scraping or unofficial API) | Least reliable source. May require authentication tokens. Consider making this optional/experimental. |
| **macOS Notifications** | UNUserNotificationCenter | Requires permission request on first launch. Support actionable notifications (e.g., "Open Dashboard"). |
| **Sparkle** | Auto-update framework | Standard for non-App-Store macOS apps. Add as SPM dependency. Requires an appcast XML hosted somewhere (GitHub Pages works). |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| Main App <-> Widget Extension | App Group shared container (JSON file + UserDefaults suite) | One-directional: app writes, widget reads. Trigger reload via WidgetCenter. |
| MenuBarExtra <-> Floating Window | Shared @Observable via .environment() | Both read from the same UsageMonitor instance. Same process. |
| MenuBarExtra <-> Settings | Shared @Observable + @AppStorage | Settings modify UserDefaults; UsageMonitor reads them. Same process. |
| Services <-> UsageMonitor | Direct method calls (async/await) | Services are owned by UsageMonitor. No IPC needed. |
| UsageMonitor <-> SwiftData | ModelContext operations | Write after each refresh. Read for historical charts. |
| UsageMonitor <-> Notifications | Direct method calls | NotificationManager checks thresholds after each state update. |

## Build Order Implications

The architecture has clear dependency layers that dictate build order:

```
Phase 1: Foundation
    Models/ + Shared/ + AppGroupConstants
    (everything else depends on data models)
        |
        v
Phase 2: Core Services
    UsageMonitor + LogFileParser (simplest data source first)
    SwiftData persistence
        |
        v
Phase 3: Primary UI
    MenuBarExtra + MenuBarView + StatusIconView
    (now you can see data flowing through the system)
        |
        v
Phase 4: Notifications
    NotificationManager + threshold evaluation
    (builds on UsageMonitor state)
        |
        v
Phase 5: Widget
    WidgetKit extension + TimelineProvider + WidgetViews
    (depends on App Group container being populated by Phase 2)
        |
        v
Phase 6: Floating Window
    FloatingWindowView + NSPanel or .windowLevel(.floating)
    (independent of widget, but needs UsageMonitor from Phase 2)
        |
        v
Phase 7: Additional Data Sources
    ClaudeAPIClient + WebUsageService
    (plugs into existing protocol-based architecture)
        |
        v
Phase 8: Polish
    Theming, settings refinement, Sparkle auto-updates
```

**Key dependency insight:** The widget extension (Phase 5) must come after the main app can write to the shared container (Phase 2). But the widget UI is independent of the menu bar UI. The floating window (Phase 6) has no dependency on the widget and could be built in parallel.

**Minimum viable loop:** After Phases 1-3, you have a working menu bar app that reads Claude Code logs and displays usage. Everything else is additive.

## Sources

- [MenuBarExtra Apple Documentation](https://developer.apple.com/documentation/swiftui/menubarextra) -- HIGH confidence
- [Build a macOS menu bar utility in SwiftUI](https://nilcoalescing.com/blog/BuildAMacOSMenuBarUtilityInSwiftUI/) -- HIGH confidence
- [Creating a floating window in macOS 15](https://www.polpiella.dev/creating-a-floating-window-using-swiftui-in-macos-15) -- HIGH confidence, macOS 15+ APIs
- [Make a floating panel in SwiftUI (NSPanel approach)](https://cindori.com/developer/floating-panel) -- HIGH confidence, pre-macOS 15 fallback
- [How to access SwiftData from widgets](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-access-a-swiftdata-container-from-widgets) -- HIGH confidence
- [Sharing data with a widget (App Groups)](https://useyourloaf.com/blog/sharing-data-with-a-widget/) -- HIGH confidence
- [The Mac Menubar and SwiftUI (2025)](https://troz.net/post/2025/mac_menu_data/) -- MEDIUM confidence, state management patterns
- [Migrating to @Observable macro (Apple docs)](https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro) -- HIGH confidence
- [Showing Settings from menu bar items (2025)](https://steipete.me/posts/2025/showing-settings-from-macos-menu-bar-items) -- MEDIUM confidence, documents real-world pain points
- [LSUIElement Apple Documentation](https://developer.apple.com/documentation/bundleresources/information-property-list/lsuielement) -- HIGH confidence
- [Accessing files from the macOS App Sandbox](https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox) -- HIGH confidence, confirms sandbox limitations
- [Distributing Mac apps outside the App Store](https://www.rambo.codes/posts/2021-01-08-distributing-mac-apps-outside-the-app-store) -- MEDIUM confidence
- [Using Swift/SwiftUI to build a modern macOS Menu Bar app (Kyan)](https://kyan.com/insights/using-swift-swiftui-to-build-a-modern-macos-menu-bar-app) -- MEDIUM confidence
- [Claude Code log file location](https://github.com/daaain/claude-code-log) -- MEDIUM confidence, confirmed ~/.claude/projects/ path
- [SwiftUI macOS floating window/panel (Itsuki)](https://levelup.gitconnected.com/swiftui-macos-floating-window-panel-4eef94a20647) -- MEDIUM confidence

---
*Architecture research for: ClaudeMon -- macOS Claude usage monitoring app*
*Researched: 2026-02-11*
