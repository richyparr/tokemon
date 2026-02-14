import SwiftUI
import AppKit

/// Compact usage display for the floating window.
/// Shows usage percentage prominently with status indicator.
/// Updates live via @Environment(UsageMonitor.self).
struct FloatingWindowView: View {
    @Environment(UsageMonitor.self) private var monitor
    @Environment(AlertManager.self) private var alertManager
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.colorScheme) private var colorScheme

    /// Computed theme colors based on current theme and color scheme
    private var themeColors: ThemeColors {
        themeManager.colors(for: colorScheme)
    }

    var body: some View {
        floatingContent
            .preferredColorScheme(themeColors.colorSchemeOverride)
    }

    private var floatingContent: some View {
        VStack(spacing: 4) {
            // Big percentage number
            Text(percentageText)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(usageColor)
                .monospacedDigit()

            // Status indicator
            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(minWidth: 100, minHeight: 60)
    }

    // MARK: - Computed Properties

    private var percentageText: String {
        let usage = monitor.currentUsage
        if usage.source == .none {
            return "--%"
        }
        if usage.hasPercentage {
            return "\(Int(usage.primaryPercentage))%"
        }
        // JSONL fallback: show token count
        return usage.formattedTokenCount
    }

    private var usageColor: Color {
        let usage = monitor.currentUsage
        guard usage.hasPercentage else {
            return Color(nsColor: .secondaryLabelColor)
        }
        let pct = usage.primaryPercentage
        return Color(nsColor: GradientColors.color(for: pct))
    }

    private var statusText: String {
        let usage = monitor.currentUsage
        let level = alertManager.currentAlertLevel

        // Priority: error states
        if case .bothSourcesFailed = monitor.error {
            return "Data unavailable"
        }

        // Priority: JSONL mode (no percentage)
        if !usage.hasPercentage && usage.source == .jsonl {
            return "Local session"
        }

        // Priority: no data
        if usage.source == .none {
            return "Loading..."
        }

        // Alert-level status
        switch level {
        case .critical:
            return "Limit reached"
        case .warning:
            return "Approaching limit"
        case .normal:
            return "5-hour usage"
        }
    }
}
