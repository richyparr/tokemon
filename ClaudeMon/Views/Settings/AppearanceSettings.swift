import SwiftUI

/// Settings tab for menu bar appearance configuration.
/// Phase 1: Percentage mode fully implemented; logo and gauge are future placeholders.
struct AppearanceSettings: View {
    @Environment(UsageMonitor.self) private var monitor

    /// Menu bar icon style options
    enum IconStyle: String, CaseIterable, Identifiable {
        case percentage = "Percentage"
        case claudeLogo = "Claude Logo"
        case gaugeMeter = "Gauge Meter"

        var id: String { rawValue }
    }

    @AppStorage("menuBarIconStyle") private var selectedStyle: String = IconStyle.percentage.rawValue

    var body: some View {
        Form {
            Section {
                Picker("Menu bar display", selection: $selectedStyle) {
                    Text("Percentage").tag(IconStyle.percentage.rawValue)
                    Text("Claude Logo (coming soon)").tag(IconStyle.claudeLogo.rawValue)
                    Text("Gauge Meter (coming soon)").tag(IconStyle.gaugeMeter.rawValue)
                }
                .pickerStyle(.radioGroup)

                if selectedStyle != IconStyle.percentage.rawValue {
                    Text("This style will be available in a future update. Using percentage for now.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            } header: {
                Text("Menu Bar Display")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
