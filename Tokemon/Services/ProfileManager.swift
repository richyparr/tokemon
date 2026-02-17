import Foundation

/// Manages named profiles that store Claude Code credentials internally.
///
/// Implements the copy/switch architecture:
/// - **Copy (sync):** Reads credentials from the system keychain into a profile's internal storage
/// - **Switch:** Writes a profile's stored credentials TO the system keychain for Claude Code to use
///
/// This avoids the keychain conflicts that caused the v2.0 multi-account feature to be removed.
/// Profiles persist via UserDefaults. Keychain I/O uses `/usr/bin/security` CLI (not KeychainAccess)
/// to interact with Claude Code's keychain entry directly.
@Observable
@MainActor
final class ProfileManager {

    // MARK: - State

    /// All profiles stored in the app
    var profiles: [Profile] = []

    /// ID of the currently active profile
    var activeProfileId: UUID?

    /// Convenience accessor for the active profile
    var activeProfile: Profile? {
        profiles.first { $0.id == activeProfileId }
    }

    /// Callback fired when the active profile changes (wired by TokemonApp in Plan 02)
    @ObservationIgnored
    var onActiveProfileChanged: ((_ profile: Profile?) -> Void)?

    // MARK: - Initialization

    init() {
        loadProfiles()
        // If no profiles exist, create a default one and try to sync system credentials
        if profiles.isEmpty {
            let defaultProfile = Profile.create(name: "Default", isDefault: true)
            profiles.append(defaultProfile)
            activeProfileId = defaultProfile.id
            // Try to sync credentials from system keychain into the default profile
            syncCredentialsFromKeychain(for: defaultProfile.id)
            saveProfiles()
        }
    }

    // MARK: - CRUD Operations

    /// Create a new profile with the given name.
    /// - Parameter name: Display name for the profile (e.g., "Work", "Personal")
    /// - Returns: The newly created profile
    @discardableResult
    func createProfile(name: String) -> Profile {
        let profile = Profile.create(name: name, isDefault: false)
        profiles.append(profile)
        saveProfiles()
        print("[ProfileManager] Created profile '\(name)' (id: \(profile.id))")
        return profile
    }

    /// Delete a profile by ID.
    ///
    /// Rules:
    /// - Cannot delete the last remaining profile
    /// - If deleting the active profile, switches to another profile first
    /// - If deleting the default profile, marks another as default
    /// - Parameter id: The profile ID to delete
    func deleteProfile(id: UUID) {
        guard profiles.count > 1 else {
            print("[ProfileManager] Cannot delete the last profile")
            return
        }

        guard let index = profiles.firstIndex(where: { $0.id == id }) else {
            print("[ProfileManager] Profile \(id) not found for deletion")
            return
        }

        let wasDefault = profiles[index].isDefault
        let wasActive = activeProfileId == id

        // Remove the profile
        let deletedName = profiles[index].name
        profiles.remove(at: index)

        // If we deleted the default, mark the first remaining profile as default
        if wasDefault, !profiles.isEmpty {
            profiles[0].isDefault = true
            print("[ProfileManager] Marked '\(profiles[0].name)' as new default")
        }

        // If we deleted the active profile, switch to another
        if wasActive, let firstProfile = profiles.first {
            setActiveProfile(id: firstProfile.id)
        }

        saveProfiles()
        print("[ProfileManager] Deleted profile '\(deletedName)'")
    }

    /// Update the display name of a profile.
    /// - Parameters:
    ///   - id: The profile ID to update
    ///   - name: The new display name
    func updateProfileName(id: UUID, name: String) {
        guard let index = profiles.firstIndex(where: { $0.id == id }) else {
            print("[ProfileManager] Profile \(id) not found for rename")
            return
        }
        let oldName = profiles[index].name
        profiles[index].name = name
        saveProfiles()
        print("[ProfileManager] Renamed profile '\(oldName)' -> '\(name)'")
    }

