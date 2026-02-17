import AppKit

/// Usage-level gradient color mapping for menu bar text.
/// Color only when it matters — stays neutral until user needs to pay attention.
enum GradientColors {

    /// Returns an NSColor appropriate for the given usage percentage (0-100).
    ///
    /// Color progression:
    /// - 0-64%: White (neutral — nothing to worry about)
    /// - 65-79%: Amber (heads up — usage is elevated)
    /// - 80-94%: Orange (warning — pace yourself)
    /// - 95-100%: Red (critical — at the limit)
    static func color(for usage: Double) -> NSColor {
        switch usage {
        case ..<65:
            return NSColor.white
        case 65..<80:
            return NSColor(calibratedRed: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)  // Amber
        case 80..<95:
            return NSColor(calibratedRed: 1.0, green: 0.5, blue: 0.2, alpha: 1.0)  // Orange
        default:
            return NSColor(calibratedRed: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)  // Red
        }
    }

    /// Returns an NSColor for the given usage percentage, with monochrome override support.
    /// When `isMonochrome` is true, returns `NSColor.labelColor` regardless of usage level.
    /// This centralizes the monochrome logic so callers don't need to duplicate it.
    static func nsColor(for usage: Double, isMonochrome: Bool) -> NSColor {
        if isMonochrome {
            return NSColor.labelColor
        }
        return color(for: usage)
    }
}
