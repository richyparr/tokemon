# Architecture Patterns: ClaudeMon v2 Pro Features

**Domain:** Feature integration for existing macOS menu bar app
**Researched:** 2026-02-14
**Mode:** Integration architecture (subsequent milestone)

## Existing Architecture Overview

ClaudeMon v1 uses a clean @Observable pattern with clear separation of concerns:

```
ClaudeMonApp (@main)
    |
    +-- UsageMonitor (@Observable) ---- primary state holder
    |       |-- oauthEnabled, jsonlEnabled, showExtraUsage
    |       |-- currentUsage: UsageSnapshot
    |       |-- usageHistory: [UsageDataPoint]
    |       |-- onUsageChanged, onAlertCheck callbacks
    |       +-- HistoryStore.shared (actor)
    |
    +-- AlertManager (@Observable) ---- threshold checking
    |       |-- alertThreshold, notificationsEnabled
    |       +-- currentAlertLevel
    |
    +-- ThemeManager (@Observable) ---- theming
    |       +-- selectedTheme: AppTheme
    |
    +-- StatusItemManager (@MainActor) ---- menu bar rendering
    |
    +-- TokenManager (struct) ---- reads Claude Code Keychain
    |
    +-- OAuthClient (struct) ---- API calls with token refresh
    |
    +-- AdminAPIClient (actor) ---- optional org API
            +-- separate Keychain service
```

**Data Flow:**
1. UsageMonitor polls via Timer (configurable interval)
2. OAuthClient.fetchUsageWithTokenRefresh() -> UsageSnapshot
3. UsageMonitor updates currentUsage + records to HistoryStore
4. Callbacks trigger StatusItemManager.update() and AlertManager.checkUsage()
5. Views observe @Observable properties directly

---

## Feature 1: LemonSqueezy Licensing

**Question:** Where does validation happen? How to gate features?

### Integration Architecture

```
NEW: LicenseManager (@Observable, @MainActor)
    |
    |-- licenseKey: String? (Keychain)
    |-- instanceId: String? (Keychain)
    |-- licenseStatus: LicenseStatus enum
    |-- isProUser: Bool (computed)
    |-- validationError: String?
    |
    +-- LemonSqueezyClient (struct, async)
            |-- activate(key:instanceName:)
            |-- validate(key:instanceId:)
            |-- deactivate(key:instanceId:)
```

### Status Enum

```swift
enum LicenseStatus: Codable {
    case free                    // No license entered
    case validating              // Checking with server
    case active(expiresAt: Date?) // Valid Pro license
    case expired                 // License expired
    case invalid(String)         // Server rejected
    case offline(lastChecked: Date) // Cached validation
}
```

### Validation Strategy

| Scenario | Behavior |
|----------|----------|
| App launch | Validate if >24h since last check, else use cached |
| Manual "Validate" | Always call API |
| Network offline | Trust cached status for 7 days, then degrade to free |
| Server error | Retry 3x, then cache existing status |

