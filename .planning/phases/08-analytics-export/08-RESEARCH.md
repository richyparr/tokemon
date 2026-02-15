# Phase 8: Analytics & Export - Research

**Researched:** 2026-02-15
**Domain:** Extended Data Retention, Usage Aggregation, PDF Generation, CSV Export, Project-Level Token Tracking
**Confidence:** HIGH

## Summary

Phase 8 extends ClaudeMon's existing usage tracking infrastructure with three major capabilities: (1) extended 90-day data retention with downsampling, (2) weekly/monthly usage summaries with per-project breakdowns, and (3) PDF and CSV export for usage reports.

The existing codebase provides a strong foundation. `HistoryStore` already supports per-account JSON file storage with 30-day retention. `UsageDataPoint` captures timestamped utilization percentages. `UsageChartView` renders trend charts using native Swift Charts. `JSONLParser` already reads `~/.claude/projects/` session files and extracts token counts per project directory. The `FeatureAccessManager` already defines Pro feature gates for all Phase 8 features (`.extendedHistory`, `.weeklySummary`, `.monthlySummary`, `.projectBreakdown`, `.exportPDF`, `.exportCSV`).

The primary technical challenges are: (a) scaling HistoryStore from 30 to 90 days without excessive disk usage (solved by downsampling old data to hourly granularity), (b) aggregating usage data into weekly/monthly summaries from JSONL session files, (c) rendering SwiftUI chart views to PDF using `ImageRenderer` (native macOS 14+ API), and (d) generating CSV from structured data using standard Foundation APIs.

**Primary recommendation:** Extend HistoryStore with configurable retention and hourly downsampling for data older than 7 days. Build an `AnalyticsEngine` service that aggregates usage data from both HistoryStore (utilization percentages) and JSONLParser (per-project token counts). Use native `ImageRenderer` for PDF export and `NSSavePanel` for CSV file saving. All features gated behind `FeatureAccessManager.canAccess()`.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Swift Charts | macOS 14+ (native) | Extended history charts (30d/90d) | Already used in UsageChartView, native framework |
| Foundation Calendar | (native) | Week/month aggregation with `dateInterval(of:for:)` | Standard date arithmetic, locale-aware |
| ImageRenderer | macOS 14+ (native) | Render SwiftUI views to PDF via CGContext | Native SwiftUI API, vectors preserved in output |
| CGContext | (native) | PDF page creation and rendering | Core Graphics PDF support, multi-page capable |
| NSSavePanel | (native) | User file destination picker for exports | macOS standard file save dialog |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| UniformTypeIdentifiers | macOS 14+ | UTType for .pdf and .csv content types | File type identification for save panels |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| ImageRenderer PDF | TPPDF library | More structured PDF API, but adds dependency; ImageRenderer keeps it native and consistent with existing chart rendering |
| NSSavePanel | SwiftUI `.fileExporter()` | fileExporter requires FileDocument conformance; NSSavePanel is simpler for one-shot exports |
| JSON file storage | SwiftData/CoreData | Over-engineered for time-series data; JSON files already work well in HistoryStore |

**Installation:**
No additional packages needed. All capabilities use native Apple frameworks already available at the macOS 14 target.

## Architecture Patterns

### Recommended Project Structure
```
ClaudeMon/
  Services/
    HistoryStore.swift          # EXTEND: 90-day retention + downsampling
    AnalyticsEngine.swift       # NEW: aggregation, summaries, project breakdown
    ExportManager.swift         # NEW: PDF and CSV generation
  Models/
    UsageDataPoint.swift        # EXTEND: add optional projectPath field
    UsageSummary.swift          # NEW: weekly/monthly summary model
    ProjectUsage.swift          # NEW: per-project token breakdown model
  Views/
    Analytics/
      AnalyticsDashboardView.swift  # NEW: main analytics container
      UsageSummaryView.swift        # NEW: weekly/monthly summary cards
      ProjectBreakdownView.swift    # NEW: per-project token table
      ExtendedHistoryChartView.swift # NEW: 30d/90d chart (extends UsageChartView pattern)
    Export/
      ExportButton.swift            # NEW: export trigger with format selection
      PDFReportView.swift           # NEW: SwiftUI view rendered to PDF
```

