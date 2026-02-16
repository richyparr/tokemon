# Phase 10: Enhanced Export - Research

**Researched:** 2026-02-16
**Domain:** SwiftUI macOS export dialogs, PDF/CSV generation, Admin API pagination, date picker UX
**Confidence:** HIGH

## Summary

This phase enhances the existing export system (PDF, CSV, shareable card) with user-selectable date ranges and richer data content. The current codebase already has a working export pipeline: `ExportManager` handles PDF/CSV generation via `ImageRenderer` and `NSSavePanel`, `AdminAPIClient` fetches usage/cost data, and `AnalyticsDashboardView` orchestrates the UX with a source picker sheet.

The main technical challenges are: (1) building a two-step export dialog (source then date range), (2) implementing Admin API pagination for large date ranges (the API limits daily buckets to max 31 per request), (3) generating multi-page PDFs for extended periods, and (4) restructuring CSV/PDF output to include the 4-column cache token breakdown plus cost data.

**Primary recommendation:** Build the export dialog as a single new `ExportDialogView` SwiftUI sheet that manages its own two-step state machine. Extend `AdminAPIClient` with a paginated fetch method. Restructure `ExportManager.generateAdminCSV` and `PDFReportView` to support the new column layout and adaptive date granularity.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **Date Range Options:** Preset periods: 7d, 30d, 90d, 1 year, All time, Custom. "All time" fetches whatever the Admin API returns (no artificial cap). Custom date range uses a calendar range picker (click and drag). Date filtering applies to both Admin API AND local data exports.
- **Export Dialog UX:** Two-step sheet flow: Step 1 pick source, Step 2 pick date range. Same dialog experience for local-only users (just without Admin API source option). Default to 30d period (no memory of last selection). Show preview/warning only for large exports (not for every export).
- **Data Included:** CSV exports include cost column when available from Admin API. PDF uses adaptive breakdown: Daily detail for periods < 30 days, Weekly summaries for 30-90 days, Monthly summaries for > 90 days. Full cache token breakdown: Input, Cache Creation, Cache Read, Output (4 separate columns).
- **Export File Format:** Filename format: `tokemon-{type}-{period}.{ext}` (e.g., `tokemon-usage-2026-01-to-2026-02.csv`). CSV column order: Date, Total, Input, Output, Cache Read, Cache Create, Cost. PDF includes summary section at top (totals + key metrics first). PDF uses tables only (no charts) for reliability.

### Claude's Discretion
- Exact calendar picker implementation (native macOS approach)
- "Large export" threshold for showing preview
- PDF layout and typography details
- Error handling for API failures during export

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope
</user_constraints>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | macOS 14+ | Export dialog UI, date pickers, sheet presentation | Already used throughout the app |
| ImageRenderer | macOS 13+ | PDF generation from SwiftUI views | Already used in ExportManager |
| CGContext | CoreGraphics | Multi-page PDF page management | Native PDF API, already used |
| NSSavePanel | AppKit | File save dialogs | Already used in ExportManager |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| DatePicker (.graphical) | macOS 10.15+ | Calendar-style date selection | Custom date range input |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Two separate DatePickers | Third-party DateRangePicker lib | Extra dependency for minor UX gain; two pickers are simpler and native |
| ImageRenderer for multi-page | Core Text CTFramesetter | More complex but handles text pagination natively; overkill since we control content per page |

**Installation:**
No new dependencies needed. All APIs are available in the existing macOS 14+ target.

## Architecture Patterns

### Recommended Project Structure
```
Tokemon/
  Views/
    Analytics/
      ExportDialogView.swift        # NEW: Two-step export sheet
      AnalyticsDashboardView.swift   # MODIFY: Wire up new dialog
      PDFReportView.swift            # MODIFY: Adaptive layout, summary section, multi-page
  Services/
    ExportManager.swift              # MODIFY: New CSV columns, date-range-aware generation
    AdminAPIClient.swift             # MODIFY: Paginated fetch for large date ranges
  Models/
    ExportConfig.swift               # NEW: Export configuration model (source, date range, format)
```

