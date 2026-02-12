import SwiftUI

/// Placeholder settings view. Will be fully built in Plan 03.
struct SettingsView: View {
    @Environment(UsageMonitor.self) private var monitor

    var body: some View {
        Text("Settings")
            .font(.title)
            .padding(40)
            .frame(width: 400, height: 300)
    }
}