### Pattern 1: Downsampled History Storage
**What:** Store recent data at full polling resolution, automatically downsample older data to hourly averages.
**When to use:** When retention period exceeds 7 days and raw per-minute data would be too large.
**Key insight:** 90 days of per-minute data = ~25MB per account. With hourly downsampling for >7d data = ~2.4MB. This 10x reduction is essential.
**Example:**
```swift
// Source: Standard time-series downsampling pattern
extension HistoryStore {
    /// Downsample data points older than threshold to hourly averages.
    /// Called periodically (e.g., daily or on app launch).
    func downsampleOldEntries(for accountId: UUID, recentWindowDays: Int = 7) {
        guard var cache = caches[accountId] else { return }

        let recentCutoff = Date().addingTimeInterval(-Double(recentWindowDays) * 24 * 3600)

        // Split into recent (keep raw) and old (downsample)
        let recentPoints = cache.filter { $0.timestamp > recentCutoff }
        let oldPoints = cache.filter { $0.timestamp <= recentCutoff }

        // Group old points by hour
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: oldPoints) { point in
            calendar.dateInterval(of: .hour, for: point.timestamp)?.start ?? point.timestamp
        }

        // Average each hour group into a single point
        let downsampled = grouped.compactMap { (hourStart, points) -> UsageDataPoint? in
            guard !points.isEmpty else { return nil }
            let avgPrimary = points.map(\.primaryPercentage).reduce(0, +) / Double(points.count)
            let avgSevenDay = points.compactMap(\.sevenDayPercentage)
            let avgSevenDayValue = avgSevenDay.isEmpty ? nil : avgSevenDay.reduce(0, +) / Double(avgSevenDay.count)

            return UsageDataPoint(
                timestamp: hourStart,
                primaryPercentage: avgPrimary,
                sevenDayPercentage: avgSevenDayValue,
                source: points.first?.source ?? "oauth"
            )
        }.sorted { $0.timestamp < $1.timestamp }

        cache = downsampled + recentPoints
        caches[accountId] = cache
    }
}
```

### Pattern 2: Weekly/Monthly Summary Aggregation
**What:** Group UsageDataPoints by calendar week or month and compute summary statistics.
**When to use:** Building weekly and monthly usage summary views.
**Example:**
```swift
// Source: Foundation Calendar dateInterval patterns
struct UsageSummary: Identifiable {
    let id = UUID()
    let period: DateInterval       // The week or month interval
    let periodLabel: String        // "Feb 10-16" or "February 2026"
    let averageUtilization: Double // Average 5-hour utilization
    let peakUtilization: Double    // Highest recorded utilization
    let dataPointCount: Int        // Number of data points in period
}

struct AnalyticsEngine {
    static func weeklySummaries(from points: [UsageDataPoint], weeks: Int = 4) -> [UsageSummary] {
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .weekOfYear, value: -weeks, to: Date())!
        let filtered = points.filter { $0.timestamp > cutoff }

        let grouped = Dictionary(grouping: filtered) { point in
            calendar.dateInterval(of: .weekOfYear, for: point.timestamp)!
        }

        return grouped.map { (interval, points) in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            let label = "\(formatter.string(from: interval.start))-\(formatter.string(from: interval.end.addingTimeInterval(-1)))"

            return UsageSummary(
                period: interval,
                periodLabel: label,
                averageUtilization: points.map(\.primaryPercentage).reduce(0, +) / Double(points.count),
                peakUtilization: points.map(\.primaryPercentage).max() ?? 0,
                dataPointCount: points.count
            )
        }.sorted { $0.period.start < $1.period.start }
    }
}
```