### Pattern 1: Two-Step Sheet with State Machine
**What:** A single sheet view that manages step transitions internally using an enum state.
**When to use:** When building multi-step dialogs that should feel like a unified flow.
**Example:**
```swift
struct ExportDialogView: View {
    enum Step {
        case selectSource
        case selectDateRange
    }

    @State private var step: Step = .selectSource
    @State private var selectedSource: ExportSource = .local
    @State private var selectedPreset: DatePreset = .thirtyDays
    @State private var customStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    @State private var customEndDate: Date = Date()

    var body: some View {
        VStack {
            switch step {
            case .selectSource:
                sourceSelectionStep
            case .selectDateRange:
                dateRangeStep
            }
        }
        .frame(width: 380)
    }
}
```

### Pattern 2: Date Preset Enum with Computed Ranges
**What:** An enum representing preset date periods that computes actual Date ranges on demand.
**When to use:** When the same set of date presets is used across multiple export types.
**Example:**
```swift
enum DatePreset: String, CaseIterable {
    case sevenDays = "7 Days"
    case thirtyDays = "30 Days"
    case ninetyDays = "90 Days"
    case oneYear = "1 Year"
    case allTime = "All Time"
    case custom = "Custom"

    func dateRange(customStart: Date? = nil, customEnd: Date? = nil) -> (start: Date, end: Date) {
        let now = Date()
        switch self {
        case .sevenDays: return (now.addingTimeInterval(-7 * 86400), now)
        case .thirtyDays: return (now.addingTimeInterval(-30 * 86400), now)
        case .ninetyDays: return (now.addingTimeInterval(-90 * 86400), now)
        case .oneYear: return (now.addingTimeInterval(-365 * 86400), now)
        case .allTime: return (Date.distantPast, now)  // API returns whatever it has
        case .custom: return (customStart ?? now, customEnd ?? now)
        }
    }
}
```

### Pattern 3: Paginated Admin API Fetch
**What:** A method that loops through `next_page` tokens to collect all data for large date ranges.
**When to use:** When fetching Admin API data for periods exceeding the API's per-request limit (31 daily buckets max).
**Example:**
```swift
// In AdminAPIClient
func fetchAllUsageData(
    startingAt: Date,
    endingAt: Date,
    bucketWidth: String = "1d"
) async throws -> AdminUsageResponse {
    var allBuckets: [AdminUsageResponse.UsageBucket] = []
    var page: String? = nil

    repeat {
        let response = try await fetchUsageReportPage(
            startingAt: startingAt,
            endingAt: endingAt,
            bucketWidth: bucketWidth,
            page: page
        )
        allBuckets.append(contentsOf: response.data)
        page = response.hasMore ? response.nextPage : nil
    } while page != nil

    return AdminUsageResponse(data: allBuckets, hasMore: false, nextPage: nil)
}
```

### Pattern 4: Multi-Page PDF with Per-Page Rendering
**What:** Create separate ImageRenderers for each PDF page, composing data into page-sized chunks.
**When to use:** When PDF content exceeds a single US Letter page.
**Example:**
```swift
static func generateMultiPagePDF(pages: [some View], filename: String) -> URL? {
    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
    var box = CGRect(x: 0, y: 0, width: 612, height: 792)

    guard let context = CGContext(tempURL as CFURL, mediaBox: &box, nil) else {
        return nil
    }

    for page in pages {
        let renderer = ImageRenderer(content: page)
        renderer.scale = 2.0
        renderer.render { size, renderContent in
            context.beginPDFPage(nil)
            // Scale and position...
            renderContent(context)
            context.endPDFPage()
        }
    }

    context.closePDF()
    return tempURL
}
```

### Pattern 5: Adaptive Date Granularity for PDF
**What:** Choose daily/weekly/monthly detail level based on the date range length.
**When to use:** When rendering PDF reports that must adapt to different time spans.
**Example:**
```swift
enum ReportGranularity {
    case daily    // < 30 days
    case weekly   // 30-90 days
    case monthly  // > 90 days

    static func from(days: Int) -> ReportGranularity {
        if days < 30 { return .daily }
        if days <= 90 { return .weekly }
        return .monthly
    }
}
```

