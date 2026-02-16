# Phase 3: Usage Trends & API Integration - Research

**Researched:** 2026-02-13
**Domain:** SwiftUI Charts, Local Data Persistence, Burn Rate Algorithms, Anthropic Admin API
**Confidence:** HIGH

## Summary

Phase 3 requires four core capabilities: (1) storing historical usage data locally, (2) visualizing usage trends over time, (3) calculating burn rate and projecting time-to-limit, and (4) optionally connecting to the Anthropic Admin API for organization cost data.

**Swift Charts** (available macOS 13+, project targets macOS 14+) is Apple's native charting framework and the correct choice for visualization. It provides `LineMark` and `AreaMark` with built-in date axis support, gradient fills, and automatic accessibility. No third-party charting libraries are needed.

**For data persistence**, the phase has two reasonable options: SwiftData (native, integrated with SwiftUI) or simple JSON file storage (Codable to disk). Given the simple data model (timestamped usage snapshots) and the need for lightweight implementation, JSON file persistence is recommended. SwiftData adds complexity without proportional benefit for a flat time-series of ~1000 records.

**Burn rate calculation** follows a simple formula: `usage_per_hour = (current_usage - baseline_usage) / elapsed_hours`. Time-to-limit is derived as `remaining_capacity / burn_rate`. The implementation should use a rolling window (e.g., last 2-4 hours) for stable burn rate calculation.

**Anthropic Admin API** requires an Admin API key (`sk-ant-admin...`) and is only available for organization accounts with admin role. The `/v1/organizations/usage_report/messages` endpoint provides token-level usage breakdowns. This is optional functionality for org admins only.

**Primary recommendation:** Use Swift Charts with `LineMark` + `AreaMark` for visualization, simple Codable JSON file persistence for historical data, and a rolling-window burn rate algorithm. Implement Admin API as an optional settings-driven feature.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Swift Charts | macOS 13+ (native) | Usage trend visualization | Apple's native framework, declarative SwiftUI syntax, built-in accessibility |
| Foundation | (native) | JSON encoding, file I/O | Codable protocol for persistence, FileManager for storage |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| SwiftData | macOS 14+ | Structured persistence | Only if data model becomes complex (relationships, queries) |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Swift Charts | DGCharts/Charts | More customizable, but adds dependency; Swift Charts is native and sufficient |
| JSON file | SwiftData | SwiftData adds schema management overhead; JSON is simpler for flat time-series |
| JSON file | CoreData | Over-engineered for simple time-series; requires boilerplate |
| JSON file | UserDefaults | 512KB limit makes it unsuitable for historical data |

**Installation:**
No additional packages needed. Swift Charts and Codable are part of the Swift standard library and Apple frameworks.

## Architecture Patterns

### Recommended Project Structure
```
Tokemon/
├── Models/
│   └── UsageHistory.swift          # Historical data point model
├── Services/
│   ├── HistoryStore.swift          # JSON persistence layer
│   ├── BurnRateCalculator.swift    # Burn rate + projection logic
│   └── AdminAPIClient.swift        # Optional Admin API integration
└── Views/
    ├── Charts/
    │   ├── UsageChartView.swift    # Main chart visualization
    │   └── ChartTimeRangeSelector.swift  # Daily/weekly toggle
    └── Settings/
        └── AdminAPISettings.swift  # Admin API connection UI
```

### Pattern 1: Time-Series Data Model
**What:** A simple Codable struct for storing usage snapshots with timestamps.
**When to use:** Any time-series data that needs persistence and visualization.
**Example:**
```swift
// Source: SwiftData best practices + Codable patterns
struct UsageDataPoint: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let primaryPercentage: Double      // 5-hour utilization
    let sevenDayPercentage: Double?    // 7-day utilization (optional)
    let source: String                  // "oauth" or "jsonl"

    init(from snapshot: UsageSnapshot) {
        self.id = UUID()
        self.timestamp = Date()
        self.primaryPercentage = snapshot.primaryPercentage
        self.sevenDayPercentage = snapshot.sevenDayUtilization
        self.source = snapshot.source.rawValue
    }
}
```

