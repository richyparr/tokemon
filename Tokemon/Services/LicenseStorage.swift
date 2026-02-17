import Foundation
import KeychainAccess

/// Secure storage for license data using Keychain.
actor LicenseStorage {
    static let shared = LicenseStorage()

    private let keychain: Keychain

    private init() {
        keychain = Keychain(service: Constants.licenseKeychainService)
            .accessibility(.afterFirstUnlockThisDeviceOnly)
    }

    // MARK: - License Storage

    /// Store activated license
    func storeLicense(key: String, instanceId: String, expiresAt: Date?) throws {
        let data = CachedLicenseData(
            state: .pro(licenseKey: key, instanceId: instanceId, expiresAt: expiresAt),
            lastValidated: Date(),
            licenseKey: key,
            instanceId: instanceId
        )
        let encoded = try JSONEncoder().encode(data)
        try keychain.set(encoded, key: "license")
    }

    /// Get stored license data
    func getLicenseData() throws -> CachedLicenseData? {
        guard let data = try keychain.getData("license") else { return nil }
        return try JSONDecoder().decode(CachedLicenseData.self, from: data)
    }

    /// Update last validated timestamp
    func updateValidationTimestamp() throws {
        guard let data = try getLicenseData() else { return }
        let updated = CachedLicenseData(
            state: data.state,
            lastValidated: Date(),
            licenseKey: data.licenseKey,
            instanceId: data.instanceId
        )
        let encoded = try JSONEncoder().encode(updated)
        try keychain.set(encoded, key: "license")
    }

    /// Clear all license data (for deactivation)
    func clearLicense() throws {
        try keychain.remove("license")
    }
}
