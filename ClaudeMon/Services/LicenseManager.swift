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
/// Handles activation, validation, trial management, and grace periods.
@Observable
@MainActor
final class LicenseManager {

    // MARK: - Published State

    /// Current license state
    var state: LicenseState = .unlicensed

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
            state = .licensed(licenseKey: trimmedKey, instanceId: instance.id, expiresAt: expiresAt)
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
                // Check if subscription expired (needs grace period)
                if response.licenseKey?.status == .expired {
                    enterGracePeriod(key: key)
                    return true
                }
                // License is invalid
                state = .unlicensed
                try await storage.clearLicense()
                onStateChanged?(state)
                return false
            }

            // Update cached validation timestamp
            try await storage.updateValidationTimestamp()
            lastValidated = Date()

            // Update state with fresh expiry info
            state = .licensed(
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
        state = .unlicensed
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
        // Developer mode bypass - treat as licensed Pro user
        if Constants.developerModeProEnabled {
            state = .licensed(licenseKey: "DEV-MODE", instanceId: "dev", expiresAt: nil)
            lastValidated = Date()
            return
        }

        // First check for existing license
        if let cached = try? await storage.getLicenseData() {
            state = cached.state
            lastValidated = cached.lastValidated
            return
        }

        // Then check for trial
        if let trial = try? await storage.getTrialState() {
            if trial.daysRemaining > 0 {
                state = .onTrial(
                    daysRemaining: trial.daysRemaining,
                    startDate: trial.startDate,
                    endDate: trial.endDate
                )
            } else {
                state = .trialExpired
            }
            return
        }

        // No license or trial - start trial
        do {
            try await storage.startTrial()
            if let trial = try await storage.getTrialState() {
                state = .onTrial(
                    daysRemaining: trial.daysRemaining,
                    startDate: trial.startDate,
                    endDate: trial.endDate
                )
            }
        } catch {
            print("[LicenseManager] Failed to start trial: \(error)")
            state = .unlicensed
        }
    }

    /// Validate on app launch (non-blocking)
    private func validateOnLaunch() async {
        // Only validate if we have a license (not trial)
        guard case .licensed = state else {
            // Update trial days remaining
            if let trial = try? await storage.getTrialState() {
                if trial.daysRemaining > 0 {
                    state = .onTrial(
                        daysRemaining: trial.daysRemaining,
                        startDate: trial.startDate,
                        endDate: trial.endDate
                    )
                } else {
                    state = .trialExpired
                }
                onStateChanged?(state)
            }
            return
        }

        // Validate license in background
        _ = try? await validateLicense()
    }

    /// Enter grace period when subscription lapses
    private func enterGracePeriod(key: String) {
        let daysRemaining = Constants.gracePeriodDays
        state = .gracePeriod(daysRemaining: daysRemaining, licenseKey: key)
        onStateChanged?(state)
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
        state = .unlicensed
        onStateChanged?(state)
        return false
    }
}
