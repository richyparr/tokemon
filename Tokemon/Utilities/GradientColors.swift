import AppKit

/// Usage-level gradient color mapping for menu bar text.
/// Uses subtle, calibrated colors -- NOT harsh traffic light colors.
/// Per user decision: unobtrusive at low usage, gradually warming as usage increases.
enum GradientColors {

    /// Returns an NSColor appropriate for the given usage percentage (0-100).
    ///
    /// Color progression:
    /// - 0-39%: White (visible against any menu bar background)
    /// - 40-64%: Bright green
    /// - 65-79%: Amber/yellow
    /// - 80-94%: Orange
    /// - 95-100%: Red
    static func color(for usage: Double) -> NSColor {
        switch usage {
        case ..<40:
            return NSColor.white
        case 40..<65:
            return NSColor(calibratedRed: 0.4, green: 0.8, blue: 0.4, alpha: 1.0)
        case 65..<80:
            return NSColor(calibratedRed: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)
        case 80..<95:
            return NSColor(calibratedRed: 1.0, green: 0.5, blue: 0.2, alpha: 1.0)
        default:
            return NSColor(calibratedRed: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)
        }
    }
}
