import SwiftUI
import ServiceManagement

/// Settings tab for alert thresholds, notifications, and startup behavior.
struct AlertSettings: View {
    @Environment(AlertManager.self) private var alertManager

    private let thresholdOptions = [50, 60, 70, 80, 90]

    // Read launch-at-login state directly from system (not UserDefaults)
    private var launchAtLoginEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    var body: some View {
        Form {
            // MARK: - Alert Threshold Section
            Section {
                Picker("Warning threshold", selection: Binding(
                    get: { alertManager.alertThreshold },
                    set: { alertManager.alertThreshold = $0 }
                )) {
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
                Toggle("macOS notifications", isOn: Binding(
                    get: { alertManager.notificationsEnabled },
                    set: { alertManager.notificationsEnabled = $0 }
                ))

                Text("Send system notifications when approaching usage limits")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Show warning if notifications enabled but permission denied
                if alertManager.notificationsEnabled && !alertManager.notificationPermissionGranted {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Notifications not permitted")
                            .font(.caption)
                        Spacer()
                        Button("Open Settings") {
                            openNotificationSettings()
                        }
                        .font(.caption)
                    }
                    .padding(.top, 4)
                }
            } header: {
                Text("Notifications")
            }

            // MARK: - Startup Section
            Section {
                Toggle("Launch at login", isOn: Binding(
                    get: { launchAtLoginEnabled },
                    set: { newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            print("[AlertSettings] Login item error: \(error.localizedDescription)")
                        }
                    }
                ))

                Text("Start ClaudeMon automatically when you log in")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Startup")
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func openNotificationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }
}
