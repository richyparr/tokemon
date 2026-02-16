import SwiftUI

/// Settings tab for optional Admin API configuration.
/// Allows organization admins to connect their Admin API key for detailed usage data.
struct AdminAPISettings: View {
    @State private var apiKey: String = ""
    @State private var isConnected: Bool = false
    @State private var maskedKey: String = ""
    @State private var isValidating: Bool = false
    @State private var errorMessage: String?
    @State private var showingKeyField: Bool = false

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "building.2")
                            .foregroundStyle(.secondary)
                        Text("Organization Admin API")
                            .font(.headline)
                    }

                    Text("Connect an Admin API key to access detailed organization usage and cost data. This is optional and only available for organization accounts with admin permissions.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if isConnected {
                Section("Connected") {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(maskedKey)
                            .font(.system(.body, design: .monospaced))
                        Spacer()
                        Button("Disconnect") {
                            disconnect()
                        }
                        .foregroundColor(.red)
                    }
                }
            } else {
                Section("Connect Admin API") {
                    if showingKeyField {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                            TextField("sk-ant-admin...", text: $apiKey)
                                .textFieldStyle(.roundedBorder)
                                .disabled(isValidating)

                            Button {
                                if let clip = NSPasteboard.general.string(forType: .string) {
                                    apiKey = clip.trimmingCharacters(in: .whitespacesAndNewlines)
                                }
                            } label: {
                                Image(systemName: "doc.on.clipboard")
                            }
                            .buttonStyle(.borderless)
                            .help("Paste from clipboard")
                            .disabled(isValidating)
                        }

                            if let error = errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }

                            HStack {
                                Button("Cancel") {
                                    showingKeyField = false
                                    apiKey = ""
                                    errorMessage = nil
                                }
                                .disabled(isValidating)

                                Button("Connect") {
                                    connect()
                                }
                                .disabled(apiKey.isEmpty || isValidating)
                                .keyboardShortcut(.defaultAction)

                                if isValidating {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                        .padding(.leading, 4)
                                }
                            }
                        }
                    } else {
                        Button("Add Admin API Key...") {
                            showingKeyField = true
                        }
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("How to get an Admin API key:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("1. Go to console.anthropic.com")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("2. Navigate to Settings > Admin API")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("3. Create a new Admin API key")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            checkConnection()
        }
    }

    private func checkConnection() {
        isConnected = AdminAPIClient.shared.hasAdminKey()
        if isConnected {
            Task {
                maskedKey = await AdminAPIClient.shared.getMaskedKey() ?? "Connected"
            }
        }
    }

    private func connect() {
        errorMessage = nil
        isValidating = true

        Task {
            do {
                // Store key
                try await AdminAPIClient.shared.setAdminKey(apiKey)

                // Validate by making test request
                try await AdminAPIClient.shared.validateKey()

                // Success
                isConnected = true
                showingKeyField = false
                apiKey = ""
                isValidating = false
                checkConnection()
            } catch {
                let message = error.localizedDescription
                // Clear invalid key on failure
                try? await AdminAPIClient.shared.clearAdminKey()
                errorMessage = message
                isValidating = false
            }
        }
    }

    private func disconnect() {
        Task {
            try? await AdminAPIClient.shared.clearAdminKey()
            isConnected = false
            maskedKey = ""
        }
    }
}
