import SwiftUI
import AppKit

extension Color {
    /// Initialize a Color from a hex value.
    /// - Parameters:
    ///   - hex: A UInt64 hex value (e.g., 0x1a1a1a or 0xc15f3c)
    ///   - opacity: Optional opacity from 0.0 to 1.0 (default 1.0)
    init(hex: UInt64, opacity: Double = 1.0) {
        let red = Double((hex >> 16) & 0xff) / 255.0
        let green = Double((hex >> 8) & 0xff) / 255.0
        let blue = Double(hex & 0xff) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}

extension NSColor {
    /// Initialize an NSColor from a hex value.
    /// - Parameters:
    ///   - hex: A UInt64 hex value (e.g., 0x1a1a1a or 0xc15f3c)
    ///   - alpha: Optional alpha from 0.0 to 1.0 (default 1.0)
    convenience init(hex: UInt64, alpha: CGFloat = 1.0) {
        let red = CGFloat((hex >> 16) & 0xff) / 255.0
        let green = CGFloat((hex >> 8) & 0xff) / 255.0
        let blue = CGFloat(hex & 0xff) / 255.0
        self.init(srgbRed: red, green: green, blue: blue, alpha: alpha)
    }
}
