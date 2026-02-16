import SwiftUI

/// Settings tab for configuring the refresh interval and display options.
/// Clean dropdown with preset intervals.
struct RefreshSettings: View {
    @Environment(UsageMonitor.self) private var monitor

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
        }
        .formStyle(.grouped)
    }

    private var currentIntervalLabel: String {
        intervals.first(where: { $0.value == monitor.refreshInterval })?.label ?? "\(Int(monitor.refreshInterval))s"
    }
}