### Pattern 2: JSON File Persistence Store
**What:** A simple actor-based store that reads/writes JSON to the app's Application Support directory.
**When to use:** Lightweight persistence for time-series data without complex queries.
**Example:**
```swift
// Source: Codable file persistence pattern
actor HistoryStore {
    private let fileURL: URL
    private var cache: [UsageDataPoint] = []

    init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let appDir = appSupport.appendingPathComponent("Tokemon", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        self.fileURL = appDir.appendingPathComponent("usage_history.json")
    }

    func append(_ point: UsageDataPoint) async throws {
        cache.append(point)
        // Trim to last 30 days
        let cutoff = Date().addingTimeInterval(-30 * 24 * 3600)
        cache = cache.filter { $0.timestamp > cutoff }
        try await save()
    }

    func load() async throws -> [UsageDataPoint] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        cache = try JSONDecoder().decode([UsageDataPoint].self, from: data)
        return cache
    }

    private func save() async throws {
        let data = try JSONEncoder().encode(cache)
        try data.write(to: fileURL)
    }
}
```

### Pattern 3: Swift Charts Line Chart with Date Axis
**What:** Using `LineMark` with `Date` values for time-series visualization.
**When to use:** Displaying usage trends over time with proper date formatting.
**Example:**
```swift
// Source: Apple Swift Charts documentation + AppCoda tutorial
import Charts

struct UsageChartView: View {
    let dataPoints: [UsageDataPoint]

    var body: some View {
        Chart {
            ForEach(dataPoints) { point in
                LineMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Usage", point.primaryPercentage)
                )
                .interpolationMethod(.catmullRom)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 6)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let pct = value.as(Double.self) {
                        Text("\(Int(pct))%")
                    }
                }
            }
        }
        .chartYScale(domain: 0...100)
    }
}
```

### Pattern 4: Area Chart with Gradient Fill
**What:** Combining `LineMark` and `AreaMark` with gradient for visual appeal.
**When to use:** Making usage charts more visually engaging.
**Example:**
```swift
// Source: SwiftUI FYI #11, nilcoalescing.com gradient patterns
Chart {
    ForEach(dataPoints) { point in
        AreaMark(
            x: .value("Time", point.timestamp),
            y: .value("Usage", point.primaryPercentage)
        )
        .foregroundStyle(
            LinearGradient(
                colors: [.blue.opacity(0.3), .blue.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .interpolationMethod(.catmullRom)

        LineMark(
            x: .value("Time", point.timestamp),
            y: .value("Usage", point.primaryPercentage)
        )
        .foregroundStyle(.blue)
        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
        .interpolationMethod(.catmullRom)
    }
}
.chartPlotStyle { plotArea in
    plotArea.background(.clear)
}
```

### Pattern 5: Burn Rate Calculation
**What:** Calculate usage pace and project time-to-limit using a rolling window.
**When to use:** Estimating when the user will hit their limit at current pace.
**Example:**
```swift
// Source: Project management burn rate algorithms
struct BurnRateCalculator {
    /// Calculate burn rate (percentage per hour) from recent data points
    /// Uses rolling window for stability
    static func calculateBurnRate(
        from points: [UsageDataPoint],
        windowHours: Double = 2.0
    ) -> Double? {
        let cutoff = Date().addingTimeInterval(-windowHours * 3600)
        let recentPoints = points.filter { $0.timestamp > cutoff }

        guard recentPoints.count >= 2,
              let first = recentPoints.first,
              let last = recentPoints.last else {
            return nil
        }

        let usageDelta = last.primaryPercentage - first.primaryPercentage
        let timeDeltaHours = last.timestamp.timeIntervalSince(first.timestamp) / 3600

        guard timeDeltaHours > 0 else { return nil }
        return usageDelta / timeDeltaHours  // % per hour
    }

    /// Project time until 100% limit at current burn rate
    static func projectTimeToLimit(
        currentUsage: Double,
        burnRate: Double  // % per hour
    ) -> TimeInterval? {
        guard burnRate > 0 else { return nil }  // Not burning = no limit ETA

        let remainingPercentage = 100.0 - currentUsage
        let hoursRemaining = remainingPercentage / burnRate
        return hoursRemaining * 3600  // Convert to seconds
    }
}
```

