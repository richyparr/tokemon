import SwiftUI

/// Settings tab for update preferences and app information.
struct GeneralSettings: View {
    @Environment(UpdateManager.self) private var updateManager

    var body: some View {
        Form {
            Section("Updates") {
                Toggle("Check for updates automatically", isOn: Binding(
                    get: { updateManager.autoCheckEnabled },
                    set: { updateManager.setAutoCheck($0) }
                ))

                HStack {
                    Button("Check for Updates Now") {
                        updateManager.checkForUpdates()
                    }
                    .disabled(updateManager.isChecking)

                    if updateManager.isChecking {
                        ProgressView()
                            .controlSize(.small)
                    }
                }

                if let error = updateManager.error {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                if updateManager.updateAvailable, let version = updateManager.availableVersion {
                    HStack {
                        Text("Version \(version) available")
                            .foregroundStyle(.blue)
                        Spacer()
                        Button("Download") {
                            updateManager.downloadUpdate()
                        }
                    }
                }
            }

            Section("About") {
                LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                LabeledContent("Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")
            }
        }
        .formStyle(.grouped)
    }
}
