import SwiftUI

/// Settings tab for menu bar appearance configuration.
/// Provides theme selection, icon style picker (5 styles), and monochrome toggle.
struct AppearanceSettings: View {
    @Environment(UsageMonitor.self) private var monitor
    @Environment(ThemeManager.self) private var themeManager

    @AppStorage("menuBarIconStyle") private var selectedStyle: String = MenuBarIconStyle.percentage.rawValue
    @AppStorage("menuBarMonochrome") private var isMonochrome: Bool = false

    /// Description text for the currently selected theme
    private var themeDescription: String {
        switch themeManager.selectedTheme {
        case .native:
            return "Follows your macOS appearance settings"
        case .light:
            return "Always light appearance"
        case .dark:
            return "Warm tones with orange accents"
        }
    }

    /// Description text for the currently selected icon style
    private var styleDescription: String {
        guard let style = MenuBarIconStyle(rawValue: selectedStyle) else {
            return ""
        }
        switch style {
        case .percentage:
            return "Shows usage as a colored percentage (e.g., 42%)"
        case .battery:
            return "Battery icon that fills as usage increases"
        case .progressBar:
            return "Thin progress bar showing usage level"
        case .iconAndBar:
            return "Lightning bolt icon with percentage text"
        case .compact:
            return "Minimal number display without % sign"
        case .trafficLight:
            return "Colored circle with percentage text (green/amber/orange/red)"
        }
    }

    var body: some View {
        Form {
            // Section 1: Theme (existing, unchanged)
            Section {
                @Bindable var manager = themeManager

                Picker("Theme", selection: $manager.selectedTheme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
                .pickerStyle(.radioGroup)

                Text(themeDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Theme")
            }

            // Section 2: Menu Bar Icon (5-style picker with descriptions)
            Section {
                Picker("Icon style", selection: $selectedStyle) {
                    ForEach(MenuBarIconStyle.allCases) { style in
                        Text(style.displayName).tag(style.rawValue)
                    }
                }
                .pickerStyle(.radioGroup)

                Text(styleDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Menu Bar Icon")
            }

            // Section 3: Monochrome (toggle with explanation)
            Section {
                Toggle("Monochrome icon", isOn: $isMonochrome)

                Text("Use a single color that matches the native macOS menu bar style. When off, the icon color shifts from green to orange to red as usage increases.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Color Mode")
            }
        }
        .formStyle(.grouped)
        .onChange(of: selectedStyle) { _, _ in
            NotificationCenter.default.post(name: Notification.Name("MenuBarStyleChanged"), object: nil)
        }
        .onChange(of: isMonochrome) { _, _ in
            NotificationCenter.default.post(name: Notification.Name("MenuBarStyleChanged"), object: nil)
        }
    }
}
