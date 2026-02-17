import SwiftUI

/// Settings tab for managing Claude Code credential profiles.
/// Provides full CRUD operations: create, rename, delete, sync from keychain,
/// manual session key entry, and profile switching.
struct ProfilesSettings: View {
    @Environment(ProfileManager.self) private var profileManager

    @State private var selectedProfileId: UUID?
    @State private var showingAddProfile = false
    @State private var newProfileName = ""
    @State private var showingDeleteConfirmation = false
    @State private var profileToDelete: UUID?

    // Manual credential entry state
    @State private var manualSessionKey = ""
    @State private var manualOrgId = ""

    // Editing name state
    @State private var editingName = ""

    var body: some View {
        Form {
            // MARK: - Profile List Section
            Section {
                List(profileManager.profiles, selection: $selectedProfileId) { profile in
                    HStack {
                        if profile.id == profileManager.activeProfileId {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.system(size: 12))
                        } else {
                            Image(systemName: "circle")
                                .foregroundStyle(.secondary)
                                .font(.system(size: 12))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(profile.name)
                                    .font(.body)

                                if profile.id == profileManager.activeProfileId {
                                    Text("Active")
                                        .font(.caption2)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1)
                                        .background(.green.opacity(0.15))
                                        .foregroundStyle(.green)
                                        .clipShape(Capsule())
                                }

                                if profile.isDefault {
                                    Text("Default")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Text(credentialStatusText(for: profile))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        // Sync button
                        Button {
                            profileManager.syncCredentialsFromKeychain(for: profile.id)
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.borderless)
                        .help("Sync credentials from system keychain")

                        // Delete button (disabled if last profile)
                        Button {
                            profileToDelete = profile.id
                            showingDeleteConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                                .foregroundStyle(.red.opacity(0.7))
                        }
                        .buttonStyle(.borderless)
                        .disabled(profileManager.profiles.count <= 1)
                        .help(profileManager.profiles.count <= 1 ? "Cannot delete the last profile" : "Delete profile")
                    }
                    .padding(.vertical, 2)
                    .tag(profile.id)
                }
                .frame(minHeight: 80, maxHeight: 160)
                .listStyle(.bordered)

                // Add profile button
                if showingAddProfile {
                    HStack {
                        TextField("Profile name", text: $newProfileName)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                addProfile()
                            }

                        Button("Add") {
                            addProfile()
                        }
                        .disabled(newProfileName.trimmingCharacters(in: .whitespaces).isEmpty)

                        Button("Cancel") {
                            showingAddProfile = false
                            newProfileName = ""
                        }
                    }
                } else {
                    Button {
                        showingAddProfile = true
                        newProfileName = ""
                    } label: {
                        Label("Add Profile", systemImage: "plus")
                    }
                }
            } header: {
                Text("Profiles")
            }

            // MARK: - Selected Profile Detail Section
            if let selectedId = selectedProfileId,
               let profile = profileManager.profiles.first(where: { $0.id == selectedId }) {

                Section {
                    // Profile name (editable)
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Profile name", text: $editingName)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 200)
                            .onSubmit {
                                if !editingName.trimmingCharacters(in: .whitespaces).isEmpty {
                                    profileManager.updateProfileName(id: selectedId, name: editingName)
                                }
                            }
                    }

                    // Status
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(credentialStatusText(for: profile))
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Profile Details")
                }

                // MARK: - Credentials Section
                Section {
                    // Sync from keychain
                    Button {
                        profileManager.syncCredentialsFromKeychain(for: selectedId)
                    } label: {
                        Label("Sync from Keychain", systemImage: "arrow.triangle.2.circlepath")
                    }

                    Text("Copy current Claude Code credentials from the system keychain into this profile")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Divider()

                    Text("Or enter credentials manually:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Manual session key entry
                    SecureField("Session Key", text: $manualSessionKey)
                        .textFieldStyle(.roundedBorder)

                    TextField("Organization ID (optional)", text: $manualOrgId)
                        .textFieldStyle(.roundedBorder)

                    Button("Save Manual Credentials") {
                        let orgId = manualOrgId.trimmingCharacters(in: .whitespaces).isEmpty ? nil : manualOrgId.trimmingCharacters(in: .whitespaces)
                        profileManager.enterManualSessionKey(
                            for: selectedId,
                            sessionKey: manualSessionKey,
                            orgId: orgId
                        )
                        manualSessionKey = ""
                        manualOrgId = ""
                    }
                    .disabled(manualSessionKey.trimmingCharacters(in: .whitespaces).isEmpty)
                } header: {
                    Text("Credentials")
                }

                // MARK: - Actions Section
                Section {
                    Button {
                        profileManager.setActiveProfile(id: selectedId)
                    } label: {
                        Label("Switch to This Profile", systemImage: "arrow.right.circle")
                    }
                    .disabled(selectedId == profileManager.activeProfileId)

                    if selectedId == profileManager.activeProfileId {
                        Text("This profile is already active")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if !profile.hasCredentials {
                        Text("Sync or enter credentials before switching")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                } header: {
                    Text("Actions")
                }
            } else {
                Section {
                    Text("Select a profile from the list above to view details")
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Profile Details")
                }
            }
        }
        .formStyle(.grouped)
        .alert("Delete Profile", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                profileToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let id = profileToDelete {
                    profileManager.deleteProfile(id: id)
                    if selectedProfileId == id {
                        selectedProfileId = profileManager.profiles.first?.id
                    }
                }
                profileToDelete = nil
            }
        } message: {
            if let id = profileToDelete,
               let profile = profileManager.profiles.first(where: { $0.id == id }) {
                Text("Are you sure you want to delete the profile \"\(profile.name)\"? This cannot be undone.")
            } else {
                Text("Are you sure you want to delete this profile?")
            }
        }
        .onAppear {
            // Auto-select the active profile
            if selectedProfileId == nil {
                selectedProfileId = profileManager.activeProfileId
            }
            // Initialize editing name
            if let selectedId = selectedProfileId,
               let profile = profileManager.profiles.first(where: { $0.id == selectedId }) {
                editingName = profile.name
            }
        }
        .onChange(of: selectedProfileId) { _, newId in
            // Update editing fields when selection changes
            if let newId,
               let profile = profileManager.profiles.first(where: { $0.id == newId }) {
                editingName = profile.name
                manualSessionKey = ""
                manualOrgId = ""
            }
        }
    }

    // MARK: - Helpers

    /// Format credential status text for a profile
    private func credentialStatusText(for profile: Profile) -> String {
        if let lastSynced = profile.lastSynced {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return "Synced \(formatter.localizedString(for: lastSynced, relativeTo: Date()))"
        } else if profile.claudeSessionKey != nil {
            return "Manual key"
        } else {
            return "No credentials"
        }
    }

    /// Create a new profile from the inline text field
    private func addProfile() {
        let name = newProfileName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let profile = profileManager.createProfile(name: name)
        selectedProfileId = profile.id
        newProfileName = ""
        showingAddProfile = false
    }
}
