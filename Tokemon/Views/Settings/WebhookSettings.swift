import SwiftUI

/// Settings tab for configuring Slack and Discord webhook alert destinations.
/// Pro-gated: non-Pro users see an upgrade prompt instead of the settings form.
struct WebhookSettings: View {
    @Environment(WebhookManager.self) private var webhookManager
    @Environment(FeatureAccessManager.self) private var featureAccess

    @State private var testingSlack = false
    @State private var testingDiscord = false
    @State private var testResult: String?
    @State private var showTestResult = false

    var body: some View {
        @Bindable var webhookManager = webhookManager

        if featureAccess.canAccess(.webhookAlerts) {
            Form {
                // MARK: - Slack Section
                Section {
                    Toggle("Enable Slack alerts", isOn: $webhookManager.config.slackEnabled)

                    if webhookManager.config.slackEnabled {
                        TextField("Webhook URL", text: $webhookManager.config.slackWebhookURL, prompt: Text("https://hooks.slack.com/services/..."))
                            .textFieldStyle(.roundedBorder)

                        Button {
                            Task {
                                testingSlack = true
                                do {
                                    try await webhookManager.testWebhook(service: .slack)
                                    testResult = "Slack webhook is working! Check your channel."
                                } catch {
                                    testResult = "Slack test failed: \(error.localizedDescription)"
                                }
                                testingSlack = false
                                showTestResult = true
                            }
                        } label: {
                            if testingSlack {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Text("Test")
                            }
                        }
                        .disabled(webhookManager.config.slackWebhookURL.isEmpty || testingSlack)
                    }

                    Text("Paste your Slack Incoming Webhook URL. Create one at api.slack.com/messaging/webhooks")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Slack")
                }

                // MARK: - Discord Section
                Section {
                    Toggle("Enable Discord alerts", isOn: $webhookManager.config.discordEnabled)

                    if webhookManager.config.discordEnabled {
                        TextField("Webhook URL", text: $webhookManager.config.discordWebhookURL, prompt: Text("https://discord.com/api/webhooks/..."))
                            .textFieldStyle(.roundedBorder)

                        Button {
                            Task {
                                testingDiscord = true
                                do {
                                    try await webhookManager.testWebhook(service: .discord)
                                    testResult = "Discord webhook is working! Check your channel."
                                } catch {
                                    testResult = "Discord test failed: \(error.localizedDescription)"
                                }
                                testingDiscord = false
                                showTestResult = true
                            }
                        } label: {
                            if testingDiscord {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Text("Test")
                            }
                        }
                        .disabled(webhookManager.config.discordWebhookURL.isEmpty || testingDiscord)
                    }

                    Text("Paste your Discord Webhook URL. Create one in Server Settings > Integrations > Webhooks")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Discord")
                }

                // MARK: - Message Template Section
                Section {
                    Toggle("Include usage percentage", isOn: $webhookManager.config.includePercentage)
                    Toggle("Include reset time", isOn: $webhookManager.config.includeResetTime)
                    Toggle("Include weekly usage", isOn: $webhookManager.config.includeWeeklyUsage)
                    Toggle("Include profile name", isOn: $webhookManager.config.includeProfileName)

                    TextField("Custom message", text: $webhookManager.config.customMessage, prompt: Text("Optional message to include in alerts"))
                        .textFieldStyle(.roundedBorder)

                    Text("Choose which fields appear in your webhook messages")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Message Template")
                }
            }
            .formStyle(.grouped)
            .alert("Webhook Test", isPresented: $showTestResult) {
                Button("OK", role: .cancel) {}
            } message: {
                if let testResult {
                    Text(testResult)
                }
            }
        } else {
            // Upgrade prompt for non-Pro users
            VStack(spacing: 16) {
                Spacer()

                Image(systemName: "bell.and.waves.left.and.right")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text("Webhook Alerts")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Send usage alerts to Slack and Discord channels. Requires Tokemon Pro.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)

                Button("Upgrade to Pro") {
                    featureAccess.openPurchasePage()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
