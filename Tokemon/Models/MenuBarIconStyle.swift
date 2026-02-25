import Foundation

/// Defines the available menu bar icon display styles.
/// Each style represents a different visual way to communicate usage in the menu bar.
enum MenuBarIconStyle: String, CaseIterable, Identifiable {
    /// Text-only percentage display (e.g., "42%") -- the original default behavior
    case percentage

    /// Horizontal battery icon that fills based on usage
    case battery

    /// Thin horizontal progress bar
    case progressBar

    /// SF Symbol (bolt) plus percentage text (e.g., "bolt 42%")
    case iconAndBar

    /// Abbreviated percentage text without the % sign (e.g., "42")
    case compact

    /// Colored circle (traffic light) with percentage text (e.g., "● 42%")
    case trafficLight

    var id: String { rawValue }

    /// Human-readable display name for the settings UI
    var displayName: String {
        switch self {
        case .percentage: return "Percentage"
        case .battery: return "Battery"
        case .progressBar: return "Progress Bar"
        case .iconAndBar: return "Icon & Bar"
        case .compact: return "Compact"
        case .trafficLight: return "Traffic Light"
        }
    }

    /// SF Symbol name for use in the settings picker
    var systemImage: String {
        switch self {
        case .percentage: return "percent"
        case .battery: return "battery.75percent"
        case .progressBar: return "chart.bar.fill"
        case .iconAndBar: return "bolt.fill"
        case .compact: return "number"
        case .trafficLight: return "circle.fill"
        }
    }
}