**Confidence:** HIGH (based on [LemonSqueezyLicense Swift package](https://github.com/kevinhermawan/swift-lemon-squeezy-license))

### Feature Gating Pattern

**DO NOT** scatter `if isProUser` checks. Use a central gating approach:

```swift
// In views
@Environment(LicenseManager.self) private var license

// Feature check
ProFeatureGate(feature: .extendedHistory) {
    // Pro content
    ExtendedHistoryView()
} lockedContent: {
    // Upsell badge or disabled state
    ProUpsellBadge()
}

// Or computed property
var canExportPDF: Bool { license.isProUser }
```

### New Components

| Component | Type | Purpose |
|-----------|------|---------|
| `LicenseManager` | @Observable class | License state management |
| `LemonSqueezyClient` | struct | API calls to LemonSqueezy |
| `LicenseSettings` | View | Settings tab for license entry |
| `ProFeatureGate` | View | Reusable feature gating component |
| `ProUpsellBadge` | View | Consistent "Pro" indicator |

### Keychain Storage

Use separate Keychain service from Claude Code credentials:

```swift
private let keychain = Keychain(service: "com.claudemon.license")
// Keys: "license_key", "instance_id", "cached_status"
```

### Integration Points

1. **ClaudeMonApp.swift**: Add `@State private var licenseManager = LicenseManager()`
2. **SettingsView.swift**: Add "License" tab
3. **PopoverContentView.swift**: Pass environment, show Pro badge if licensed
4. **All Pro features**: Use `ProFeatureGate` wrapper

### Build Order Consideration

**Build FIRST** because other Pro features depend on gating.

---

## Feature 2: Multi-Account Support

**Question:** How to extend UsageMonitor and KeychainManager?

### Architecture Decision

**Option A:** Multiple UsageMonitor instances (rejected)
- Pro: Clean separation
- Con: Duplicates polling, complex state sync

**Option B:** Single UsageMonitor with account abstraction (recommended)
- Pro: Single source of truth, simpler UI binding
- Con: More complex internal state

### Account Model

```swift
struct Account: Identifiable, Codable {
    let id: UUID
    var name: String           // User-provided display name
    var keychainKey: String    // Unique key for credential lookup
    var isActive: Bool         // Currently selected account
    var lastUsage: UsageSnapshot?  // Cached for quick display
}
```

### Extended UsageMonitor

```swift
@Observable
@MainActor
final class UsageMonitor {
    // Existing...

    // NEW: Multi-account
    var accounts: [Account] = []
    var activeAccountId: UUID?

    var activeAccount: Account? {
        accounts.first { $0.id == activeAccountId }
    }

    // Modify refresh() to use activeAccount.keychainKey
}
```

### Extended TokenManager

Current TokenManager reads from Claude Code's Keychain using hardcoded service name. For multi-account:

```swift
struct TokenManager {
    // Existing static methods become instance methods or take account parameter

    static func getCredentials(for account: Account) throws -> ClaudeCredentials {
        // If account.keychainKey == "default" -> use existing Claude Code credentials
        // Otherwise -> use account-specific Keychain service
    }
}
```

**Critical:** The default account MUST continue reading Claude Code's Keychain (`Claude Code-credentials` service with username as key). Additional accounts would need manual credential entry (Pro feature complexity).

### Account Management UI

```
SettingsView
    +-- AccountsSettings (new tab)
            |-- Account list with active indicator
            |-- Add Account button
            |-- Edit account name
            +-- Switch active account
```

### New Components

| Component | Type | Purpose |
|-----------|------|---------|
| `Account` | struct | Account model |
| `AccountStore` | actor | Persist account list to disk |
| `AccountsSettings` | View | Account management UI |
| (modified) `TokenManager` | struct | Account-aware credential access |
| (modified) `UsageMonitor` | class | Multi-account state |

### Data Flow Changes

```
Before:
UsageMonitor -> TokenManager.getCredentials() -> single Keychain entry

After:
UsageMonitor -> activeAccount -> TokenManager.getCredentials(for:) -> account-specific Keychain
```

### Integration Points

1. **TokenManager.swift**: Add account parameter to credential methods
2. **UsageMonitor.swift**: Add accounts array, activeAccountId, modify refresh()
3. **SettingsView.swift**: Add "Accounts" tab
4. **PopoverContentView.swift**: Show account switcher if multiple accounts
5. **MenuBar display**: Could show active account name

### Build Order Consideration

**Build SECOND** after licensing. Multi-account is a Pro feature, needs gating.

---

## Feature 3: Analytics / Extended History

**Question:** How to extend HistoryStore?

### Current HistoryStore

```swift
actor HistoryStore {
    private var cache: [UsageDataPoint] = []
    private let maxAgeDays: Int = 30  // Trim after 30 days

    func append(_ point: UsageDataPoint) throws
    func getHistory() -> [UsageDataPoint]
    func getHistory(since cutoff: Date) -> [UsageDataPoint]
}
```

### Extended Architecture

```swift
actor HistoryStore {
    // Existing...

    // NEW: Extended retention for Pro
    private var maxAgeDays: Int {
        // Injected from LicenseManager or read from UserDefaults
        LicenseManager.shared.isProUser ? 365 : 30
    }

    // NEW: Aggregation for analytics
    func getDailyAverages(for period: DateInterval) -> [DailyAggregate]
    func getWeeklyTrends() -> [WeeklyTrend]
    func getPeakUsageHours() -> [Int: Double]  // hour -> avg percentage
}
```

### New Analytics Models

```swift
struct DailyAggregate: Identifiable {
    let id: Date  // Day start
    let averageUsage: Double
    let peakUsage: Double
    let dataPointCount: Int
}

struct WeeklyTrend {
    let weekStart: Date
    let averageUsage: Double
    let trend: TrendDirection  // up, down, stable
}

enum TrendDirection {
    case up, down, stable
}
```

### New Components

| Component | Type | Purpose |
|-----------|------|---------|
| `DailyAggregate` | struct | Daily rollup model |
| `WeeklyTrend` | struct | Weekly comparison model |
| `AnalyticsView` | View | Extended analytics dashboard |
| `HistoryExporter` | struct | Export history to CSV/PDF |
| (modified) `HistoryStore` | actor | Extended retention + aggregation |

### Integration Points

1. **HistoryStore.swift**: Add aggregation methods, dynamic maxAgeDays
2. **UsageChartView.swift**: Add extended time ranges (30d, 90d, 365d) for Pro
3. **SettingsView.swift**: Add "Analytics" section or expand "General"
4. **New AnalyticsView**: Deep-dive analytics (accessible from Settings or popover)

### Build Order Consideration

**Build THIRD** after multi-account. Uses Pro gating, extends existing HistoryStore.

---

## Feature 4: PDF/CSV Export

**Question:** Where in the view hierarchy?

### Export Architecture

```swift
struct ExportManager {
    // CSV export
    static func exportCSV(
        dataPoints: [UsageDataPoint],
        dateRange: DateInterval
    ) -> Data

    // PDF export - uses ImageRenderer
    @MainActor
    static func exportPDF(
        content: some View,
        title: String
    ) -> Data
}
```

### Integration Strategy

**Entry Points:**
1. **PopoverContentView** - "Export" button in footer menu
2. **AnalyticsView** - "Export Report" button
3. **SettingsView** - "Export History" in General tab

**UI Pattern:**

```swift
Menu("Export...") {
    Button("Export CSV...") { showCSVExport = true }
    Button("Export PDF Report...") { showPDFExport = true }
}
.fileExporter(
    isPresented: $showCSVExport,
    document: CSVDocument(data: exportData),
    contentType: .commaSeparatedText,
    defaultFilename: "claudemon-usage-\(dateString).csv"
)
```

### PDF Report Structure

```
+----------------------------------+
| ClaudeMon Usage Report           |
| Generated: Feb 14, 2026          |
+----------------------------------+
| Summary                          |
| - Total data points: 1,234       |
| - Date range: Jan 1 - Feb 14     |
| - Average usage: 45%             |
+----------------------------------+
| [Usage Chart Image]              |
|                                  |
+----------------------------------+
| Daily Breakdown (table)          |
| Date       | Avg | Peak | Count  |
| 2026-02-14 | 52% | 87%  | 24     |
| ...                              |
+----------------------------------+
```

### ImageRenderer for PDF

**Confidence:** HIGH (based on [Hacking with Swift ImageRenderer tutorial](https://www.hackingwithswift.com/quick-start/swiftui/how-to-render-a-swiftui-view-to-a-pdf))

```swift
@MainActor
func renderPDF(content: some View) -> Data {
    let renderer = ImageRenderer(content: content)

    var pdfData = Data()
    renderer.render { size, render in
        var mediaBox = CGRect(origin: .zero, size: size)

        guard let consumer = CGDataConsumer(data: pdfData as! CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)
        else { return }

        context.beginPDFPage(nil)
        render(context)
        context.endPDFPage()
        context.closePDF()
    }

    return pdfData
}
```

### New Components

| Component | Type | Purpose |
|-----------|------|---------|
| `ExportManager` | struct | CSV/PDF generation logic |
| `CSVDocument` | FileDocument | SwiftUI file exporter wrapper |
| `PDFReportView` | View | Formatted report layout for PDF |
| `ExportSettingsView` | View | Export options (date range, format) |

### Integration Points

1. **PopoverContentView.swift**: Add export menu item to gear menu
2. **New ExportManager.swift**: Export logic
3. **New PDFReportView.swift**: Report layout (rendered to PDF)

### Build Order Consideration

**Build FOURTH** after analytics. Uses HistoryStore aggregation methods.

---

## Feature 5: Shareable Images

**Question:** How to render SwiftUI to image?

### Architecture

```swift
struct ShareableImageGenerator {
    @MainActor
    static func generateUsageCard(
        usage: UsageSnapshot,
        theme: ThemeColors,
        displayScale: CGFloat
    ) -> NSImage

    @MainActor
    static func generateChartImage(
        dataPoints: [UsageDataPoint],
        theme: ThemeColors,
        displayScale: CGFloat
    ) -> NSImage
}
```

### ImageRenderer Usage (macOS)

**Confidence:** HIGH (based on [Apple Documentation](https://developer.apple.com/documentation/swiftui/imagerenderer) and [Create with Swift tutorial](https://www.createwithswift.com/exporting-swiftui-views-to-images-with-imagerender/))

```swift
@MainActor
func generateImage(from view: some View, scale: CGFloat = 2.0) -> NSImage? {
    let renderer = ImageRenderer(content: view)
    renderer.scale = scale  // 2.0 for Retina
    return renderer.nsImage
}
```

**macOS-specific:** Use `renderer.nsImage` (not `uiImage`)

### Share Card Design

```
+---------------------------+
| ClaudeMon                 |
|                           |
|     72%                   |
|   5-hour usage            |
|                           |
| Resets in 2h 15m          |
| 7-day: 45%                |
+---------------------------+
```

### Integration Points

1. **PopoverContentView.swift**: Add "Share" button/menu
2. **New ShareableCardView.swift**: Shareable card layout
3. **New ShareableImageGenerator.swift**: ImageRenderer wrapper
4. **NSSharingServicePicker**: macOS share sheet

### Share Flow

```swift
Button("Share...") {
    let cardView = ShareableCardView(usage: monitor.currentUsage, theme: themeColors)
    if let image = ShareableImageGenerator.generateUsageCard(from: cardView) {
        let picker = NSSharingServicePicker(items: [image])
        picker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
    }
}
```

### New Components

| Component | Type | Purpose |
|-----------|------|---------|
| `ShareableCardView` | View | Card layout for sharing |
| `ShareableImageGenerator` | struct | ImageRenderer wrapper |

### Build Order Consideration

**Build FIFTH** (last). Standalone feature, no dependencies on other Pro features.

---

## Component Summary

### New Components (9 total)

| Component | Type | Pro Feature |
|-----------|------|-------------|
| `LicenseManager` | @Observable class | Licensing |
| `LemonSqueezyClient` | struct | Licensing |
| `AccountStore` | actor | Multi-account |
| `Account` | struct | Multi-account |
| `ExportManager` | struct | Export |
| `PDFReportView` | View | Export |
| `ShareableCardView` | View | Sharing |
| `ShareableImageGenerator` | struct | Sharing |
| `AnalyticsView` | View | Analytics |

### Modified Components (5 total)

| Component | Modification |
|-----------|-------------|
| `UsageMonitor` | Add accounts array, activeAccountId |
| `TokenManager` | Account parameter for credentials |
| `HistoryStore` | Extended retention, aggregation methods |
| `SettingsView` | New tabs: License, Accounts |
| `PopoverContentView` | Export menu, share button, Pro badge |

### New Settings Tabs

| Tab | Purpose |
|-----|---------|
| License | Enter/validate license key |
| Accounts | Multi-account management (Pro) |

---

## Suggested Build Order

Based on dependencies:

```
Phase 1: Licensing Infrastructure
    - LicenseManager
    - LemonSqueezyClient
    - LicenseSettings view
    - ProFeatureGate component
    - Wire into ClaudeMonApp

    Dependencies: None (foundation for all Pro features)

Phase 2: Multi-Account
    - Account model
    - AccountStore actor
    - TokenManager modifications
    - UsageMonitor modifications
    - AccountsSettings view

    Dependencies: Licensing (for Pro gating)

Phase 3: Extended Analytics
    - HistoryStore aggregation methods
    - Extended retention (Pro)
    - AnalyticsView
    - Extended ChartTimeRange options

    Dependencies: Licensing, builds on existing HistoryStore

Phase 4: Export (PDF/CSV)
    - ExportManager
    - PDFReportView
    - CSVDocument
    - Export UI in popover/settings

    Dependencies: Analytics (uses aggregation methods)

Phase 5: Shareable Images
    - ShareableCardView
    - ShareableImageGenerator
    - Share menu integration

    Dependencies: None (can parallel with Phase 4)
```

### Phase Ordering Rationale

1. **Licensing first**: All other features need Pro gating
2. **Multi-account second**: Core data layer change, affects OAuth flow
3. **Analytics third**: Extends HistoryStore after it's stable
4. **Export fourth**: Uses analytics aggregation methods
5. **Sharing last**: Standalone, no blockers

---

## Confidence Assessment

| Feature | Confidence | Reason |
|---------|------------|--------|
| LemonSqueezy | HIGH | Well-documented Swift package, clear API |
| Multi-account | MEDIUM | Custom design, potential Keychain conflicts |
| Extended History | HIGH | Simple extension of existing actor |
| PDF Export | HIGH | ImageRenderer well-documented for macOS |
| CSV Export | HIGH | Trivial data formatting |
| Shareable Images | HIGH | ImageRenderer + NSSharingServicePicker |

---

## Sources

### Licensing
- [LemonSqueezyLicense Swift Package](https://github.com/kevinhermawan/swift-lemon-squeezy-license) - Swift package API
- [LemonSqueezy License API Docs](https://docs.lemonsqueezy.com/api/license-api) - Official API documentation

### Image/PDF Export
- [Hacking with Swift - ImageRenderer](https://www.hackingwithswift.com/quick-start/swiftui/how-to-convert-a-swiftui-view-to-an-image) - SwiftUI to image
- [Hacking with Swift - PDF Rendering](https://www.hackingwithswift.com/quick-start/swiftui/how-to-render-a-swiftui-view-to-a-pdf) - SwiftUI to PDF
- [Create with Swift - ImageRenderer](https://www.createwithswift.com/exporting-swiftui-views-to-images-with-imagerender/) - Detailed tutorial

### Multi-account Keychain
- [KeychainAccess GitHub](https://github.com/kishikawakatsumi/KeychainAccess) - Library used by ClaudeMon
- [Swift Keychain Secure Storage](https://oneuptime.com/blog/post/2026-02-02-swift-keychain-secure-storage/view) - Best practices

### File Export
- [SwiftUI fileExporter](https://www.hackingwithswift.com/quick-start/swiftui/how-to-export-files-using-fileexporter) - Native SwiftUI export
- [Swift with Majid - File Export](https://swiftwithmajid.com/2023/05/10/file-importing-and-exporting-in-swiftui/) - Comprehensive guide
