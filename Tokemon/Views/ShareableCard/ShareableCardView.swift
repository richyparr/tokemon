import SwiftUI
import AppKit

/// Self-contained SwiftUI view for shareable usage cards.
/// CRITICAL: No @Environment dependencies. ImageRenderer creates an isolated rendering
/// context without the normal SwiftUI environment. All data must be passed as parameters.
/// NOTE: Uses solid colors only (no gradients) to avoid macOS ImageRenderer rendering bugs.
struct ShareableCardView: View {
    // Pre-load logo images (must be done before ImageRenderer context)
    private static let logoWhite: NSImage? = {
        guard let url = Bundle.module.url(forResource: "tokemon_logo_white", withExtension: "png"),
              let image = NSImage(contentsOf: url) else { return nil }
        return image
    }()

    private static let logoColor: NSImage? = {
        guard let url = Bundle.module.url(forResource: "tokemon_logo", withExtension: "png"),
              let image = NSImage(contentsOf: url) else { return nil }
        return image
    }()
    let periodLabel: String          // "This Week" or "February 2026"
    let utilizationPercentage: Double?
    let topProjectName: String?      // Optional
    let totalTokensUsed: Int?        // Optional
    let generatedDate: Date

    // Admin API mode properties
    let totalTokens: Int?
    let inputTokens: Int?
    let outputTokens: Int?

    // Insight mode properties
    let insight: ShareableInsight?

    /// Local data initializer (percentage-based) - legacy
    init(
        periodLabel: String,
        utilizationPercentage: Double,
        topProjectName: String?,
        totalTokensUsed: Int?,
        generatedDate: Date
    ) {
        self.periodLabel = periodLabel
        self.utilizationPercentage = utilizationPercentage
        self.topProjectName = topProjectName
        self.totalTokensUsed = totalTokensUsed
        self.generatedDate = generatedDate
        self.totalTokens = nil
        self.inputTokens = nil
        self.outputTokens = nil
        self.insight = nil
    }

    /// Admin API initializer (token-based)
    init(
        periodLabel: String,
        totalTokens: Int,
        inputTokens: Int,
        outputTokens: Int,
        generatedDate: Date
    ) {
        self.periodLabel = periodLabel
        self.utilizationPercentage = nil
        self.topProjectName = nil
        self.totalTokensUsed = nil
        self.generatedDate = generatedDate
        self.totalTokens = totalTokens
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.insight = nil
    }

    /// Insight-based initializer (derived data cards)
    init(insight: ShareableInsight, generatedDate: Date = Date()) {
        self.periodLabel = ""
        self.utilizationPercentage = nil
        self.topProjectName = nil
        self.totalTokensUsed = nil
        self.generatedDate = generatedDate
        self.totalTokens = nil
        self.inputTokens = nil
        self.outputTokens = nil
        self.insight = insight
    }

    private var isAdminMode: Bool {
        totalTokens != nil
    }

    private var isInsightMode: Bool {
        insight != nil
    }

    // Tokemon branding colors from Brand Guidelines
    private let brandBase = Color(hex: "FF5A22")        // Primary orange-red
    private let brandDark = Color(hex: "1F2937")        // Dark for text
    private let brandColor700 = Color(hex: "802000")    // Deep red-brown
    private let brandColor100 = Color(hex: "FFC6B3")    // Light peach

    var body: some View {
        if isInsightMode, let insight = insight {
            insightCardBody(insight)
        } else if isAdminMode {
            adminCardBody
        } else {
            legacyCardBody
        }
    }

    // MARK: - Insight Card (New branded cards)

    @ViewBuilder
    private func insightCardBody(_ insight: ShareableInsight) -> some View {
        ZStack {
            // Background with brand color
            brandDark

            VStack(alignment: .leading, spacing: 0) {
                // Top: Logo area
                HStack {
                    // Tokemon logo (white version for dark bg)
                    if let logo = Self.logoWhite {
                        Image(nsImage: logo)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 20)
                    } else {
                        Text("tokemon")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    // Card type emoji
                    Text(insight.type.emoji)
                        .font(.system(size: 24))
                }
                .padding(.bottom, 16)

                Spacer()

                // Main headline
                Text(insight.headline)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                // Subheadline
                Text(insight.subheadline)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.top, 4)

                Spacer()

                // Bottom bar with accent
                HStack {
                    // Accent bar
                    RoundedRectangle(cornerRadius: 2)
                        .fill(brandBase)
                        .frame(width: 40, height: 4)

                    Spacer()

                    // URL
                    Text("tokemon.ai")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(20)
        }
        .frame(width: 320, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Admin Card (token-based)

    @ViewBuilder
    private var adminCardBody: some View {
        ZStack {
            Color.white

            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        // Tokemon logo (color version for light bg)
                        if let logo = Self.logoColor {
                            Image(nsImage: logo)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 18)
                        } else {
                            Text("tokemon")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(brandBase)
                        }
                        Text("Organization Stats")
                            .font(.system(size: 11))
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                    Text(periodLabel)
                        .font(.system(size: 12))
                        .foregroundStyle(.gray)
                }

                Spacer()

                // Main stat
                if let total = totalTokens {
                    HStack {
                        Spacer()
                        Text(formatTokensLarge(total))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(brandDark)
                        Spacer()
                    }
                }

                Spacer()

                // Token breakdown
                HStack(spacing: 8) {
                    if let input = inputTokens {
                        pillBadge(text: "In: \(formatTokens(input))")
                    }
                    if let output = outputTokens {
                        pillBadge(text: "Out: \(formatTokens(output))")
                    }
                    Spacer()
                }

                // Footer
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
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Legacy Card (percentage-based)

    @ViewBuilder
    private var legacyCardBody: some View {
        ZStack {
            Color.white

            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        // Tokemon logo (color version for light bg)
                        if let logo = Self.logoColor {
                            Image(nsImage: logo)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 18)
                        } else {
                            Text("tokemon")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(brandBase)
                        }
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

                // Main stat
                HStack {
                    Spacer()
                    Text(String(format: "%.1f%%", utilizationPercentage ?? 0))
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(brandDark)
                    Spacer()
                }

                Spacer()

                // Footer
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
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helpers

    private func pillBadge(text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(brandDark.opacity(0.8))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.15))
            )
    }

    private func formatTokens(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000.0)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000.0)
        } else {
            return "\(count)"
        }
    }

    private func formatTokensLarge(_ count: Int) -> String {
        if count >= 1_000_000_000 {
            return String(format: "%.1fB", Double(count) / 1_000_000_000.0)
        } else if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000.0)
        } else if count >= 1_000 {
            return String(format: "%.0fK", Double(count) / 1_000.0)
        } else {
            return "\(count)"
        }
    }
}

// MARK: - Color Extension for Hex

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}
