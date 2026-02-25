import SwiftUI

/// Main settings window with consolidated tabs: Profiles, General, Appearance, Notifications,
/// Terminal, Analytics, Budget, Admin, and Team (conditional).
struct SettingsView: View {
    @Environment(UsageMonitor.self) private var monitor
    @Environment(AlertManager.self) private var alertManager
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        TabView {
            ProfilesSettings()
                .tabItem {
                    Label("Profiles", systemImage: "person.2")
                }

            GeneralSettingsTab()
                .environment(monitor)
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            AppearanceSettings()
                .environment(monitor)
                .environment(themeManager)
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }

            NotificationsSettings()
                .environment(alertManager)
                .tabItem {
                    Label("Notifications", systemImage: "bell.badge")
                }

            StatuslineSettings()
                .tabItem {
                    Label("Terminal", systemImage: "terminal")
                }

            AnalyticsDashboardView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.xaxis")
                }

            BudgetDashboardView()
                .tabItem {
                    Label("Budget", systemImage: "dollarsign.gauge.chart.lefthalf.righthalf")
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
        .frame(minWidth: 880, minHeight: 400)
    }
}
