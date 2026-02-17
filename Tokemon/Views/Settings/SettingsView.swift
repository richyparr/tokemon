import SwiftUI

/// Main settings window with tabs: Profiles, General, Data Sources, Appearance, Alerts, Analytics, License, Admin API, and Updates.
/// Uses native macOS TabView with automatic style for system-consistent settings.
struct SettingsView: View {
    @Environment(UsageMonitor.self) private var monitor
    @Environment(AlertManager.self) private var alertManager
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LicenseManager.self) private var licenseManager

    var body: some View {
        TabView {
            ProfilesSettings()
                .tabItem {
                    Label("Profiles", systemImage: "person.2")
                }

            GeneralSettings()
                .tabItem {
                    Label("Updates", systemImage: "arrow.triangle.2.circlepath.circle")
                }

            RefreshSettings()
                .environment(monitor)
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            DataSourceSettings()
                .environment(monitor)
                .tabItem {
                    Label("Sources", systemImage: "arrow.triangle.2.circlepath")
                }

            AppearanceSettings()
                .environment(monitor)
                .environment(themeManager)
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }

            StatuslineSettings()
                .tabItem {
                    Label("Terminal", systemImage: "terminal")
                }

            AlertSettings()
                .environment(alertManager)
                .tabItem {
                    Label("Alerts", systemImage: "bell.badge")
                }

            WebhookSettings()
                .tabItem {
                    Label("Webhooks", systemImage: "bell.and.waves.left.and.right")
                }

            AnalyticsDashboardView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.xaxis")
                }

            LicenseSettings()
                .environment(licenseManager)
                .tabItem {
                    Label("License", systemImage: "key.fill")
                }

            AdminAPISettings()
                .tabItem {
                    Label("Admin", systemImage: "building.2")
                }

            // Team tab only visible when Admin API is configured
            if AdminAPIClient.shared.hasAdminKey() {
                TeamDashboardView()
                    .tabItem {
                        Label("Team", systemImage: "person.3.fill")
                    }
            }
        }
        .frame(minWidth: 560, minHeight: 400)
    }
}
