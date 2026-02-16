import Foundation
import KeychainAccess
import CryptoKit

/// Secure storage for license and trial data using Keychain.
/// Uses HMAC signatures to detect tampering with trial dates.
actor LicenseStorage {
    static let shared = LicenseStorage()

    private let keychain: Keychain

    /// HMAC key for trial signature (compiled into binary)
    /// This prevents casual tampering - determined users can still bypass
    private let hmacKey: SymmetricKey

    private init() {
        keychain = Keychain(service: Constants.licenseKeychainService)
            .accessibility(.afterFirstUnlockThisDeviceOnly)

        // Generate a stable HMAC key from app-specific data
        let keyData = "Tokemon-Trial-Signature-Key-v1".data(using: .utf8)!
        hmacKey = SymmetricKey(data: SHA256.hash(data: keyData))
    }

    // MARK: - Trial Storage

    struct TrialData: Codable, Sendable {
        let startDate: Date
        let endDate: Date
        let signature: Data
    }

    /// Start a new trial period
    func startTrial() throws {
        // Check if trial already exists
        if try getTrialData() != nil {
            return // Trial already started, don't reset
        }

        let start = Date()
        let end = start.addingTimeInterval(Double(Constants.trialDurationDays) * 24 * 60 * 60)
        let signature = computeTrialSignature(start: start, end: end)

        let trial = TrialData(startDate: start, endDate: end, signature: signature)
        let encoded = try JSONEncoder().encode(trial)
        try keychain.set(encoded, key: "trial")
    }

    /// Get trial state if valid
    func getTrialState() throws -> (daysRemaining: Int, startDate: Date, endDate: Date)? {
        guard let trial = try getTrialData() else { return nil }

        // Verify HMAC signature
        let expectedSig = computeTrialSignature(start: trial.startDate, end: trial.endDate)
        guard expectedSig == trial.signature else {
            // Tampered - treat as expired
            return (0, trial.startDate, trial.endDate)
        }

        let remaining = Calendar.current.dateComponents([.day], from: Date(), to: trial.endDate).day ?? 0
        return (max(0, remaining), trial.startDate, trial.endDate)
    }

    private func getTrialData() throws -> TrialData? {
        guard let data = try keychain.getData("trial") else { return nil }
        return try JSONDecoder().decode(TrialData.self, from: data)
    }

    private func computeTrialSignature(start: Date, end: Date) -> Data {
        let message = "\(start.timeIntervalSince1970)|\(end.timeIntervalSince1970)".data(using: .utf8)!
        let signature = HMAC<SHA256>.authenticationCode(for: message, using: hmacKey)
        return Data(signature)
    }

    // MARK: - License Storage

    /// Store activated license
    func storeLicense(key: String, instanceId: String, expiresAt: Date?) throws {
        let data = CachedLicenseData(
            state: .licensed(licenseKey: key, instanceId: instanceId, expiresAt: expiresAt),
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

    /// Clear trial data (for testing only)
    func clearTrial() throws {
        try keychain.remove("trial")
    }
}