### Anti-Patterns to Avoid
- **Hardcoded date ranges in fetch calls:** Current code uses `now.addingTimeInterval(-30 * 24 * 3600)` directly in `performPDFExport`. All date ranges must come from the export config.
- **Separate NSSavePanel per export path:** The current code has separate save panel logic in each `exportCSV`/`exportPDF`/`exportAdminCSV` method. Consolidate the save panel into the dialog flow.
- **Single-page PDF assumption:** Current `generatePDF` creates exactly one page. For large date ranges (90d+), content will overflow. Must implement multi-page support.
- **Ignoring API pagination:** The current `fetchUsageReport` makes a single request and ignores `hasMore`/`nextPage`. For "1 Year" or "All Time", this silently truncates data.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Date selection UI | Custom calendar grid view | SwiftUI `DatePicker` with `.graphical` style | Native macOS look, accessibility, localization all handled |
| CSV escaping | Custom string manipulation | Existing `escapeCSVField` helper in ExportManager | Already handles commas, quotes, newlines correctly |
| PDF coordinate math | Manual page layout calculations | Existing `generatePDF` pattern with margins/scaling | Already solved for US Letter with 36pt margins |
| ISO8601 date formatting | Custom date string parsing | `ISO8601DateFormatter` (already in use) | Handles fractional seconds, timezone correctly |

**Key insight:** The existing ExportManager and AdminAPIClient have solid foundations. This phase extends them rather than replacing them. The critical new code is the export dialog UI and API pagination -- everything else builds on proven patterns.

## Common Pitfalls

### Pitfall 1: Admin API Pagination Truncation
**What goes wrong:** For periods over 31 days with daily buckets, the API returns `has_more: true` but the current code ignores it, silently dropping data beyond the first page.
**Why it happens:** The current `fetchUsageReport` method doesn't handle pagination at all.
**How to avoid:** Implement a paginated fetch wrapper that loops until `has_more` is false. Use this for all export-related fetches.
**Warning signs:** Export for "90 Days" or "1 Year" shows suspiciously round numbers or exactly 31 days of data.

### Pitfall 2: Admin API Limit per Request
**What goes wrong:** The Admin API enforces maximum limits per bucket width. For `"1d"` buckets, max is 31 days. Requesting more returns an error or truncated data.
**Why it happens:** API design limits per-request scope to prevent abuse.
**How to avoid:** Always use pagination. For "1 Year" (365 days), expect ~12 paginated requests for daily data. For the Cost Report, only `"1d"` bucket_width is supported.
**Warning signs:** API errors or incomplete data for large ranges.

### Pitfall 3: Single-Page PDF Overflow
**What goes wrong:** PDF content for 90+ days of daily data overflows the single 792pt page, getting clipped or compressed to unreadable size.
**Why it happens:** Current `generatePDF` calculates `scale = min(scaleX, scaleY, 1.0)` which shrinks everything to fit on one page. With 90 rows of data, text becomes microscopic.
**How to avoid:** Split data into page-sized chunks. For a US Letter page with 36pt margins, usable height is ~720pt. At ~14pt per row, that's ~50 data rows per page (minus headers/summary).
**Warning signs:** Exported PDF has tiny, unreadable text.

### Pitfall 4: Cost Data in Cents vs Dollars
**What goes wrong:** Admin API Cost Report returns `amount` as a string in the lowest currency unit (cents for USD). Displaying "12345.67" looks like $12,345.67 but is actually $123.46.
**Why it happens:** API docs state: "Cost amount in lowest currency units (e.g. cents) as a decimal string. For example, '123.45' in 'USD' represents $1.23."
**How to avoid:** Divide parsed amount by 100 to convert cents to dollars. The existing `AdminCostResponse.CostBucket.totalCost` already does `Double($1.amount)` -- verify it divides by 100. (Looking at the current code: it does NOT divide by 100. This is a bug to fix.)
**Warning signs:** Costs appear ~100x too high in exports.

### Pitfall 5: ImageRenderer Environment Isolation
**What goes wrong:** PDFReportView crashes or renders blank because it uses `@Environment` properties.
**Why it happens:** `ImageRenderer` creates an isolated rendering context without the normal SwiftUI environment.
**How to avoid:** The existing PDFReportView already handles this correctly (all data passed as parameters, no @Environment). Keep this pattern for any new PDF pages.
**Warning signs:** Blank or partially rendered PDF output.

### Pitfall 6: NSSavePanel in LSUIElement App
**What goes wrong:** Save panel appears behind other windows or doesn't appear at all.
**Why it happens:** Menu bar (LSUIElement) apps don't have a key window by default.
**How to avoid:** Always call `NSApp.activate(ignoringOtherApps: true)` before showing panels. Use standalone panel mode, not `beginSheetModal`. The current code already handles this correctly.
**Warning signs:** Export button seems to do nothing (panel hidden behind other apps).