### Pattern 3: Project/Folder Token Breakdown
**What:** Parse JSONL session files grouped by project directory to show which projects consumed the most tokens.
**When to use:** ANALYTICS-07 requirement -- per-project usage tracking.
**Key insight:** Claude Code stores sessions at `~/.claude/projects/{encoded-path}/` where the directory name encodes the project path (e.g., `-Users-richardparr-ClaudeMon` maps to `/Users/richardparr/ClaudeMon`). The existing `JSONLParser.findProjectDirectories()` already discovers these. Each JSONL entry also has a `cwd` field with the full path.
**Example:**
```swift
// Source: Existing JSONLParser patterns
struct ProjectUsage: Identifiable {
    let id = UUID()
    let projectPath: String        // Decoded path (e.g., "/Users/richardparr/ClaudeMon")
    let projectName: String        // Last component (e.g., "ClaudeMon")
    let inputTokens: Int
    let outputTokens: Int
    let cacheCreationTokens: Int
    let cacheReadTokens: Int
    let sessionCount: Int

    var totalTokens: Int {
        inputTokens + outputTokens + cacheCreationTokens + cacheReadTokens
    }
}

extension AnalyticsEngine {
    /// Decode a Claude Code project directory name back to a filesystem path.
    /// "-Users-richardparr-ClaudeMon" -> "/Users/richardparr/ClaudeMon"
    static func decodeProjectPath(_ dirName: String) -> String {
        // Replace leading dash + subsequent dashes with slashes
        var path = dirName
        if path.hasPrefix("-") {
            path = "/" + String(path.dropFirst())
        }
        path = path.replacingOccurrences(of: "-", with: "/")
        return path
    }

    /// Aggregate token usage per project from JSONL session files.
    static func projectBreakdown(since: Date) throws -> [ProjectUsage] {
        let projectDirs = try JSONLParser.findProjectDirectories()

        return projectDirs.compactMap { dirURL in
            let sessions = JSONLParser.findSessionFiles(in: dirURL, since: since)
            guard !sessions.isEmpty else { return nil }

            var totalInput = 0, totalOutput = 0, totalCacheCreate = 0, totalCacheRead = 0
            for session in sessions {
                let usage = JSONLParser.parseSession(at: session)
                totalInput += usage.inputTokens
                totalOutput += usage.outputTokens
                totalCacheCreate += usage.cacheCreationTokens
                totalCacheRead += usage.cacheReadTokens
            }

            let decodedPath = decodeProjectPath(dirURL.lastPathComponent)
            let projectName = URL(fileURLWithPath: decodedPath).lastPathComponent

            return ProjectUsage(
                projectPath: decodedPath,
                projectName: projectName,
                inputTokens: totalInput,
                outputTokens: totalOutput,
                cacheCreationTokens: totalCacheCreate,
                cacheReadTokens: totalCacheRead,
                sessionCount: sessions.count
            )
        }.sorted { $0.totalTokens > $1.totalTokens }
    }
}
```

### Pattern 4: PDF Report via ImageRenderer
**What:** Render a SwiftUI view hierarchy (charts, tables, summaries) to a multi-page PDF using `ImageRenderer`.
**When to use:** ANALYTICS-03 -- export usage report as PDF.
**Important notes:** ImageRenderer is @MainActor. On macOS, LinearGradient may render differently in ImageRenderer vs on-screen (known Apple limitation). Keep PDF report views simple (solid colors preferred over gradients for reliability).
**Example:**
```swift
// Source: HackingWithSwift ImageRenderer PDF tutorial + Apple docs
@MainActor
struct ExportManager {
    /// Render a report view to PDF and return the file URL.
    static func generatePDF(from reportView: some View, filename: String = "ClaudeMon-Report.pdf") -> URL? {
        let renderer = ImageRenderer(content: reportView)
        renderer.scale = 2.0  // Retina quality

        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        renderer.render { size, context in
            // US Letter size (612 x 792 points)
            var box = CGRect(x: 0, y: 0, width: 612, height: 792)

            guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else { return }

            pdf.beginPDFPage(nil)

            // Scale content to fit page with margins
            let margin: CGFloat = 36 // 0.5 inch margins
            let scaleX = (612 - 2 * margin) / size.width
            let scaleY = (792 - 2 * margin) / size.height
            let scale = min(scaleX, scaleY, 1.0)

            pdf.translateBy(x: margin, y: margin)
            pdf.scaleBy(x: scale, y: scale)

            context(pdf)

            pdf.endPDFPage()
            pdf.closePDF()
        }

        return url
    }
}
```

