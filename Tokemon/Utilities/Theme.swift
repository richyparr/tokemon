import SwiftUI
import AppKit

/// Available application themes.
enum AppTheme: String, CaseIterable, Identifiable {
    case native = "Native macOS"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }
}

/// Semantic color resolution based on theme and color scheme.
struct ThemeColors {
    let theme: AppTheme
    let colorScheme: ColorScheme

    /// Primary background color for views.
    var primaryBackground: Color {
        switch theme {
        case .native:
            // Uses system appearance - NSColor reads from system
            return Color(nsColor: .windowBackgroundColor)
        case .light:
            // Hardcoded light appearance colors (NSColor ignores preferredColorScheme)
            return Color(hex: 0xececec)
        case .dark:
            // Warm dark theme
            return colorScheme == .dark ? Color(hex: 0x141413) : Color(hex: 0xfaf9f5)
        }
    }

    /// Primary accent color for highlights and interactive elements.
    var primaryAccent: Color {
        switch theme {
        case .native:
            return Color.accentColor
        case .light:
            // System blue in light mode
            return Color(hex: 0x007aff)
        case .dark:
            // Warm accent
            return Color(hex: 0xc15f3c)
        }
    }

    /// Secondary text color for less prominent content.
    var secondaryText: Color {
        switch theme {
        case .native:
            return Color(nsColor: .secondaryLabelColor)
        case .light:
            // Dark gray for light backgrounds (macOS light mode secondary label)
            return Color(hex: 0x3c3c43, opacity: 0.6)
        case .dark:
            return Color(hex: 0xb0aea5)
        }
    }

    /// Tertiary text color for disabled/placeholder content.
    var tertiaryText: Color {
        switch theme {
        case .native:
            return Color(nsColor: .tertiaryLabelColor)
        case .light:
            // Medium gray for light backgrounds (readable but muted)
            return Color(hex: 0x3c3c43, opacity: 0.3)
        case .dark:
            return Color(hex: 0x8a877d)
        }
    }

    /// Usage percentage color (handles low-usage case for Light theme).
    /// For percentages >= 40%, returns the gradient color directly.
    /// For < 40%, returns theme-appropriate secondary color.
    func usageColor(for percentage: Double) -> Color {
        if percentage < 40 {
            return secondaryText
        }
        // Higher percentages use the standard gradient colors
        return Color(nsColor: GradientColors.color(for: percentage))
    }

    /// Gradient colors for charts and visualizations.
    var chartGradientColors: [Color] {
        switch theme {
        case .native:
            return [Color.accentColor.opacity(0.4), Color.accentColor.opacity(0.1)]
        case .light:
            // Use system blue for light theme (hardcoded to avoid NSColor issues)
            return [Color(hex: 0x007aff, opacity: 0.4), Color(hex: 0x007aff, opacity: 0.1)]
        case .dark:
            return [Color(hex: 0xc15f3c, opacity: 0.4), Color(hex: 0xc15f3c, opacity: 0.1)]
        }
    }

    /// Color scheme override for themes that enforce a specific appearance.
    /// Returns nil for themes that follow system appearance.
    var colorSchemeOverride: ColorScheme? {
        switch theme {
        case .native:
            return nil  // Follows system
        case .light:
            return .light  // Always light
        case .dark:
            return nil  // Follows system (warm tones adapt to light/dark)
        }
    }
}

/// Observable manager for application theme state.
@Observable
@MainActor
final class ThemeManager {
    /// The currently selected theme.
    var selectedTheme: AppTheme = .native {
        didSet {
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: "selectedTheme")
        }
    }

    init() {
        // Load persisted theme selection if available
        if let stored = UserDefaults.standard.string(forKey: "selectedTheme"),
           let theme = AppTheme(rawValue: stored) {
            self.selectedTheme = theme
        }
    }

    /// Returns ThemeColors for the given color scheme.
    /// - Parameter colorScheme: The current color scheme from the environment
    /// - Returns: A ThemeColors instance with resolved semantic colors
    func colors(for colorScheme: ColorScheme) -> ThemeColors {
        ThemeColors(theme: selectedTheme, colorScheme: colorScheme)
    }
}