    /// Set the active profile, writing its credentials to the system keychain.
    /// - Parameter id: The profile ID to activate
    func setActiveProfile(id: UUID) {
        guard profiles.contains(where: { $0.id == id }) else {
            print("[ProfileManager] Profile \(id) not found for activation")
            return
        }

        activeProfileId = id
        writeCredentialsToKeychain(for: id)
        saveProfiles()

        let profile = activeProfile
        print("[ProfileManager] Activated profile '\(profile?.name ?? "unknown")'")
        onActiveProfileChanged?(profile)
    }

    // MARK: - Keychain Sync Operations (Copy/Switch Pattern)

    /// Sync (copy) credentials FROM the system keychain INTO the specified profile.
    ///
    /// Reads the Claude Code credentials from the macOS keychain using `/usr/bin/security`
    /// and stores the raw JSON string in the profile's `cliCredentialsJSON` field.
    /// - Parameter profileId: The profile to sync credentials into
    func syncCredentialsFromKeychain(for profileId: UUID) {
        guard let index = profiles.firstIndex(where: { $0.id == profileId }) else {
            print("[ProfileManager] Profile \(profileId) not found for sync")
            return
        }

        let process = Process()
        let pipe = Pipe()
        let errorPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        process.arguments = [
            "find-generic-password",
            "-s", Constants.keychainService,
            "-a", NSUserName(),
            "-w"
        ]
        process.standardOutput = pipe
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            print("[ProfileManager] Failed to run security command for sync: \(error)")
            return
        }

        if process.terminationStatus != 0 {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorString = String(data: errorData, encoding: .utf8) ?? "unknown error"
            print("[ProfileManager] security find-generic-password failed (status \(process.terminationStatus)): \(errorString)")
            return
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let jsonString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !jsonString.isEmpty else {
            print("[ProfileManager] No credentials found in system keychain")
            return
        }

        profiles[index].cliCredentialsJSON = jsonString
        profiles[index].lastSynced = Date()
        saveProfiles()
        print("[ProfileManager] Synced credentials from system keychain into profile '\(profiles[index].name)'")
    }

    /// Store manually-entered session key and org ID into a profile.
    /// - Parameters:
    ///   - profileId: The profile to update
    ///   - sessionKey: The OAuth session key entered by the user
    ///   - orgId: Optional organization ID
    func enterManualSessionKey(for profileId: UUID, sessionKey: String, orgId: String?) {
        guard let index = profiles.firstIndex(where: { $0.id == profileId }) else {
            print("[ProfileManager] Profile \(profileId) not found for manual entry")
            return
        }

        profiles[index].claudeSessionKey = sessionKey
        profiles[index].organizationId = orgId
        saveProfiles()
        print("[ProfileManager] Stored manual session key for profile '\(profiles[index].name)'")
    }

    /// Write the specified profile's credentials TO the system keychain.
    ///
    /// This is the "switch" operation -- it makes Claude Code use this profile's credentials
    /// by writing them to the keychain location Claude Code reads from.
    /// Prefers `cliCredentialsJSON` (full blob) over constructing from manual session key.
    /// - Parameter profileId: The profile whose credentials to write
    func writeCredentialsToKeychain(for profileId: UUID) {
        guard let profile = profiles.first(where: { $0.id == profileId }) else {
            print("[ProfileManager] Profile \(profileId) not found for keychain write")
            return
        }

        // Determine the credentials JSON to write
        let credentialsJSON: String
        if let cliJSON = profile.cliCredentialsJSON {
            // Prefer the full CLI credentials JSON blob
            credentialsJSON = cliJSON
        } else if let sessionKey = profile.claudeSessionKey {
            // Construct a minimal ClaudeCredentials JSON from the manual session key
            credentialsJSON = constructCredentialsJSON(sessionKey: sessionKey, orgId: profile.organizationId)
        } else {
            print("[ProfileManager] Profile '\(profile.name)' has no credentials to write")
            return
        }

        // Step 1: Delete existing keychain entry (ignore errors if it doesn't exist)
        let deleteProcess = Process()
        let deleteErrorPipe = Pipe()
        deleteProcess.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        deleteProcess.arguments = [
            "delete-generic-password",
            "-s", Constants.keychainService,
            "-a", NSUserName()
        ]
        deleteProcess.standardOutput = Pipe()
        deleteProcess.standardError = deleteErrorPipe

        do {
            try deleteProcess.run()
            deleteProcess.waitUntilExit()
        } catch {
            print("[ProfileManager] Failed to run delete-generic-password: \(error)")
        }

        // Step 2: Add new keychain entry with -U flag (update if exists)
        let addProcess = Process()
        let addPipe = Pipe()
        let addErrorPipe = Pipe()
        addProcess.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        addProcess.arguments = [
            "add-generic-password",
            "-s", Constants.keychainService,
            "-a", NSUserName(),
            "-w", credentialsJSON,
            "-U"
        ]
        addProcess.standardOutput = addPipe
        addProcess.standardError = addErrorPipe

        do {
            try addProcess.run()
            addProcess.waitUntilExit()
        } catch {
            print("[ProfileManager] Failed to run add-generic-password: \(error)")
            return
        }

        if addProcess.terminationStatus != 0 {
            let errorData = addErrorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorString = String(data: errorData, encoding: .utf8) ?? "unknown error"
            print("[ProfileManager] add-generic-password failed (status \(addProcess.terminationStatus)): \(errorString)")
            return
        }

        print("[ProfileManager] Wrote credentials for profile '\(profile.name)' to system keychain")
    }

