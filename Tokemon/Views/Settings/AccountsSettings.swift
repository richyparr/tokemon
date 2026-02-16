import SwiftUI

/// Settings tab for managing Claude accounts.
/// Allows adding, renaming, and removing accounts.
struct AccountsSettings: View {
    @Environment(AccountManager.self) private var accountManager
    @Environment(FeatureAccessManager.self) private var featureAccess

    @State private var selectedAccount: Account?
    @State private var showingRemoveConfirmation = false
    @State private var editingDisplayName = ""
    @State private var isEditingName = false
    @State private var isCheckingForAccounts = false
    @State private var checkResultMessage: String?

    var body: some View {
        Form {
            // Combined usage view when multiple accounts exist
            if accountManager.accounts.count > 1 {
                Section {
                    CombinedUsageView()
                }
            }

            Section("Accounts") {
                if accountManager.accounts.isEmpty {
                    Text("No accounts configured")
                        .foregroundStyle(.secondary)
                        .italic()
                } else {
                    ForEach(accountManager.accounts) { account in
                        accountRow(account)
                    }
                }
            }

            if let account = selectedAccount {
                Section("Account Details") {
                    // Display name editor
                    HStack {
                        Text("Display Name")
                        Spacer()
                        if isEditingName {
                            TextField("Name", text: $editingDisplayName)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 150)
                                .onSubmit {
                                    saveDisplayName(for: account)
                                }
                            Button("Save") {
                                saveDisplayName(for: account)
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            Text(account.displayName)
                                .foregroundStyle(.secondary)
                            Button("Edit") {
                                editingDisplayName = account.displayName
                                isEditingName = true
                            }
                            .buttonStyle(.borderless)
                        }
                    }

                    // Username (read-only)
                    HStack {
                        Text("Username")
                        Spacer()
                        Text(account.username)
                            .foregroundStyle(.secondary)
                    }

                    // Created date
                    HStack {
                        Text("Added")
                        Spacer()
                        Text(account.createdAt, style: .date)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Alert Settings for \(account.displayName)") {
                    // Alert threshold slider
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Alert Threshold")
                            Spacer()
                            Text("\(account.settings.alertThreshold)%")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }

                        Slider(
                            value: Binding(
                                get: { Double(account.settings.alertThreshold) },
                                set: { newValue in
                                    updateThreshold(for: account, value: Int(newValue))
                                }
                            ),
                            in: 50...100,
                            step: 5
                        )

                        Text("Get notified when this account reaches this usage percentage")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Notifications toggle
                    Toggle("Enable Notifications", isOn: Binding(
                        get: { account.settings.notificationsEnabled },
                        set: { newValue in
                            updateNotifications(for: account, enabled: newValue)
                        }
                    ))
                }

                Section {
                    Button("Remove Account", role: .destructive) {
                        showingRemoveConfirmation = true
                    }
                    .disabled(accountManager.accounts.count == 1)
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Adding Accounts")
                        .font(.headline)
                    Text("To add another Claude account, run `claude login` in Terminal with different credentials, then click the button below to detect the new account.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        Button {
                            Task {
                                await checkForNewAccounts()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                if isCheckingForAccounts {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                }
                                Text("Check for New Accounts")
                            }
                        }
                        .disabled(isCheckingForAccounts)

                        if let message = checkResultMessage {
                            Text(message)
                                .font(.caption)
                                .foregroundStyle(message.contains("Found") ? .green : .secondary)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .confirmationDialog(
            "Remove Account?",
            isPresented: $showingRemoveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                if let account = selectedAccount {
                    Task {
                        try? await accountManager.removeAccount(account)
                        selectedAccount = nil
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the account from Tokemon. Your Claude credentials will not be affected.")
        }
        .proGated(.multiAccount)
    }

    @ViewBuilder
    private func accountRow(_ account: Account) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(account.displayName)
                    .fontWeight(.medium)
                if account.displayName != account.username {
                    Text(account.username)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if account.id == accountManager.activeAccount?.id {
                Text("Active")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.2))
                    .foregroundStyle(.green)
                    .clipShape(Capsule())
            } else {
                Button("Switch") {
                    Task { try? await accountManager.setActiveAccount(account) }
                }
                .buttonStyle(.borderless)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedAccount = account
            isEditingName = false
        }
        .background(selectedAccount?.id == account.id ? Color.accentColor.opacity(0.1) : Color.clear)
    }

    private func saveDisplayName(for account: Account) {
        let trimmed = editingDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        Task {
            try? await accountManager.updateDisplayName(account, displayName: trimmed)
            isEditingName = false
            // Update selectedAccount to reflect change
            if let updated = accountManager.accounts.first(where: { $0.id == account.id }) {
                selectedAccount = updated
            }
        }
    }

    private func updateThreshold(for account: Account, value: Int) {
        var settings = account.settings
        settings.alertThreshold = value
        Task {
            try? await accountManager.updateAccountSettings(account, settings: settings)
            // Refresh selected account
            if let updated = accountManager.accounts.first(where: { $0.id == account.id }) {
                selectedAccount = updated
            }
        }
    }

    private func updateNotifications(for account: Account, enabled: Bool) {
        var settings = account.settings
        settings.notificationsEnabled = enabled
        Task {
            try? await accountManager.updateAccountSettings(account, settings: settings)
            // Refresh selected account
            if let updated = accountManager.accounts.first(where: { $0.id == account.id }) {
                selectedAccount = updated
            }
        }
    }

    private func checkForNewAccounts() async {
        isCheckingForAccounts = true
        checkResultMessage = nil
        defer { isCheckingForAccounts = false }

        do {
            let newAccounts = try await accountManager.checkForNewAccounts()
            if newAccounts.isEmpty {
                checkResultMessage = "No new accounts found"
            } else if newAccounts.count == 1 {
                checkResultMessage = "Found 1 new account"
            } else {
                checkResultMessage = "Found \(newAccounts.count) new accounts"
            }
        } catch {
            checkResultMessage = "Error: \(error.localizedDescription)"
        }

        // Clear message after 5 seconds
        Task {
            try? await Task.sleep(for: .seconds(5))
            checkResultMessage = nil
        }
    }
}