### Anti-Patterns to Avoid
- **Storing raw UsageSnapshot in history:** Too much data; extract only what's needed for charting
- **Unbounded history growth:** Always trim to a reasonable window (30 days max)
- **Polling burn rate constantly:** Calculate on demand or on data refresh, not continuously
- **Admin API in main monitor flow:** Keep Admin API separate; it's optional and has different auth
- **Using SwiftData for simple flat data:** Adds complexity without benefit

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Chart visualization | Custom drawing code | Swift Charts | Apple's framework handles axes, accessibility, animations |
| Date formatting | String formatting | DateFormatter/.formatted | Proper localization, edge cases |
| JSON persistence | Manual file handling | Codable + JSONEncoder/Decoder | Type safety, automatic serialization |
| Moving average | Raw loop calculation | Accelerate framework (if needed) | SIMD optimization for large datasets |

**Key insight:** Swift Charts handles the hard parts of charting (scales, axes, accessibility, animations). The persistence layer should be as thin as possible -- a few hundred lines of Codable + FileManager code.

## Common Pitfalls

### Pitfall 1: Chart Performance with Large Datasets
**What goes wrong:** Rendering thousands of data points causes UI lag.
**Why it happens:** SwiftUI Charts recalculates layout for every point on each frame.
**How to avoid:** Downsample data for display (e.g., hourly averages for weekly view), limit visible points to ~500.
**Warning signs:** Choppy scrolling, high CPU usage when chart is visible.

### Pitfall 2: Race Conditions in History Store
**What goes wrong:** Concurrent reads/writes corrupt the JSON file.
**Why it happens:** Multiple async tasks accessing file simultaneously.
**How to avoid:** Use an `actor` for the store, serialize all file operations.
**Warning signs:** Missing data points, JSON parse errors on load.

### Pitfall 3: Burn Rate Volatility
**What goes wrong:** Burn rate fluctuates wildly, making projections useless.
**Why it happens:** Using instantaneous rate (two adjacent points) instead of rolling window.
**How to avoid:** Use 2-4 hour rolling window for calculation, show "calculating..." if insufficient data.
**Warning signs:** Time-to-limit estimate jumping from "2 hours" to "20 minutes" to "5 hours".

### Pitfall 4: Admin API Key Exposure
**What goes wrong:** Admin API key stored insecurely or logged.
**Why it happens:** Treating Admin key like regular data instead of credential.
**How to avoid:** Store in Keychain (like OAuth tokens), never log key value, clear on logout.
**Warning signs:** Key visible in UserDefaults, debug logs, or crash reports.

### Pitfall 5: Assuming Admin API Available for All Users
**What goes wrong:** Feature fails silently for individual accounts.
**Why it happens:** Admin API only works for organization accounts with admin role.
**How to avoid:** Clear UI indicating "Organization Admin only", validate key prefix (`sk-ant-admin`).
**Warning signs:** 401/403 errors, user confusion about why feature doesn't work.

## Code Examples

