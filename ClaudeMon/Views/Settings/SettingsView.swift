import SwiftUI

/// Main settings window with five tabs: General, Data Sources, Appearance, Alerts, and Admin API.
/// Uses native macOS TabView with automatic style for system-consistent settings.
struct SettingsView: View {
    @Environment(UsageMonitor.self) private var monitor
    @Environment(AlertManager.self) private var alertManager

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

            AlertSettings()
                .environment(alertManager)
                .tabItem {
                    Label("Alerts", systemImage: "bell.badge")
                }

            AdminAPISettings()
                .tabItem {
                    Label("Admin API", systemImage: "building.2")
                }
        }
        .frame(minWidth: 420, minHeight: 320)
    }
}
