import SwiftUI

/// Main popover layout shell displayed when clicking the menu bar icon.
/// Shows usage percentage, detail rows, and a footer with refresh status.
struct PopoverContentView: View {
    @Environment(UsageMonitor.self) private var monitor

    var body: some View {
        VStack(spacing: 16) {
            // Big percentage number (dominant, first thing user sees)
            Text(formattedPercentage)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(percentageColor)

            // Secondary context
            Text("of 5-hour limit used")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()

            // Detail rows (placeholder -- will be refined in Plan 03)
            VStack(alignment: .leading, spacing: 12) {
                detailRow(
                    label: "Resets at",
                    value: formattedResetTime
                )
                detailRow(
                    label: "7-day usage",
                    value: formattedSevenDay
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            Divider()

            // Footer: last updated + settings gear
            HStack {
                if monitor.isRefreshing {
                    ProgressView()
                        .controlSize(.small)
                    Text("Updating...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let lastUpdated = monitor.lastUpdated {
                    Text("Updated \(lastUpdated, style: .relative) ago")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Not yet updated")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    // Placeholder action -- settings will be wired in Plan 03
                } label: {
                    Image(systemName: "gear")
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(16)
        .frame(minWidth: 320, maxWidth: 320, minHeight: 300, maxHeight: 500)
    }

    // MARK: - Formatted Values

    private var formattedPercentage: String {
        let pct = monitor.currentUsage.primaryPercentage
        if monitor.currentUsage.source == .none {
            return "--%"
        }
        return "\(Int(pct))%"
    }

    private var percentageColor: Color {
        Color(nsColor: GradientColors.color(for: monitor.currentUsage.primaryPercentage))
    }

    private var formattedResetTime: String {
        guard let resetsAt = monitor.currentUsage.resetsAt else {
            return "--"
        }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: resetsAt)
    }

    private var formattedSevenDay: String {
        guard let sevenDay = monitor.currentUsage.sevenDayUtilization else {
            return "--"
        }
        return "\(Int(sevenDay))%"
    }

    // MARK: - Helper Views

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.body)
                .fontWeight(.medium)
        }
    }
}