### Complete Chart View with Time Range Selection
```swift
// Source: Swift Charts documentation + AppCoda patterns
import SwiftUI
import Charts

enum TimeRange: String, CaseIterable {
    case day = "24h"
    case week = "7d"

    var interval: TimeInterval {
        switch self {
        case .day: return 24 * 3600
        case .week: return 7 * 24 * 3600
        }
    }

    var strideComponent: Calendar.Component {
        switch self {
        case .day: return .hour
        case .week: return .day
        }
    }

    var strideCount: Int {
        switch self {
        case .day: return 4    // Every 4 hours
        case .week: return 1   // Every day
        }
    }
}

struct UsageTrendChartView: View {
    let allDataPoints: [UsageDataPoint]
    @State private var selectedRange: TimeRange = .day

    private var filteredPoints: [UsageDataPoint] {
        let cutoff = Date().addingTimeInterval(-selectedRange.interval)
        return allDataPoints.filter { $0.timestamp > cutoff }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Range selector
            Picker("Time Range", selection: $selectedRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 120)

            // Chart
            Chart {
                ForEach(filteredPoints) { point in
                    AreaMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Usage", point.primaryPercentage)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue.opacity(0.4), .blue.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Usage", point.primaryPercentage)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(
                    by: selectedRange.strideComponent,
                    count: selectedRange.strideCount
                )) { value in
                    AxisGridLine()
                    AxisValueLabel(format: selectedRange == .day
                        ? .dateTime.hour(.defaultDigits(amPM: .abbreviated))
                        : .dateTime.weekday(.abbreviated)
                    )
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let pct = value.as(Double.self) {
                            Text("\(Int(pct))%")
                        }
                    }
                }
            }
            .chartYScale(domain: 0...100)
            .frame(height: 200)
        }
    }
}
```

### Burn Rate Display Component
```swift
// Source: Burn rate calculation patterns
struct BurnRateView: View {
    let currentUsage: Double
    let burnRate: Double?  // % per hour, nil if insufficient data
    let timeToLimit: TimeInterval?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(burnRateColor)
                Text("Burn Rate")
                    .font(.headline)
            }

            if let rate = burnRate {
                Text(String(format: "%.1f%% per hour", rate))
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)

                if let timeRemaining = timeToLimit, timeRemaining > 0 {
                    HStack {
                        Image(systemName: "clock")
                        Text("Limit in: \(formattedTime(timeRemaining))")
                    }
                    .foregroundColor(timeRemaining < 3600 ? .red : .secondary)
                }
            } else {
                Text("Calculating...")
                    .foregroundColor(.secondary)
            }
        }
    }

    private var burnRateColor: Color {
        guard let rate = burnRate else { return .gray }
        if rate > 20 { return .red }
        if rate > 10 { return .orange }
        return .green
    }

    private func formattedTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
```

