import SwiftUI

/// Big usage percentage display at the top of the popover.
/// Dominant, first thing the user sees. Shows colored percentage for OAuth,
/// token count for JSONL, or "--%" for no data.
/// Displays warning banner when alert level is critical.
struct UsageHeaderView: View {
    let usage: UsageSnapshot
    let alertLevel: AlertManager.AlertLevel

    var body: some View {
        VStack(spacing: 4) {
            // Warning banner for critical alert level
            if alertLevel == .critical {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("Usage limit reached")
                }
                .font(.caption)
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.9), in: Capsule())
                .padding(.bottom, 8)
            }

            // Large percentage (or token count) -- dominant, first thing user sees
            Text(headerText)
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundStyle(headerColor)
                .contentTransition(.numericText())

            // Context line: reset timer for OAuth, description for JSONL
            Text(subtitleText)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Computed Properties

    private var headerText: String {
        if usage.source == .none {
            return "--%"
        }
        if usage.hasPercentage {
            return "\(Int(usage.primaryPercentage))%"
        }
        // JSONL fallback: show token count as the big number
        return usage.formattedTokenCount
    }

    private var subtitleText: String {
        if usage.source == .none {
            return "waiting for data"
        }
        if usage.hasPercentage {
            // Show reset timer as subtitle (more prominent than in detail view)
            if let resetTime = usage.resetsAt?.formattedResetTime() {
                return "resets in \(resetTime)"
            }
            return "of 5-hour limit"
        }
        return "tokens from local session logs"
    }

    private var headerColor: Color {
        if usage.source == .none {
            return Color(nsColor: .tertiaryLabelColor)
        }
        if usage.hasPercentage {
            return Color(nsColor: GradientColors.color(for: usage.primaryPercentage))
        }
        // JSONL fallback: neutral color
        return Color(nsColor: .secondaryLabelColor)
    }
}
