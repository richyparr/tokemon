import SwiftUI
import ServiceManagement

/// Settings tab for configuring the refresh interval and display options.
/// Clean dropdown with preset intervals.
struct RefreshSettings: View {
    @Environment(UsageMonitor.self) private var monitor
    @AppStorage("showUsageTrend") private var showUsageTrend: Bool = false
    @State private var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled

    /// Available refresh intervals (in seconds)
    private let intervals: [(label: String, value: TimeInterval)] = [
        ("30 seconds", 30),
        ("1 minute", 60),
        ("2 minutes", 120),
        ("5 minutes", 300),
        ("10 minutes", 600),
    ]

    var body: some View {
        @Bindable var monitor = monitor

        Form {
            Section {
                Picker("Refresh interval", selection: Binding(
                    get: { monitor.refreshInterval },
                    set: { newValue in
                        monitor.refreshInterval = newValue
                        // Restart polling with the new interval
                        monitor.startPolling(interval: newValue)
                    }
                )) {
                    ForEach(intervals, id: \.value) { interval in
                        Text(interval.label).tag(interval.value)
                    }
                }
                .pickerStyle(.menu)

                Text("Data refreshes every \(currentIntervalLabel)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Refresh Interval")
            }

            Section {
                Toggle("Show extra usage", isOn: Binding(
                    get: { monitor.showExtraUsage },
                    set: { monitor.showExtraUsage = $0 }
                ))

                Text("Display billing information (spent, monthly limit) when available")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Display")
            }

            Section {
                Toggle("Show usage trend chart", isOn: $showUsageTrend)

                Text("Display a usage chart and burn rate in the popover")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Popover")
            }

            Section {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        setLaunchAtLogin(newValue)
                    }

                Text("Automatically start tokemon when you log in")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Startup")
            }
        }
        .formStyle(.grouped)
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Revert toggle on failure
            launchAtLogin = SMAppService.mainApp.status == .enabled
            print("[RefreshSettings] Failed to set launch at login: \(error)")
        }
    }

    private var currentIntervalLabel: String {
        intervals.first(where: { $0.value == monitor.refreshInterval })?.label ?? "\(Int(monitor.refreshInterval))s"
    }
}
