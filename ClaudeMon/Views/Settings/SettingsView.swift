import SwiftUI

/// Main settings window with three tabs: General, Data Sources, and Appearance.
/// Uses native macOS TabView with automatic style for system-consistent settings.
struct SettingsView: View {
    @Environment(UsageMonitor.self) private var monitor

    var body: some View {
        TabView {
            RefreshSettings()
                .environment(monitor)
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            DataSourceSettings()
                .environment(monitor)
                .tabItem {
                    Label("Data Sources", systemImage: "arrow.triangle.2.circlepath")
                }

            AppearanceSettings()
                .environment(monitor)
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }
        }
        .frame(minWidth: 420, minHeight: 280)
    }
}
