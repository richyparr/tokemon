import SwiftUI

/// Displays current burn rate and projected time to limit.
struct BurnRateView: View {
    let currentUsage: Double
    let dataPoints: [UsageDataPoint]

    private var burnRate: Double? {
        BurnRateCalculator.calculateBurnRate(from: dataPoints)
    }

    private var timeToLimit: TimeInterval? {
        guard let rate = burnRate else { return nil }
        return BurnRateCalculator.projectTimeToLimit(currentUsage: currentUsage, burnRate: rate)
    }

    private var burnRateLevel: BurnRateCalculator.BurnRateLevel {
        BurnRateCalculator.burnRateColor(rate: burnRate)
    }

    private var levelColor: Color {
        switch burnRateLevel {
        case .normal: return .green
        case .elevated: return .orange
        case .critical: return .red
        case .unknown: return .secondary
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            // Burn rate
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(levelColor)
                        .font(.caption)
                    Text("Burn Rate")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let rate = burnRate {
                    Text(String(format: "%.1f%%/hr", rate))
                        .font(.system(.body, design: .monospaced))
                } else {
                    Text("--")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }

            Divider()
                .frame(height: 30)

            // Time to limit
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .foregroundColor(timeToLimitColor)
                        .font(.caption)
                    Text("Limit In")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let time = timeToLimit {
                    Text(BurnRateCalculator.formatTimeRemaining(time))
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(timeToLimitColor)
                } else {
                    Text("--")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var timeToLimitColor: Color {
        guard let time = timeToLimit else { return .secondary }
        if time < 3600 { return .red }          // <1 hour
        if time < 2 * 3600 { return .orange }   // <2 hours
        return .primary
    }
}