### Pattern 5: CSV Export
**What:** Generate CSV data from usage history and save via NSSavePanel.
**When to use:** ANALYTICS-04 -- export raw usage data as CSV.
**Example:**
```swift
// Source: Standard CSV generation + NSSavePanel patterns
extension ExportManager {
    /// Generate CSV string from usage data points.
    static func generateCSV(from points: [UsageDataPoint]) -> String {
        let header = "Timestamp,Utilization %,7-Day Utilization %,Source"
        let formatter = ISO8601DateFormatter()

        let rows = points.map { point in
            let ts = formatter.string(from: point.timestamp)
            let sevenDay = point.sevenDayPercentage.map { String(format: "%.1f", $0) } ?? ""
            return "\(ts),\(String(format: "%.1f", point.primaryPercentage)),\(sevenDay),\(point.source)"
        }

        return ([header] + rows).joined(separator: "\n")
    }

    /// Show NSSavePanel and write CSV to user-selected location.
    @MainActor
    static func exportCSV(content: String, suggestedFilename: String = "claudemon-usage.csv") async -> Bool {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = suggestedFilename
        panel.canCreateDirectories = true

        let response = await panel.beginSheetModal(for: NSApp.keyWindow ?? NSApp.mainWindow!)
        guard response == .OK, let url = panel.url else { return false }

        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            return true
        } catch {
            print("[ExportManager] CSV export failed: \(error)")
            return false
        }
    }
}
```

### Anti-Patterns to Avoid
- **Keeping all 90 days at full resolution:** 25MB+ per account; always downsample old data to hourly
- **Rendering charts with gradients in PDF:** ImageRenderer on macOS may render gradients incorrectly; use solid colors in PDF report views
- **Blocking the main thread during JSONL parsing:** Project breakdown scans many files; always do I/O on a background thread/Task
- **Computing summaries on every view refresh:** Cache aggregation results and only recompute when data changes
- **Using `.fileExporter()` for one-shot exports:** Requires conforming to FileDocument protocol; NSSavePanel is simpler for export-only flows
- **Storing project breakdown in HistoryStore:** Project data comes from JSONL files (different source); keep it in a separate computation pipeline

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| PDF generation | Custom PDF drawing with Core Text | ImageRenderer + SwiftUI views | ImageRenderer preserves text as vectors, handles layout automatically |
| Chart rendering for PDF | CGContext drawing of charts | Swift Charts inside ImageRenderer | Reuse existing chart components |
| CSV parsing/escaping | Manual string concatenation with commas | Proper CSV escaping (quote fields with commas/newlines) | CSV edge cases are subtle (embedded commas, newlines, quotes) |
| Date aggregation | Manual day/week/month arithmetic | Calendar.dateInterval(of:for:) | Calendar handles DST, leap years, locale-specific week starts |
| File save dialog | Custom save view | NSSavePanel | macOS standard; users expect this UX |

**Key insight:** The entire PDF pipeline can reuse existing SwiftUI views. Build a `PDFReportView` that composes chart views and summary views, then render it with ImageRenderer. No custom Core Graphics drawing needed.

## Common Pitfalls

### Pitfall 1: HistoryStore Data Growth
**What goes wrong:** 90 days of per-minute data grows to 25MB+ per account, causing slow load times and excessive disk usage.
**Why it happens:** HistoryStore loads entire JSON file into memory on startup.
**How to avoid:** Implement downsampling: keep last 7 days at full resolution, downsample older data to hourly averages. Run downsampling on app launch and periodically.
**Warning signs:** History file > 5MB, slow app startup, memory spikes on load.

