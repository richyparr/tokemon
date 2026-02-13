import SwiftUI
import Charts

/// Time range options for the usage chart.
enum ChartTimeRange: String, CaseIterable {
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

/// Usage trend chart with area fill and line overlay.
/// Uses Swift Charts (native macOS 13+, project targets macOS 14+).
struct UsageChartView: View {
    let dataPoints: [UsageDataPoint]
    @State private var selectedRange: ChartTimeRange = .day

    private var filteredPoints: [UsageDataPoint] {
        let cutoff = Date().addingTimeInterval(-selectedRange.interval)
        return dataPoints.filter { $0.timestamp > cutoff }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Range selector
            HStack {
                Text("Usage Trend")
                    .font(.headline)
                Spacer()
                Picker("", selection: $selectedRange) {
                    ForEach(ChartTimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 100)
            }

            if filteredPoints.isEmpty {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No data yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(height: 120)
                .frame(maxWidth: .infinity)
            } else {
                // Chart
                Chart {
                    ForEach(filteredPoints) { point in
                        // Area fill (gradient)
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

                        // Line overlay
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
                    )) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: selectedRange == .day
                            ? .dateTime.hour(.defaultDigits(amPM: .abbreviated))
                            : .dateTime.weekday(.abbreviated)
                        )
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
                .frame(height: 120)
            }
        }
    }
}