### Pitfall 7: Date Range Edge Cases
**What goes wrong:** "All Time" with no Admin API key configured, or Custom range with end before start.
**Why it happens:** Insufficient validation of date inputs.
**How to avoid:** Validate that start < end. For "All Time" with local data, use the oldest timestamp from `usageHistory`. For Admin API "All Time", omit the `starting_at` parameter or use a very early date.
**Warning signs:** Empty exports, API errors, or app crashes on edge case selections.

## Code Examples

Verified patterns from the existing codebase:

### Current Export Source Picker (to be replaced by two-step dialog)
```swift
// Source: AnalyticsDashboardView.swift lines 111-163
// This is the current single-step source picker.
// Phase 10 replaces this with ExportDialogView that adds Step 2 (date range).
.sheet(isPresented: $showingExportSourcePicker) {
    exportSourcePicker  // Current: just source selection, no date range
}
```

### Current CSV Generation (to be enhanced)
```swift
// Source: ExportManager.swift lines 168-181
// Current Admin CSV: Date, Total, Input, Output, Cache Read (5 columns)
// Phase 10 target: Date, Total, Input, Output, Cache Read, Cache Create, Cost (7 columns)
static func generateAdminCSV(from response: AdminUsageResponse) -> String {
    let header = "Date,Total Tokens,Input Tokens,Output Tokens,Cache Read Tokens"
    // Missing: Cache Create and Cost columns
}
```

### Admin API Fetch (needs pagination wrapper)
```swift
// Source: AdminAPIClient.swift lines 52-99
// Current: Single request, no pagination support
// Phase 10: Must handle has_more/next_page for ranges > 31 days
func fetchUsageReport(startingAt: Date, endingAt: Date, bucketWidth: String = "1d") async throws -> AdminUsageResponse {
    // ... single request, returns whatever fits in one page
}
```

### Two DatePickers for Custom Range (recommended approach)
```swift
// For custom date range selection, use two graphical DatePickers side by side
// This is the native macOS approach -- no third-party library needed
HStack(spacing: 16) {
    VStack(alignment: .leading) {
        Text("Start Date")
            .font(.caption)
            .foregroundStyle(.secondary)
        DatePicker("", selection: $startDate, in: ...endDate, displayedComponents: .date)
            .datePickerStyle(.graphical)
            .labelsHidden()
    }
    VStack(alignment: .leading) {
        Text("End Date")
            .font(.caption)
            .foregroundStyle(.secondary)
        DatePicker("", selection: $endDate, in: startDate..., displayedComponents: .date)
            .datePickerStyle(.graphical)
            .labelsHidden()
    }
}
```

