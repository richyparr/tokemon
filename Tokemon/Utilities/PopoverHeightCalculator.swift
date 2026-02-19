import Foundation

/// Pure function for calculating popover height based on content state.
/// Extracted from TokemonApp for testability.
///
/// The popover height must adjust dynamically based on which sections are visible:
/// - Profile switcher (multi-profile mode)
/// - Extra usage billing section
/// - Update available banner
/// - Usage trend chart
enum PopoverHeightCalculator {
    /// Base height: account switcher + header + divider + detail + divider + footer + padding = ~300px
    static let baseHeight: CGFloat = 300
    static let updateBannerHeight: CGFloat = 56
    static let chartHeight: CGFloat = 230
    static let extraUsageHeight: CGFloat = 75
    static let profileSwitcherHeight: CGFloat = 28
    static let profileSummaryHeader: CGFloat = 32
    static let profileRowHeight: CGFloat = 24

    /// Calculate the total popover height based on which content sections are visible.
    ///
    /// - Parameters:
    ///   - profileCount: Number of configured profiles. Multi-profile UI shown when > 1.
    ///   - showExtraUsage: Whether the user has enabled showing extra usage in the popover.
    ///   - extraUsageEnabled: Whether the account has extra usage billing enabled.
    ///   - updateAvailable: Whether an app update is available (shows banner).
    ///   - showUsageTrend: Whether the usage trend chart is enabled.
    /// - Returns: The calculated height in points for the popover frame.
    static func calculate(
        profileCount: Int,
        showExtraUsage: Bool,
        extraUsageEnabled: Bool,
        updateAvailable: Bool,
        showUsageTrend: Bool
    ) -> CGFloat {
        var height = baseHeight

        if profileCount > 1 {
            height += profileSwitcherHeight + profileSummaryHeader + (CGFloat(profileCount) * profileRowHeight)
        }

        if showExtraUsage && extraUsageEnabled {
            height += extraUsageHeight
        }

        if updateAvailable {
            height += updateBannerHeight
        }

        if showUsageTrend {
            height += chartHeight
        }

        return height
    }
}
