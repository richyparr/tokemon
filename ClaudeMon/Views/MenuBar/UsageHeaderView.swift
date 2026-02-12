import SwiftUI

/// Big usage percentage display at the top of the popover.
/// Dominant, first thing the user sees. Shows colored percentage for OAuth,
/// token count for JSONL, or "--%" for no data.
struct UsageHeaderView: View {
    let usage: UsageSnapshot

    var body: some View {
        VStack(spacing: 4) {
            // Large percentage (or token count) -- dominant, first thing user sees
            Text(headerText)
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundStyle(headerColor)
                .contentTransition(.numericText())

            // Context line below the number
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
            return "of 5-hour limit used"
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