### Filename Generation with Date Range
```swift
// Locked decision: tokemon-{type}-{period}.{ext}
func exportFilename(type: String, startDate: Date, endDate: Date, ext: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM"
    let start = formatter.string(from: startDate)
    let end = formatter.string(from: endDate)
    return "tokemon-\(type)-\(start)-to-\(end).\(ext)"
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Single hardcoded date range (30d/90d) | User-selectable date ranges | This phase | Users choose exactly what period to export |
| Single-page PDF | Multi-page PDF | This phase | Large reports no longer unreadable |
| 5-column Admin CSV | 7-column CSV (+ Cache Create, Cost) | This phase | Complete data in every export |
| Separate save panel per export type | Unified export dialog flow | This phase | Consistent UX regardless of export type |
| No API pagination | Full pagination support | This phase | "All Time" and "1 Year" actually return all data |

**Deprecated/outdated:**
- The current `exportSourcePicker` in AnalyticsDashboardView is replaced by the new `ExportDialogView`
- The `performPDFExport`/`performCSVExport` methods with hardcoded date ranges are replaced by config-driven exports

## Discretion Recommendations

### Calendar Picker Implementation
**Recommendation:** Use two native SwiftUI `DatePicker` controls with `.graphical` style side by side (start + end). The `.graphical` style renders as a native macOS calendar grid. This is simpler than a click-and-drag range picker and fully native. The dialog sheet is already ~380px wide which accommodates two compact calendar pickers in an HStack, though they may need vertical stacking if space is tight.

**Alternative considered:** A single calendar with range selection (click-drag). SwiftUI does not support this natively. Third-party options like `DateRangePicker` exist but add a dependency. Two separate graphical pickers are the pragmatic native choice.

**If two graphical pickers are too wide:** Stack them vertically, or use `.compact` style DatePickers (which show a text field that opens a calendar popover on click). The `.compact` style is more space-efficient and still feels native on macOS.

### Large Export Threshold
**Recommendation:** Show a preview/warning when the date range exceeds 90 days AND the source is Admin API. This is the point where pagination kicks in (multiple API requests) and the export may take several seconds. Local data exports are fast regardless of range since data is already in memory.

The warning should show: estimated number of data points and approximate file size. A simple confirmation: "This export covers X days of data. Continue?"

### PDF Layout Details
**Recommendation:**
- Page 1: Summary section (totals, key metrics, date range, source) + start of detail table
- Subsequent pages: Continuation of detail table with repeating column headers
- Footer on every page: "Generated by Tokemon - tokemon.ai" + page number
- Font: System font at 10pt for table data, 14pt for headers, 18pt for title
- Row height: ~16pt with 2pt padding = 18pt total per row
- Usable rows per page: ~38 data rows (after header, margins, footer)

### Error Handling for API Failures
**Recommendation:** Three-tier approach:
1. **Before export starts:** Validate API key exists. If not, disable Admin API source option.
2. **During fetch:** Show progress indicator in the export dialog. If a page fails, retry once with exponential backoff. If retry fails, show error with option to export partial data or cancel.
3. **On complete failure:** Show alert with error message. Offer to fall back to local data export instead.

## Open Questions

1. **Cost Report bucket width limitation**
   - What we know: The Cost Report API only supports `"1d"` bucket_width (unlike Usage which supports `"1h"`, `"1d"`, `"1m"`).
   - What's unclear: Whether `limit` has the same 31-day max as Usage. Likely yes, so pagination is needed for cost data too.
   - Recommendation: Implement pagination for both usage and cost endpoints identically.

2. **Admin API "All Time" earliest date**
   - What we know: The API returns data from whenever the organization started using it. There's no documented minimum date.
   - What's unclear: How far back data goes and whether very old requests will timeout.
   - Recommendation: For "All Time", use `Date.distantPast` equivalent (e.g., 2023-01-01) as the starting_at parameter. If the API returns no data for early periods, pagination will naturally handle it.

3. **Cost amount units confirmation**
   - What we know: API docs say "lowest currency units (e.g. cents)." The string "123.45" in USD represents $1.23.
   - What's unclear: Whether the current `AdminCostResponse` parsing divides by 100. Current code does `Double($1.amount)` without division.
   - Recommendation: Verify and fix during implementation. This is potentially a pre-existing bug affecting the OrgUsageView cost display.

## Sources

### Primary (HIGH confidence)
- Anthropic Admin API - Get Messages Usage Report: Verified query parameters, pagination fields (has_more, next_page), limit constraints (1d: max 31 days), response schema including cache_creation structure. Source: https://platform.claude.com/docs/en/api/admin-api/usage-cost/get-messages-usage-report
- Anthropic Admin API - Get Cost Report: Verified cost report only supports "1d" bucket_width, amount in cents (lowest currency unit), pagination support. Source: https://platform.claude.com/docs/en/api/admin-api/usage-cost/get-cost-report
- Existing codebase: ExportManager.swift, AdminAPIClient.swift, PDFReportView.swift, AnalyticsDashboardView.swift, AdminUsageResponse.swift -- all read directly

### Secondary (MEDIUM confidence)
- SwiftUI DatePicker graphical style on macOS: Available since macOS 10.15+, renders as calendar grid. Source: https://developer.apple.com/documentation/swiftui/graphicaldatepickerstyle
- Multi-page PDF with ImageRenderer: Multiple beginPDFPage/endPDFPage calls within a single CGContext. Pattern verified across multiple sources. Sources: https://www.hackingwithswift.com/quick-start/swiftui/how-to-render-a-swiftui-view-to-a-pdf, https://www.hackingwithswift.com/forums/swiftui/rendering-a-swiftui-view-to-multi-page-pdf/17892

### Tertiary (LOW confidence)
- Graphical DatePicker exact appearance on macOS 14: Could not find macOS-specific screenshots. Will look correct as it's a system control, but exact sizing needs testing during implementation.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- no new dependencies, all APIs verified in existing codebase
- Architecture: HIGH -- extending proven patterns from existing ExportManager/AdminAPIClient
- Pitfalls: HIGH -- API pagination limits verified from official docs, cost amount units verified from official docs
- Date picker UX: MEDIUM -- graphical style confirmed available on macOS but exact sizing in two-picker layout needs testing

**Research date:** 2026-02-16
**Valid until:** 2026-03-16 (30 days -- stable APIs, no fast-moving dependencies)
