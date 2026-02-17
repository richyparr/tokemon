import SwiftUI
import Charts

/// Time range options for the extended history chart.
enum ExtendedChartTimeRange: String, CaseIterable, Identifiable {
    case day = "24h"
    case week = "7d"
    case month = "30d"
    case quarter = "90d"

    var id: String { rawValue }

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

    /// Date format for x-axis labels
    var axisLabelFormat: Date.FormatStyle {
        switch self {
        case .day:
            return .dateTime.hour(.defaultDigits(amPM: .abbreviated))
        case .week:
            return .dateTime.weekday(.abbreviated)
        case .month:
            return .dateTime.month(.abbreviated).day()
        case .quarter:
            return .dateTime.month(.abbreviated).day()
        }
    }
}

/// Extended history chart with 24h/7d/30d/90d time range picker.
/// Uses Swift Charts area+line chart following the same pattern as UsageChartView.
struct ExtendedHistoryChartView: View {
    let dataPoints: [UsageDataPoint]
    @State private var selectedRange: ExtendedChartTimeRange = .week
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.colorScheme) private var colorScheme

    private var themeColors: ThemeColors {
        themeManager.colors(for: colorScheme)
    }

    private var filteredPoints: [UsageDataPoint] {
        let cutoff = Date().addingTimeInterval(-selectedRange.interval)
        return dataPoints.filter { $0.timestamp > cutoff }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with range selector
            HStack {
                Text("Usage History")
                    .font(.headline)
                Spacer()
                Picker("", selection: $selectedRange) {
                    ForEach(ExtendedChartTimeRange.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }

            if filteredPoints.isEmpty {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No data for this period")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(height: 140)
                .frame(maxWidth: .infinity)
            } else {
                // Chart
                Chart {
                    ForEach(filteredPoints) { point in
                        AreaMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Usage", point.primaryPercentage)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: themeColors.chartGradientColors,
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Usage", point.primaryPercentage)
                        )
                        .foregroundStyle(themeColors.primaryAccent)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(
                        by: selectedRange.strideComponent,
                        count: selectedRange.strideCount
                    )) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: selectedRange.axisLabelFormat)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: [0, 25, 50, 75, 100]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let pct = value.as(Double.self) {
                                Text("\(Int(pct))%")
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartYScale(domain: 0...100)
                .frame(height: 140)
            }
        }
    }
}