### Admin API Client
```swift
// Source: Anthropic Admin API documentation
import Foundation
import KeychainAccess

actor AdminAPIClient {
    static let shared = AdminAPIClient()

    private let keychain = Keychain(service: "Tokemon-AdminAPI")
    private let baseURL = "https://api.anthropic.com/v1/organizations"

    /// Store Admin API key securely
    func setAdminKey(_ key: String) throws {
        guard key.hasPrefix("sk-ant-admin") else {
            throw AdminAPIError.invalidKeyFormat
        }
        try keychain.set(key, key: "admin_api_key")
    }

    /// Check if Admin API is configured
    func hasAdminKey() -> Bool {
        (try? keychain.get("admin_api_key")) != nil
    }

    /// Clear stored Admin API key
    func clearAdminKey() throws {
        try keychain.remove("admin_api_key")
    }

    /// Fetch usage report for organization
    func fetchUsageReport(
        startingAt: Date,
        endingAt: Date,
        bucketWidth: String = "1d"
    ) async throws -> AdminUsageResponse {
        guard let adminKey = try keychain.get("admin_api_key") else {
            throw AdminAPIError.notConfigured
        }

        let formatter = ISO8601DateFormatter()
        let url = URL(string: "\(baseURL)/usage_report/messages")!
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "starting_at", value: formatter.string(from: startingAt)),
            URLQueryItem(name: "ending_at", value: formatter.string(from: endingAt)),
            URLQueryItem(name: "bucket_width", value: bucketWidth)
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue(adminKey, forHTTPHeaderField: "x-api-key")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AdminAPIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode(AdminUsageResponse.self, from: data)
        case 401, 403:
            throw AdminAPIError.unauthorized
        default:
            throw AdminAPIError.serverError(httpResponse.statusCode)
        }
    }

    enum AdminAPIError: Error {
        case notConfigured
        case invalidKeyFormat
        case invalidResponse
        case unauthorized
        case serverError(Int)
    }
}

// Response model (simplified)
struct AdminUsageResponse: Codable {
    let data: [UsageBucket]
    let hasMore: Bool
    let nextPage: String?

    struct UsageBucket: Codable {
        let bucketStartTime: String
        let inputTokens: Int
        let outputTokens: Int
        let cacheCreationInputTokens: Int
        let cacheReadInputTokens: Int

        enum CodingKeys: String, CodingKey {
            case bucketStartTime = "bucket_start_time"
            case inputTokens = "input_tokens"
            case outputTokens = "output_tokens"
            case cacheCreationInputTokens = "cache_creation_input_tokens"
            case cacheReadInputTokens = "cache_read_input_tokens"
        }
    }

    enum CodingKeys: String, CodingKey {
        case data
        case hasMore = "has_more"
        case nextPage = "next_page"
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Core Data for all persistence | SwiftData for complex models, Codable JSON for simple data | 2023 (WWDC) | Simpler code for time-series |
| Third-party charting libraries | Swift Charts native framework | 2022 (WWDC) | No dependencies, better integration |
| Manual chart drawing | Declarative chart syntax | 2022 (WWDC) | 90% less charting code |
| NSCoding | Codable protocol | Swift 4 (2017) | Type-safe serialization |

**Deprecated/outdated:**
- DGCharts/Charts library for new SwiftUI projects (Swift Charts is native and sufficient)
- Core Data for simple flat data (SwiftData or Codable files are simpler)
- UserDefaults for anything beyond small settings (512KB limit)

## Open Questions

1. **History Data Granularity**
   - What we know: Storing every poll (~1 minute) for 30 days = ~43,000 records
   - What's unclear: Is this too many points? Should we aggregate to hourly?
   - Recommendation: Start with every poll, add downsampling if performance issues arise

2. **Admin API Key Sharing with OAuth**
   - What we know: Admin API uses different key format than OAuth
   - What's unclear: Can one user have both OAuth (Claude Code) and Admin API access?
   - Recommendation: Support both independently, let user configure Admin API separately in settings

3. **Burn Rate Window Tuning**
   - What we know: 2-4 hour window provides stability
   - What's unclear: What's optimal for Claude's 5-hour reset window?
   - Recommendation: Start with 2 hours, make configurable if users request

## Sources

### Primary (HIGH confidence)
- [Anthropic Admin API Documentation](https://platform.claude.com/docs/en/api/administration-api) - Authentication, endpoints, permissions
- [Anthropic Usage and Cost API](https://platform.claude.com/docs/en/api/usage-cost-api) - Detailed usage tracking endpoints
- [Apple Swift Charts Documentation](https://developer.apple.com/documentation/charts) - Framework reference
- [HackingWithSwift SwiftData Guide](https://www.hackingwithswift.com/quick-start/swiftdata) - @Model macro usage

### Secondary (MEDIUM confidence)
- [AppCoda SwiftUI Line Charts](https://www.appcoda.com/swiftui-line-charts/) - Complete chart examples with date axes
- [Swift with Majid Charts Basics](https://swiftwithmajid.com/2023/01/10/mastering-charts-in-swiftui-basics/) - LineMark, AreaMark patterns
- [SwiftUI FYI Line Chart with Gradient](https://swiftuifyi.substack.com/p/swiftui-fyi-11-line-chart-with-gradient) - Gradient fill techniques

### Tertiary (LOW confidence - needs validation if used)
- Burn rate calculation patterns from project management sources (adapted for usage tracking)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Apple frameworks, official documentation
- Architecture: HIGH - Standard patterns verified in multiple sources
- Pitfalls: MEDIUM - Derived from general SwiftUI/Swift best practices
- Admin API: HIGH - Directly from Anthropic official documentation

**Research date:** 2026-02-13
**Valid until:** 2026-03-15 (30 days - stable frameworks, Admin API may update)
