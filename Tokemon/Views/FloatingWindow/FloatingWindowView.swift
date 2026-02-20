import SwiftUI
import AppKit

/// Compact usage display for the floating window.
/// Shows one or more usage rows based on the rows passed at init.
/// Updates live via @Environment(UsageMonitor.self).
struct FloatingWindowView: View {
    @Environment(UsageMonitor.self) private var monitor
    @Environment(AlertManager.self) private var alertManager
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.colorScheme) private var colorScheme

    /// Which rows to display, in display order. Set at init by the controller.
    let rows: [FloatingWindowRow]

    /// Computed theme colors based on current theme and color scheme
    private var themeColors: ThemeColors {
        themeManager.colors(for: colorScheme)
    }

    var body: some View {
        VStack(spacing: 0) {
            if rows.isEmpty {
                // Fallback: show 5-hour usage if no rows specified
                singleRow(for: .fiveHour, fontSize: 32)
            } else if rows.count == 1 {
                singleRow(for: rows[0], fontSize: 32)
            } else {
                // Multiple rows with dividers
                singleRow(for: rows[0], fontSize: 32)
                ForEach(rows.dropFirst(), id: \.self) { row in
                    Divider()
                        .padding(.horizontal, 12)
                    singleRow(for: row, fontSize: 24)
                }
            }
        }
        .padding(EdgeInsets(top: 12, leading: 12, bottom: 16, trailing: 12))
        .frame(minWidth: 120, minHeight: 60)
        .background(themeColors.primaryBackground)
        .tint(themeColors.primaryAccent)
        .preferredColorScheme(themeColors.colorSchemeOverride)
    }

    // MARK: - Row View

    private func singleRow(for row: FloatingWindowRow, fontSize: CGFloat) -> some View {
        VStack(spacing: 4) {
            Text(percentageText(for: row))
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .foregroundStyle(usageColor(for: row))
                .monospacedDigit()

            Text(statusText(for: row))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, fontSize < 32 ? 4 : 0)
    }

    // MARK: - Per-Row Computed Properties

    private func percentageText(for row: FloatingWindowRow) -> String {
        let usage = monitor.currentUsage

        if row == .fiveHour {
            if usage.source == .none {
                return "--%"
            }
            if usage.hasPercentage {
                return "\(Int(usage.primaryPercentage))%"
            }
            return usage.formattedTokenCount
        }

        // 7-day rows
        if let pct = row.percentage(from: usage) {
            return "\(Int(pct))%"
        }
        return "--%"
    }

    private func usageColor(for row: FloatingWindowRow) -> Color {
        let usage = monitor.currentUsage

        if let pct = row.percentage(from: usage) {
            return Color(nsColor: GradientColors.color(for: pct))
        }
        return Color(nsColor: .secondaryLabelColor)
    }

    private func statusText(for row: FloatingWindowRow) -> String {
        let usage = monitor.currentUsage

        if row == .fiveHour {
            let level = alertManager.currentAlertLevel
            if case .bothSourcesFailed = monitor.error {
                return "Data unavailable"
            }
            if !usage.hasPercentage && usage.source == .jsonl {
                return "Local session"
            }
            if usage.source == .none {
                return "Loading..."
            }
            switch level {
            case .critical: return "Limit reached"
            case .warning: return "Approaching limit"
            case .normal: return row.label
            }
        }

        // 7-day rows: just show the label
        return row.label
    }
}
