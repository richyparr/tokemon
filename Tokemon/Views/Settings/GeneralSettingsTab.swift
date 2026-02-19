import SwiftUI
import ServiceManagement

/// Consolidated "General" settings tab merging refresh, data sources, display, updates, startup, and about.
struct GeneralSettingsTab: View {
    @Environment(UsageMonitor.self) private var monitor
    @Environment(UpdateManager.self) private var updateManager

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
            // MARK: - Refresh Interval
            Section {
                Picker("Refresh interval", selection: Binding(
                    get: { monitor.refreshInterval },
                    set: { newValue in
                        monitor.refreshInterval = newValue
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

            // MARK: - Data Sources
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Toggle("OAuth Endpoint (Primary)", isOn: $monitor.oauthEnabled)
                        .disabled(!monitor.oauthEnabled && !monitor.jsonlEnabled)
                        .onChange(of: monitor.oauthEnabled) { _, newValue in
                            if !newValue && !monitor.jsonlEnabled {
                                monitor.oauthEnabled = true
                            }
                        }

                    Text("Fetches usage data from Anthropic's API using your Claude Code credentials")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 20)

                    statusIndicator(for: monitor.oauthState, enabled: monitor.oauthEnabled)
                        .padding(.leading, 20)
                }

                Divider()
                    .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 6) {
                    Toggle("Claude Code Logs (Fallback)", isOn: $monitor.jsonlEnabled)
                        .disabled(!monitor.jsonlEnabled && !monitor.oauthEnabled)
                        .onChange(of: monitor.jsonlEnabled) { _, newValue in
                            if !newValue && !monitor.oauthEnabled {
                                monitor.jsonlEnabled = true
                            }
                        }

                    Text("Reads usage from local Claude Code session files in ~/.claude/")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 20)

                    statusIndicator(for: monitor.jsonlState, enabled: monitor.jsonlEnabled)
                        .padding(.leading, 20)
                }
            } header: {
                Text("Data Sources")
            } footer: {
                Text("At least one data source must be enabled")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // MARK: - Display
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

            // MARK: - Popover
            Section {
                Toggle("Show usage trend chart", isOn: $showUsageTrend)

                Text("Display a usage chart and burn rate in the popover")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Popover")
            }

            // MARK: - Updates
            Section {
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
            } header: {
                Text("Updates")
            }

            // MARK: - Startup
            Section {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        setLaunchAtLogin(newValue)
                    }

                Text("Automatically start Tokemon when you log in")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Startup")
            }

            // MARK: - About
            Section {
                LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                LabeledContent("Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")
            } header: {
                Text("About")
            }
        }
        .formStyle(.grouped)
        .onAppear {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    // MARK: - Helpers

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            launchAtLogin = SMAppService.mainApp.status == .enabled
            print("[GeneralSettingsTab] Failed to set launch at login: \(error)")
        }
    }

    private var currentIntervalLabel: String {
        intervals.first(where: { $0.value == monitor.refreshInterval })?.label ?? "\(Int(monitor.refreshInterval))s"
    }

    @ViewBuilder
    private func statusIndicator(for state: DataSourceState, enabled: Bool) -> some View {
        HStack(spacing: 6) {
            if !enabled {
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)
                Text("Disabled")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                switch state {
                case .available:
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Connected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                case .failed(let msg):
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                case .disabled:
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 8, height: 8)
                    Text("Disabled")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                case .notConfigured:
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                    Text("Not configured")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
