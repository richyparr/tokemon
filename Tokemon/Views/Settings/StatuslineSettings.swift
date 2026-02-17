import SwiftUI
import AppKit

/// Settings tab for terminal statusline configuration.
/// Allows enabling export, field selection, format customization, and one-click shell install.
struct StatuslineSettings: View {
    @State private var config = StatuslineConfig.load()
    @State private var isCopied = false
    @State private var showInstallAlert = false
    @State private var installAlertMessage = ""
    @State private var installSuccess = false

    /// Preview of the statusline with current format settings
    private var previewText: String {
        var fields: [String] = []

        if config.showSessionPercent {
            fields.append("S:42%")
        }
        if config.showWeeklyPercent {
            fields.append("W:78%")
        }
        if config.showResetTimer {
            fields.append("R:2h15m")
        }

        let content = fields.joined(separator: config.separator)
        return "\(config.prefix)\(content)\(config.suffix)"
    }

    /// Shell install command for clipboard
    private var installCommand: String {
        """
        # Tokemon terminal statusline
        [ -f ~/.tokemon/tokemon-statusline.sh ] && source ~/.tokemon/tokemon-statusline.sh
        """
    }

    /// Detect user's shell config file
    private var shellConfigPath: String {
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        if shell.contains("zsh") {
            return "~/.zshrc"
        } else if shell.contains("bash") {
            // macOS Catalina+ uses zsh by default, but respect SHELL if set to bash
            return "~/.bashrc"
        }
        return "~/.zshrc" // Default to zsh
    }

    var body: some View {
        Form {
            // Section 1: Enable toggle
            Section {
                Toggle("Enable statusline export", isOn: $config.enabled)
                    .onChange(of: config.enabled) { _, _ in
                        saveAndNotify()
                    }

                Text("When enabled, Tokemon writes usage data to ~/.tokemon/statusline for your shell prompt.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Terminal Statusline")
            }

            // Section 2: Field selection (only shown when enabled)
            if config.enabled {
                Section {
                    Toggle("Session usage %", isOn: $config.showSessionPercent)
                        .onChange(of: config.showSessionPercent) { _, _ in saveAndNotify() }

                    Toggle("Weekly usage %", isOn: $config.showWeeklyPercent)
                        .onChange(of: config.showWeeklyPercent) { _, _ in saveAndNotify() }

                    Toggle("Reset timer", isOn: $config.showResetTimer)
                        .onChange(of: config.showResetTimer) { _, _ in saveAndNotify() }
                } header: {
                    Text("Fields")
                }

                // Section 3: Format options
                Section {
                    HStack {
                        Text("Separator")
                        Spacer()
                        TextField("", text: $config.separator)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                            .onSubmit { saveAndNotify() }
                    }

                    HStack {
                        Text("Prefix")
                        Spacer()
                        TextField("", text: $config.prefix)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                            .onSubmit { saveAndNotify() }
                    }

                    HStack {
                        Text("Suffix")
                        Spacer()
                        TextField("", text: $config.suffix)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                            .onSubmit { saveAndNotify() }
                    }

                    Toggle("ANSI colors", isOn: $config.useColors)
                        .onChange(of: config.useColors) { _, _ in saveAndNotify() }

                    Text("Colors show usage severity: green (<50%), yellow (50-79%), red (80%+)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Format")
                }

                // Section 4: Preview
                Section {
                    Text(previewText)
                        .font(.system(.body, design: .monospaced))
                        .padding(.vertical, 4)
                } header: {
                    Text("Preview")
                }

                // Section 5: Shell Integration
                Section {
                    Text("Add this line to your \(shellConfigPath):")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(installCommand)
                        .font(.system(.caption, design: .monospaced))
                        .padding(8)
                        .background(Color(nsColor: .textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    HStack {
                        Button(action: copyInstallCommand) {
                            HStack(spacing: 4) {
                                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                Text(isCopied ? "Copied!" : "Copy Install Command")
                            }
                        }

                        Spacer()

                        Button("Add to \(shellConfigPath)") {
                            installToShellConfig()
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    Text("Then add $(tokemon_statusline) to your PS1 or PROMPT variable.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Shell Integration")
                }

                // Section 6: Advanced
                Section {
                    Text("Raw JSON data is also available at ~/.tokemon/status.json for custom integrations.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Advanced")
                }
            }
        }
        .formStyle(.grouped)
        .alert(installAlertMessage, isPresented: $showInstallAlert) {
            Button("OK") {}
        }
    }

    // MARK: - Actions

    private func saveAndNotify() {
        config.save()
        NotificationCenter.default.post(name: StatuslineExporter.configChangedNotification, object: nil)
    }

    private func copyInstallCommand() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(installCommand, forType: .string)

        isCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isCopied = false
        }
    }

    private func installToShellConfig() {
        let configFile = (shellConfigPath as NSString).expandingTildeInPath

        // Check if already installed
        if let contents = try? String(contentsOfFile: configFile, encoding: .utf8) {
            if contents.contains("tokemon-statusline.sh") {
                installAlertMessage = "Tokemon statusline is already installed in \(shellConfigPath)"
                showInstallAlert = true
                return
            }
        }

        // Append the install command
        let appendText = "\n\n\(installCommand)\n"

        do {
            let fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: configFile))
            defer { try? fileHandle.close() }
            try fileHandle.seekToEnd()
            if let data = appendText.data(using: .utf8) {
                try fileHandle.write(contentsOf: data)
            }
            installAlertMessage = "Tokemon statusline installed! Restart your terminal or run:\n\nsource \(shellConfigPath)"
            installSuccess = true
        } catch {
            // File might not exist, try to create it
            do {
                try installCommand.write(toFile: configFile, atomically: true, encoding: .utf8)
                installAlertMessage = "Tokemon statusline installed! Restart your terminal or run:\n\nsource \(shellConfigPath)"
                installSuccess = true
            } catch {
                installAlertMessage = "Failed to install: \(error.localizedDescription)"
                installSuccess = false
            }
        }

        showInstallAlert = true
    }
}
