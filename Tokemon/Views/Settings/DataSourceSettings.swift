import SwiftUI

/// Settings tab for enabling/disabling data sources.
/// Toggles OAuth and JSONL independently with at-least-one-enabled guard.
struct DataSourceSettings: View {
    @Environment(UsageMonitor.self) private var monitor
    @Environment(FeatureAccessManager.self) private var featureAccess

    var body: some View {
        @Bindable var monitor = monitor

        Form {
            Section {
                // OAuth toggle
                VStack(alignment: .leading, spacing: 6) {
                    Toggle("OAuth Endpoint (Primary)", isOn: $monitor.oauthEnabled)
                        .disabled(!monitor.oauthEnabled && !monitor.jsonlEnabled)
                        .onChange(of: monitor.oauthEnabled) { _, newValue in
                            if !newValue && !monitor.jsonlEnabled {
                                // Prevent disabling both -- re-enable
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

                // JSONL toggle
                VStack(alignment: .leading, spacing: 6) {
                    Toggle("Claude Code Logs (Fallback)", isOn: $monitor.jsonlEnabled)
                        .disabled(!monitor.jsonlEnabled && !monitor.oauthEnabled)
                        .onChange(of: monitor.jsonlEnabled) { _, newValue in
                            if !newValue && !monitor.oauthEnabled {
                                // Prevent disabling both -- re-enable
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

            // Pro Features teaser (preparation for Phase 7 multi-account)
            Section {
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundStyle(.secondary)
                    Text("Multiple accounts")
                    Spacer()
                    if featureAccess.isPro {
                        Text("Coming in v2.1")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ProBadge()
                    }
                }
                .opacity(0.6)
            } header: {
                Text("Pro Features")
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Status Indicator

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
