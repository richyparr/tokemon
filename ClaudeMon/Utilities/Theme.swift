import SwiftUI
import AppKit

/// Available application themes.
enum AppTheme: String, CaseIterable, Identifiable {
    case native = "Native macOS"
    case minimalDark = "Minimal Dark"
    case anthropic = "Anthropic"

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
            return Color(nsColor: .windowBackgroundColor)
        case .minimalDark:
            return Color(hex: 0x1a1a1a)
        case .anthropic:
            return colorScheme == .dark ? Color(hex: 0x141413) : Color(hex: 0xfaf9f5)
        }
    }

    /// Primary accent color for highlights and interactive elements.
    var primaryAccent: Color {
        switch theme {
        case .native:
            return Color.accentColor
        case .minimalDark:
            return Color(hex: 0x4a9eff)
        case .anthropic:
            // Crail orange - Anthropic brand color
            return Color(hex: 0xc15f3c)
        }
    }

    /// Secondary text color for less prominent content.
    var secondaryText: Color {
        switch theme {
        case .native:
            return Color(nsColor: .secondaryLabelColor)
        case .minimalDark:
            return Color(hex: 0x8e8e93)
        case .anthropic:
            return Color(hex: 0xb0aea5)
        }
    }

    /// Gradient colors for charts and visualizations.
    var chartGradientColors: [Color] {
        switch theme {
        case .native:
            return [Color.accentColor.opacity(0.4), Color.accentColor.opacity(0.1)]
        case .minimalDark:
            return [Color(hex: 0x4a9eff, opacity: 0.4), Color(hex: 0x4a9eff, opacity: 0.1)]
        case .anthropic:
            return [Color(hex: 0xc15f3c, opacity: 0.4), Color(hex: 0xc15f3c, opacity: 0.1)]
        }
    }

    /// Color scheme override for themes that enforce a specific appearance.
    /// Returns nil for themes that follow system appearance.
    var colorSchemeOverride: ColorScheme? {
        switch theme {
        case .native:
            return nil  // Follows system
        case .minimalDark:
            return .dark  // Always dark
        case .anthropic:
            return nil  // Follows system (works in both light and dark)
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