### Pitfall 2: ImageRenderer Environment Objects
**What goes wrong:** PDF renders blank or crashes because the view uses `@Environment` values not available in ImageRenderer.
**Why it happens:** ImageRenderer creates an isolated rendering context without the normal SwiftUI environment.
**How to avoid:** Build a dedicated `PDFReportView` that takes all data as parameters (not from environment). Do not rely on `@Environment(ThemeManager.self)` or `@Environment(\.colorScheme)` inside PDF views. Pass explicit colors and data.
**Warning signs:** Blank sections in PDF, crashes during render, missing theme colors.

### Pitfall 3: JSONL Parsing Performance for Large Projects
**What goes wrong:** Project breakdown takes several seconds, blocking the UI.
**Why it happens:** Scanning all project directories and parsing all JSONL files synchronously.
**How to avoid:** Run JSONL parsing in a background Task. Show a loading indicator. Consider caching results with a staleness TTL (e.g., reparse only if data is >5 minutes old).
**Warning signs:** UI freezes when opening analytics tab, spinning wheel.

### Pitfall 4: Calendar Week Boundary Confusion
**What goes wrong:** Weekly summaries split data incorrectly at week boundaries.
**Why it happens:** Different locales have different week starts (Sunday vs Monday). `Calendar.current` uses the user's locale.
**How to avoid:** Always use `Calendar.current.dateInterval(of: .weekOfYear, for:)` which respects locale settings. Never hardcode week start day.
**Warning signs:** Data appears in wrong week, different results on different machines.

### Pitfall 5: NSSavePanel in Menu Bar App
**What goes wrong:** Save panel appears behind other windows or fails to show.
**Why it happens:** ClaudeMon is an LSUIElement app (no Dock icon), so it doesn't have a key window by default.
**How to avoid:** Call `NSApp.activate(ignoringOtherApps: true)` before presenting NSSavePanel. Use `panel.begin()` (standalone) rather than `panel.beginSheetModal()` if there's no reliable key window. The existing `openSettings()` pattern in the codebase already handles this activation.
**Warning signs:** Panel doesn't appear, appears behind other apps, or crashes on nil window.

### Pitfall 6: CSV Special Characters
**What goes wrong:** CSV output is malformed when data contains commas, quotes, or newlines.
**Why it happens:** Naive string concatenation without proper RFC 4180 escaping.
**How to avoid:** Wrap fields containing commas/quotes/newlines in double quotes. Escape embedded double quotes by doubling them (`""` inside quoted fields). For this app, the risk is low since data is numeric, but project names could theoretically contain commas.
**Warning signs:** Spreadsheet misaligns columns, import errors.

## Code Examples

### Extended ChartTimeRange for 30d/90d Views
```swift
// Source: Existing ChartTimeRange pattern in UsageChartView.swift
enum ExtendedChartTimeRange: String, CaseIterable {
    case day = "24h"
    case week = "7d"
    case month = "30d"
    case quarter = "90d"

    var interval: TimeInterval {
        switch self {
        case .day: return 24 * 3600
        case .week: return 7 * 24 * 3600
        case .month: return 30 * 24 * 3600
        case .quarter: return 90 * 24 * 3600
        }
    }

    var strideComponent: Calendar.Component {
        switch self {
        case .day: return .hour
        case .week: return .day
        case .month: return .day
        case .quarter: return .weekOfYear
        }
    }

    var strideCount: Int {
        switch self {
        case .day: return 4      // Every 4 hours
        case .week: return 1     // Every day
        case .month: return 5    // Every 5 days
        case .quarter: return 2  // Every 2 weeks
        }
    }

    var dateFormatStyle: Date.FormatStyle {
        switch self {
        case .day: return .dateTime.hour(.defaultDigits(amPM: .abbreviated))
        case .week: return .dateTime.weekday(.abbreviated)
        case .month: return .dateTime.month(.abbreviated).day()
        case .quarter: return .dateTime.month(.abbreviated).day()
        }
    }
}
```

