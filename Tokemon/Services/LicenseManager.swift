import Foundation
import AppKit
@preconcurrency import LemonSqueezyLicense

/// Licensing error types
enum LicenseError: Error, LocalizedError {
    case activationFailed(String)
    case validationFailed(String)
    case wrongProduct
    case networkError(String)
    case deactivationFailed(String)

    var errorDescription: String? {
        switch self {
        case .activationFailed(let msg): return "Activation failed: \(msg)"
        case .validationFailed(let msg): return "Validation failed: \(msg)"
        case .wrongProduct: return "License key is for a different product"
        case .networkError(let msg): return "Network error: \(msg)"
        case .deactivationFailed(let msg): return "Deactivation failed: \(msg)"
        }
    }
}

/// Central license state manager following UsageMonitor pattern.
/// Handles activation and validation - simple Free/Pro model.
@Observable
@MainActor
final class LicenseManager {

    // MARK: - Published State

    /// Current license state
    var state: LicenseState = .free

    /// Whether validation is in progress
    var isValidating: Bool = false

    /// Timestamp of last successful validation
    var lastValidated: Date?

    /// Current error, if any
    var error: LicenseError?

    // MARK: - Callbacks

    /// Callback when state changes (for StatusItemManager)
    @ObservationIgnored
    var onStateChanged: ((LicenseState) -> Void)?

    // MARK: - Private

    @ObservationIgnored
    private let storage = LicenseStorage.shared

    @ObservationIgnored
    private nonisolated let license = LemonSqueezyLicense()

    // MARK: - Initialization

    init() {
        // Load cached state synchronously for immediate UI
        Task { @MainActor in
            await loadCachedState()
            // Validate in background (non-blocking)
            Task {
                await validateOnLaunch()
            }
        }
    }

    // MARK: - Public API

    /// Activate a license key
    func activateLicense(key: String) async throws {
        error = nil
        isValidating = true
        defer { isValidating = false }

        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        let instanceName = Host.current().localizedName ?? "Mac"

        do {
            let response = try await license.activate(key: trimmedKey, instanceName: instanceName)

            // Verify product ownership (critical security check)
            guard let meta = response.meta,
                  meta.storeId == Constants.lemonSqueezyStoreId,
                  meta.productId == Constants.lemonSqueezyProductId else {
                throw LicenseError.wrongProduct
            }

            guard response.activated, let instance = response.instance else {
                throw LicenseError.activationFailed("License key could not be activated")
            }

            // Store license securely
            let expiresAt = response.licenseKey?.expiresAt
            try await storage.storeLicense(
                key: trimmedKey,
                instanceId: instance.id,
                expiresAt: expiresAt
            )

            // Update state
            state = .pro(licenseKey: trimmedKey, instanceId: instance.id, expiresAt: expiresAt)
            lastValidated = Date()
            onStateChanged?(state)

        } catch let licenseError as LicenseError {
            error = licenseError
            throw licenseError
        } catch let lsError as LemonSqueezyLicenseError {
            let licenseError: LicenseError
            switch lsError {
            case .badServerResponse:
                licenseError = .activationFailed("Invalid server response")
            case .serverError(let statusCode, let errorMsg):
                licenseError = .activationFailed(errorMsg ?? "Server error (\(statusCode))")
            }
            self.error = licenseError
            throw licenseError
        } catch {
            let licenseError = LicenseError.networkError(error.localizedDescription)
            self.error = licenseError
            throw licenseError
        }
    }

    /// Validate current license
    func validateLicense() async throws -> Bool {
        guard let cachedData = try await storage.getLicenseData(),
              let key = cachedData.licenseKey,
              let instanceId = cachedData.instanceId else {
            return false
        }

        isValidating = true
        defer { isValidating = false }

        do {
            let response = try await license.validate(key: key, instanceId: instanceId)

            guard response.valid else {
                // License is invalid
                state = .free
                try await storage.clearLicense()
                onStateChanged?(state)
                return false
            }

            // Update cached validation timestamp
            try await storage.updateValidationTimestamp()
            lastValidated = Date()

            // Update state with fresh expiry info
            state = .pro(
                licenseKey: key,
                instanceId: instanceId,
                expiresAt: response.licenseKey?.expiresAt
            )
            onStateChanged?(state)
            return true

        } catch {
            // Network error - use offline fallback
            return handleOfflineValidation(cachedData: cachedData)
        }
    }

    /// Deactivate current license
    func deactivateLicense() async throws {
        guard let cachedData = try await storage.getLicenseData(),
              let key = cachedData.licenseKey,
              let instanceId = cachedData.instanceId else {
            return
        }

        do {
            _ = try await license.deactivate(key: key, instanceId: instanceId)
        } catch {
            // Log but continue - we'll clear local data anyway
            print("[LicenseManager] Deactivation API call failed: \(error)")
        }

        try await storage.clearLicense()
        state = .free
        lastValidated = nil
        onStateChanged?(state)
    }

    /// Open LemonSqueezy checkout page
    func openPurchasePage() {
        guard let url = URL(string: Constants.lemonSqueezyCheckoutURL) else { return }
        NSWorkspace.shared.open(url)
    }

    /// Open LemonSqueezy customer portal
    func openCustomerPortal() {
        guard let url = URL(string: Constants.lemonSqueezyPortalURL) else { return }
        NSWorkspace.shared.open(url)
    }

    // MARK: - Private Methods

    /// Load cached state on launch
    private func loadCachedState() async {
        // Developer mode bypass - treat as Pro user
        if Constants.developerModeProEnabled {
            state = .pro(licenseKey: "DEV-MODE", instanceId: "dev", expiresAt: nil)
            lastValidated = Date()
            return
        }

        // Check for existing license
        if let cached = try? await storage.getLicenseData() {
            state = cached.state
            lastValidated = cached.lastValidated
            return
        }

        // No license - free tier
        state = .free
    }

    /// Validate on app launch (non-blocking)
    private func validateOnLaunch() async {
        // Only validate if we have a license
        guard case .pro = state else { return }

        // Validate license in background
        _ = try? await validateLicense()
    }

    /// Handle offline validation using cached state
    private func handleOfflineValidation(cachedData: CachedLicenseData) -> Bool {
        let offlineWindow = TimeInterval(Constants.offlineValidationDays * 24 * 60 * 60)

        if Date().timeIntervalSince(cachedData.lastValidated) < offlineWindow {
            // Within offline window - trust cached state
            state = cachedData.state
            lastValidated = cachedData.lastValidated
            onStateChanged?(state)
            return true
        }

        // Offline window expired
        state = .free
        onStateChanged?(state)
        return false
    }
}
