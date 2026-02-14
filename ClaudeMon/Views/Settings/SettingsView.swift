import SwiftUI

/// Main settings window with seven tabs: General, Data Sources, Appearance, Alerts, Accounts, License, and Admin API.
/// Uses native macOS TabView with automatic style for system-consistent settings.
struct SettingsView: View {
    @Environment(UsageMonitor.self) private var monitor
    @Environment(AlertManager.self) private var alertManager
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LicenseManager.self) private var licenseManager
    @Environment(AccountManager.self) private var accountManager

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
                .environment(themeManager)
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }

            AlertSettings()
                .environment(alertManager)
                .tabItem {
                    Label("Alerts", systemImage: "bell.badge")
                }

            AccountsSettings()
                .tabItem {
                    Label("Accounts", systemImage: "person.2.fill")
                }

            LicenseSettings()
                .environment(licenseManager)
                .tabItem {
                    Label("License", systemImage: "key.fill")
                }

            AdminAPISettings()
                .tabItem {
                    Label("Admin API", systemImage: "building.2")
                }
        }
        .frame(minWidth: 420, minHeight: 320)
    }
}
