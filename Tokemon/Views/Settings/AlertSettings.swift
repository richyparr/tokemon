import SwiftUI
import ServiceManagement

/// Settings tab for alert thresholds, notifications, and startup behavior.
struct AlertSettings: View {
    @Environment(AlertManager.self) private var alertManager

    private let thresholdOptions = [50, 60, 70, 80, 90]

    // State for launch at login (read from system on appear, updated on toggle)
    @State private var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled

    var body: some View {
        @Bindable var alertManager = alertManager

        Form {
            // MARK: - Alert Threshold Section
            Section {
                Picker("Warning threshold", selection: $alertManager.alertThreshold) {
                    ForEach(thresholdOptions, id: \.self) { value in
                        Text("\(value)%").tag(value)
                    }
                }
                .pickerStyle(.menu)

                Text("Show visual warning when usage exceeds this percentage")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Alert Threshold")
            }

            // MARK: - Notifications Section
            Section {
                Toggle("macOS notifications", isOn: $alertManager.notificationsEnabled)
                    .onChange(of: alertManager.notificationsEnabled) { _, newValue in
                        if newValue {
                            alertManager.requestNotificationPermission()
                        }
                    }

                Text("Send system notifications when approaching usage limits")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Notifications")
            }

            // MARK: - Session Notifications Section
            Section {
                Toggle("Notify when session resets", isOn: Binding(
                    get: { alertManager.autoStartEnabled },
                    set: { alertManager.autoStartEnabled = $0 }
                ))

                Text("Get notified when your usage resets to 0%, indicating a fresh session is available.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Session Notifications")
            }

            // MARK: - Startup Section
            Section {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            print("[AlertSettings] Login item error: \(error.localizedDescription)")
                            // Revert on failure
                            launchAtLogin = SMAppService.mainApp.status == .enabled
                        }
                    }

                Text("Start Tokemon automatically when you log in")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Startup")
            }
        }
        .formStyle(.grouped)
        .onAppear {
            // Refresh launch at login state from system (user may have changed in System Settings)
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