### PDF Report View Template
```swift
// Source: ImageRenderer documentation + SwiftUI layout patterns
/// A self-contained view for PDF rendering. Takes all data as parameters.
/// No @Environment dependencies (ImageRenderer limitation on macOS).
struct PDFReportView: View {
    let accountName: String
    let generatedDate: Date
    let weeklySummaries: [UsageSummary]
    let projectBreakdown: [ProjectUsage]
    let dataPoints: [UsageDataPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("ClaudeMon Usage Report")
                    .font(.title.bold())
                Spacer()
                Text(generatedDate.formatted(date: .long, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("Account: \(accountName)")
                .font(.subheadline)

            Divider()

            // Weekly Summaries
            Text("Weekly Summary")
                .font(.headline)

            ForEach(weeklySummaries) { summary in
                HStack {
                    Text(summary.periodLabel)
                    Spacer()
                    Text("Avg: \(Int(summary.averageUtilization))%")
                    Text("Peak: \(Int(summary.peakUtilization))%")
                }
                .font(.caption)
            }

            Divider()

            // Project Breakdown
            Text("Project Token Usage")
                .font(.headline)

            ForEach(projectBreakdown.prefix(10)) { project in
                HStack {
                    Text(project.projectName)
                    Spacer()
                    Text(formatTokens(project.totalTokens))
                        .monospacedDigit()
                }
                .font(.caption)
            }
        }
        .padding(24)
        .frame(width: 540)  // Fits US Letter with margins
        .background(Color.white)
        .foregroundColor(.black)
    }

    private func formatTokens(_ count: Int) -> String {
        if count >= 1_000_000 { return String(format: "%.1fM", Double(count) / 1_000_000) }
        if count >= 1_000 { return String(format: "%.1fK", Double(count) / 1_000) }
        return "\(count)"
    }
}
```

### NSSavePanel for PDF Export
```swift
// Source: macOS NSSavePanel documentation
@MainActor
static func exportPDF(from view: some View, suggestedFilename: String = "ClaudeMon-Report.pdf") async -> Bool {
    // Activate app (important for LSUIElement apps)
    NSApp.activate(ignoringOtherApps: true)

    let panel = NSSavePanel()
    panel.allowedContentTypes = [.pdf]
    panel.nameFieldStringValue = suggestedFilename
    panel.canCreateDirectories = true
    panel.title = "Export Usage Report"
    panel.prompt = "Export"

    let response = await panel.begin()
    guard response == .OK, let destinationURL = panel.url else { return false }

    // Generate PDF to temp file, then move to destination
    guard let tempURL = generatePDF(from: view, filename: "temp-report.pdf") else { return false }

    do {
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        try FileManager.default.moveItem(at: tempURL, to: destinationURL)

        // Open in Finder (optional convenience)
        NSWorkspace.shared.activateFileViewerSelecting([destinationURL])
        return true
    } catch {
        print("[ExportManager] Failed to save PDF: \(error)")
        return false
    }
}
```

