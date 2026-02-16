import Foundation

/// Data source for export operations.
/// Replaces the inline enum from AnalyticsDashboardView.
enum ExportSource: String, CaseIterable, Sendable {
    case local = "This Machine"
    case organization = "Organization"

    var icon: String {
        switch self {
        case .local: return "desktopcomputer"
        case .organization: return "building.2"
        }
    }

    var description: String {
        switch self {
        case .local: return "Local polling data collected by tokemon"
        case .organization: return "Organization-wide data from Admin API"
        }
    }
}

/// Preset date range options for export.
enum DatePreset: String, CaseIterable, Sendable {
    case sevenDays = "7 Days"
    case thirtyDays = "30 Days"
    case ninetyDays = "90 Days"
    case oneYear = "1 Year"
    case allTime = "All Time"
    case custom = "Custom"

    /// Compute the actual date range for this preset.
    /// - Parameters:
    ///   - customStart: Start date for custom range (only used when preset is .custom)
    ///   - customEnd: End date for custom range (only used when preset is .custom)
    /// - Returns: Tuple of (start, end) dates
    func dateRange(customStart: Date? = nil, customEnd: Date? = nil) -> (start: Date, end: Date) {
        let end = Date()
        let calendar = Calendar.current

        switch self {
        case .sevenDays:
            let start = calendar.date(byAdding: .day, value: -7, to: end) ?? end
            return (start, end)
        case .thirtyDays:
            let start = calendar.date(byAdding: .day, value: -30, to: end) ?? end
            return (start, end)
        case .ninetyDays:
            let start = calendar.date(byAdding: .day, value: -90, to: end) ?? end
            return (start, end)
        case .oneYear:
            let start = calendar.date(byAdding: .year, value: -1, to: end) ?? end
            return (start, end)
        case .allTime:
            // API won't have data before Anthropic launched publicly (early 2023)
            var components = DateComponents()
            components.year = 2023
            components.month = 1
            components.day = 1
            let start = calendar.date(from: components) ?? end
            return (start, end)
        case .custom:
            // Use provided custom dates, fallback to 30 days
            let start = customStart ?? calendar.date(byAdding: .day, value: -30, to: end) ?? end
            let actualEnd = customEnd ?? end
            return (start, actualEnd)
        }
    }

    /// Number of days in this preset (approximate, for display)
    var approximateDays: Int {
        switch self {
        case .sevenDays: return 7
        case .thirtyDays: return 30
        case .ninetyDays: return 90
        case .oneYear: return 365
        case .allTime: return 1000 // Arbitrary large number
        case .custom: return 30 // Default assumption
        }
    }
}

/// Granularity for report breakdown based on date range.
enum ReportGranularity: Sendable {
    case daily
    case weekly
    case monthly

    /// Determine appropriate granularity based on number of days.
    /// Per user's locked decision: daily < 30d, weekly 30-90d, monthly > 90d
    static func from(days: Int) -> ReportGranularity {
        if days < 30 {
            return .daily
        } else if days <= 90 {
            return .weekly
        } else {
            return .monthly
        }
    }

    var label: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}

/// Export file format.
enum ExportFormat: String, Identifiable, Sendable {
    case pdf
    case csv
    case card

    var id: String { rawValue }
}

/// Configuration for an export operation.
/// Captures all user selections from the export dialog.
struct ExportConfig: Sendable {
    let source: ExportSource
    let datePreset: DatePreset
    let format: ExportFormat
    let customStartDate: Date?
    let customEndDate: Date?

    init(
        source: ExportSource,
        datePreset: DatePreset,
        format: ExportFormat,
        customStartDate: Date? = nil,
        customEndDate: Date? = nil
    ) {
        self.source = source
        self.datePreset = datePreset
        self.format = format
        self.customStartDate = customStartDate
        self.customEndDate = customEndDate
    }

    /// The actual date range based on preset and custom dates.
    var dateRange: (start: Date, end: Date) {
        datePreset.dateRange(customStart: customStartDate, customEnd: customEndDate)
    }

    /// Number of days in the date range.
    var numberOfDays: Int {
        let range = dateRange
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: range.start, to: range.end)
        return max(1, components.day ?? 1)
    }

    /// Appropriate granularity for this config's date range.
    var granularity: ReportGranularity {
        ReportGranularity.from(days: numberOfDays)
    }

    /// Suggested filename for the export.
    /// Format: tokemon-{type}-{period}.{ext}
    /// Example: tokemon-usage-2026-01-to-2026-02.csv
    var suggestedFilename: String {
        let range = dateRange
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"

        let startStr = formatter.string(from: range.start)
        let endStr = formatter.string(from: range.end)
        let period = "\(startStr)-to-\(endStr)"

        switch format {
        case .pdf:
            return "tokemon-report-\(period).pdf"
        case .csv:
            return "tokemon-usage-\(period).csv"
        case .card:
            return "tokemon-card-\(period).png"
        }
    }

    /// Whether this is a large export that warrants a warning.
    /// True when date range exceeds 90 days AND source is organization.
    var isLargeExport: Bool {
        source == .organization && numberOfDays > 90
    }
}
