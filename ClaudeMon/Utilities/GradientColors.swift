import AppKit

/// Usage-level gradient color mapping for menu bar text.
/// Uses subtle, calibrated colors -- NOT harsh traffic light colors.
/// Per user decision: unobtrusive at low usage, gradually warming as usage increases.
enum GradientColors {

    /// Returns an NSColor appropriate for the given usage percentage (0-100).
    ///
    /// Color progression:
    /// - 0-39%: Secondary label color (subtle, blends with system)
    /// - 40-64%: Muted warm green-yellow
    /// - 65-79%: Amber
    /// - 80-94%: Warm orange
    /// - 95-100%: Muted red
    static func color(for usage: Double) -> NSColor {
        switch usage {
        case ..<40:
            return NSColor.secondaryLabelColor
        case 40..<65:
            return NSColor(calibratedRed: 0.6, green: 0.7, blue: 0.3, alpha: 1.0)
        case 65..<80:
            return NSColor(calibratedRed: 0.85, green: 0.6, blue: 0.2, alpha: 1.0)
        case 80..<95:
            return NSColor(calibratedRed: 0.9, green: 0.4, blue: 0.2, alpha: 1.0)
        default:
            return NSColor(calibratedRed: 0.85, green: 0.25, blue: 0.2, alpha: 1.0)
        }
    }
}