### Pro Feature Gating Pattern
```swift
// Source: Existing FeatureAccessManager + ProBadge patterns in codebase
struct AnalyticsDashboardView: View {
    @Environment(FeatureAccessManager.self) private var featureAccess

    var body: some View {
        if featureAccess.canAccess(.extendedHistory) {
            // Full analytics view
            analyticsContent
        } else {
            // Locked state with upgrade prompt
            VStack(spacing: 12) {
                Image(systemName: "chart.bar.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("Analytics is a Pro feature")
                    .font(.headline)
                Text("Upgrade to view extended history, usage summaries, and export reports.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Upgrade to Pro") {
                    featureAccess.openPurchasePage()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| UIGraphicsBeginPDFContext | ImageRenderer.render() | iOS 16 / macOS 13 (2022) | SwiftUI views render directly to PDF, no manual drawing |
| NSDocument for exports | NSSavePanel + direct write | Always available | Simpler for one-shot exports without document-based app |
| UserDefaults for history | Codable JSON files | Established in Phase 3 | Handles larger data, per-account storage |
| Fixed chart time ranges (24h/7d) | Extended ranges with downsampling | This phase | 30d/90d views become feasible |

**Deprecated/outdated:**
- `UIGraphicsBeginPDFContextToFile` (UIKit-only, not available on macOS)
- Third-party PDF libraries for simple report generation (ImageRenderer handles it natively)
- `NSSavePanel.allowedFileTypes` (deprecated; use `.allowedContentTypes` with UTType)

## Open Questions

1. **Analytics UI Location**
   - What we know: The popover is 320x440px and already dense. Settings window has tabs.
   - What's unclear: Where should the analytics dashboard live -- in the popover, settings, or a separate window?
   - Recommendation: Add an "Analytics" tab to the Settings window (not in the popover). The settings window already has infrastructure for tabs (SettingsView.swift uses TabView) and handles the LSUIElement window activation. The popover should get a small "View Analytics" link that opens the settings window to the Analytics tab.

2. **Multi-Account Project Breakdown**
   - What we know: JSONL session files are not per-account. All Claude Code sessions from all accounts write to the same `~/.claude/projects/` directory.
   - What's unclear: Can we attribute JSONL sessions to specific accounts?
   - Recommendation: The project breakdown is inherently cross-account (single machine). Present it as a "This Machine" view rather than per-account. The utilization history (from OAuth/HistoryStore) is already per-account.

3. **PDF Multi-Page Support**
   - What we know: ImageRenderer renders one SwiftUI view to one page. Multi-page requires manual page breaking.
   - What's unclear: How much content fits on one page for a typical report?
   - Recommendation: Start with single-page PDF (summary + top 10 projects). If content overflows, split into multiple ImageRenderer.render() calls with page continuation. Most users will have <10 active projects.

## Sources

### Primary (HIGH confidence)
- **Apple ImageRenderer documentation** - PDF rendering via CGContext, @MainActor requirement
- **Apple NSSavePanel documentation** - File save dialog, allowedContentTypes
- **Apple Calendar documentation** - dateInterval(of:for:), weekOfYear, month components
- **Existing codebase** - HistoryStore.swift, JSONLParser.swift, UsageChartView.swift, FeatureAccessManager.swift
- [HackingWithSwift: How to render a SwiftUI view to a PDF](https://www.hackingwithswift.com/quick-start/swiftui/how-to-render-a-swiftui-view-to-a-pdf) - Complete ImageRenderer PDF example
- [Swift with Majid: File importing and exporting in SwiftUI](https://swiftwithmajid.com/2023/05/10/file-importing-and-exporting-in-swiftui/) - fileExporter patterns

### Secondary (MEDIUM confidence)
- [AppCoda: SwiftUI ImageRenderer PDF Documents](https://www.appcoda.com/swiftui-imagerenderer-pdf/) - CGContext page setup
- [Apple Developer Forums: ImageRenderer macOS limitations](https://developer.apple.com/forums/thread/736400) - Gradient rendering differences on macOS
- [Swift Dev Journal: SwiftUI Open and Save Panels](https://www.swiftdevjournal.com/swiftui-open-and-save-panels/) - NSSavePanel patterns
- Direct inspection of `~/.claude/projects/` directory structure - Confirmed directory naming encoding and JSONL cwd field

### Tertiary (LOW confidence)
- [TPPDF GitHub](https://github.com/techprimate/TPPDF) - Alternative PDF library (not recommended but documented as fallback)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All native Apple frameworks, no new dependencies needed
- Architecture: HIGH - Extends existing patterns (HistoryStore, JSONLParser, UsageChartView), verified against codebase
- Downsampling strategy: HIGH - Data volume calculations verified (25MB raw vs 2.4MB downsampled)
- PDF generation: MEDIUM - ImageRenderer works for simple layouts; gradient rendering on macOS has known quirks
- Project breakdown: HIGH - Verified JSONL structure and directory naming by inspecting actual files on disk
- Pitfalls: HIGH - Based on macOS-specific issues verified in Apple Developer Forums

**Research date:** 2026-02-15
**Valid until:** 2026-03-17 (30 days - stable frameworks, no new APIs expected)
