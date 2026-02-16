import SwiftUI

/// Self-contained SwiftUI view for shareable usage cards.
/// CRITICAL: No @Environment dependencies. ImageRenderer creates an isolated rendering
/// context without the normal SwiftUI environment. All data must be passed as parameters.
/// NOTE: Uses solid colors only (no gradients) to avoid macOS ImageRenderer rendering bugs.
struct ShareableCardView: View {
    let periodLabel: String          // "This Week" or "February 2026"
    let utilizationPercentage: Double
    let topProjectName: String?      // Optional
    let totalTokensUsed: Int?        // Optional
    let generatedDate: Date

    // Tokemon branding colors
    private let accentOrange = Color(red: 0xc1 / 255.0, green: 0x5f / 255.0, blue: 0x3c / 255.0)
    private let cardBackground = Color.white

    var body: some View {
        ZStack {
            // Background
            cardBackground

            VStack(alignment: .leading, spacing: 8) {
                // Top row: Branding + Period
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tokemon")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(accentOrange)

                        Text("Claude Usage Stats")
                            .font(.system(size: 11))
                            .foregroundStyle(.gray)
                    }

                    Spacer()

                    Text(periodLabel)
                        .font(.system(size: 12))
                        .foregroundStyle(.gray)
                }

                Spacer()

                // Main stat: Utilization percentage
                HStack {
                    Spacer()
                    Text(String(format: "%.1f%%", utilizationPercentage))
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                    Spacer()
                }

                Spacer()

                // Optional stats: Project name and token count in pills
                if topProjectName != nil || totalTokensUsed != nil {
                    HStack(spacing: 8) {
                        if let projectName = topProjectName {
                            pillBadge(text: projectName)
                        }

                        if let tokens = totalTokensUsed {
                            pillBadge(text: formatTokens(tokens))
                        }

                        Spacer()
                    }
                }

                // Footer: Viral marketing URL
                HStack {
                    Spacer()
                    Text("tokemon.ai")
                        .font(.system(size: 10))
                        .foregroundStyle(.gray)
                }
            }
            .padding(16)
        }
        .frame(width: 320, height: 200)
    }

    // MARK: - Helpers

    /// Create a pill badge with text.
    private func pillBadge(text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.black.opacity(0.8))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.15))
            )
    }

    /// Format token count: 1M+, 1K+, or raw number.
    private func formatTokens(_ count: Int) -> String {
        if count >= 1_000_000 {
            let millions = Double(count) / 1_000_000.0
            return String(format: "%.1fM tokens", millions)
        } else if count >= 1_000 {
            let thousands = Double(count) / 1_000.0
            return String(format: "%.1fK tokens", thousands)
        } else {
            return "\(count) tokens"
        }
    }
}