    // MARK: - Persistence (UserDefaults)

    /// Save profiles and active profile ID to UserDefaults.
    private func saveProfiles() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        do {
            let data = try encoder.encode(profiles)
            UserDefaults.standard.set(data, forKey: Constants.profilesStorageKey)
        } catch {
            print("[ProfileManager] Failed to encode profiles: \(error)")
        }

        if let activeId = activeProfileId {
            UserDefaults.standard.set(activeId.uuidString, forKey: Constants.activeProfileIdKey)
        } else {
            UserDefaults.standard.removeObject(forKey: Constants.activeProfileIdKey)
        }
    }

    /// Load profiles and active profile ID from UserDefaults.
    private func loadProfiles() {
        guard let data = UserDefaults.standard.data(forKey: Constants.profilesStorageKey) else {
            print("[ProfileManager] No saved profiles found")
            return
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            profiles = try decoder.decode([Profile].self, from: data)
        } catch {
            print("[ProfileManager] Failed to decode profiles: \(error)")
            profiles = []
        }

        if let activeIdString = UserDefaults.standard.string(forKey: Constants.activeProfileIdKey),
           let activeId = UUID(uuidString: activeIdString) {
            activeProfileId = activeId
        } else if let firstProfile = profiles.first {
            activeProfileId = firstProfile.id
        }

        print("[ProfileManager] Loaded \(profiles.count) profile(s), active: \(activeProfileId?.uuidString ?? "none")")
    }

    // MARK: - Private Helpers

    /// Construct a minimal Claude Code credentials JSON from a manual session key.
    ///
    /// Matches the `TokenManager.ClaudeCredentials` structure:
    /// `{ "claudeAiOauth": { "accessToken": "...", "refreshToken": "", "expiresAt": ..., "scopes": [...] } }`
    private func constructCredentialsJSON(sessionKey: String, orgId: String?) -> String {
        // Set expiry far in the future (manual keys don't have a real expiry)
        let farFutureMs = Int64(Date().addingTimeInterval(365 * 24 * 60 * 60).timeIntervalSince1970 * 1000)

        var inner: [String: Any] = [
            "accessToken": sessionKey,
            "refreshToken": "",
            "expiresAt": farFutureMs,
            "scopes": ["user:profile"]
        ]

        if let orgId = orgId {
            inner["organizationId"] = orgId
        }

        let outer: [String: Any] = ["claudeAiOauth": inner]

        guard let data = try? JSONSerialization.data(withJSONObject: outer, options: [.sortedKeys]),
              let jsonString = String(data: data, encoding: .utf8) else {
            print("[ProfileManager] Failed to construct credentials JSON")
            return "{}"
        }

        return jsonString
    }
}
