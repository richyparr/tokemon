import Foundation
import Sparkle

/// Manages app updates via Sparkle framework.
/// Checks for updates on launch and provides UI-bindable state.
@Observable
@MainActor
final class UpdateManager: NSObject {

    /// Whether an update is available (for UI banner)
    var updateAvailable: Bool = false

    /// Version string of available update (e.g., "1.1.0")
    var availableVersion: String?

    /// Whether currently checking for updates
    var isChecking: Bool = false

    /// Error message if update check failed
    var error: String?

    /// Whether automatic update checks are enabled
    var autoCheckEnabled: Bool {
        get { UserDefaults.standard.object(forKey: Constants.autoCheckUpdatesKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: Constants.autoCheckUpdatesKey) }
    }

    /// Sparkle updater controller
    @ObservationIgnored
    private var updaterController: SPUStandardUpdaterController?

    override init() {
        super.init()
        setupSparkle()
    }

    private func setupSparkle() {
        // Create updater controller with this object as delegate
        updaterController = SPUStandardUpdaterController(
            startingUpdater: autoCheckEnabled,
            updaterDelegate: self,
            userDriverDelegate: nil
        )

        // Configure updater
        if let updater = updaterController?.updater {
            updater.automaticallyChecksForUpdates = autoCheckEnabled
            updater.automaticallyDownloadsUpdates = false // User must confirm
        }
    }

    /// Timeout task for update check
    @ObservationIgnored
    private var checkTimeoutTask: Task<Void, Never>?

    /// Manually check for updates (from Settings or menu)
    func checkForUpdates() {
        guard let controller = updaterController else { return }
        isChecking = true
        error = nil

        // Cancel any existing timeout
        checkTimeoutTask?.cancel()

        // Start timeout timer (15 seconds)
        checkTimeoutTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(15))
            if !Task.isCancelled && self.isChecking {
                self.isChecking = false
                self.error = "Update check timed out. Appcast may not be available."
            }
        }

        controller.checkForUpdates(nil)
    }

    /// Cancel timeout when check completes
    private func cancelTimeout() {
        checkTimeoutTask?.cancel()
        checkTimeoutTask = nil
    }

    /// Open download page for available update
    func downloadUpdate() {
        guard let controller = updaterController else { return }
        controller.checkForUpdates(nil) // This will show the update UI
    }

    /// Update auto-check preference and reconfigure Sparkle
    func setAutoCheck(_ enabled: Bool) {
        autoCheckEnabled = enabled
        updaterController?.updater.automaticallyChecksForUpdates = enabled
    }
}

// MARK: - SPUUpdaterDelegate

extension UpdateManager: SPUUpdaterDelegate {

    nonisolated func feedURLString(for updater: SPUUpdater) -> String? {
        Constants.sparkleAppcastURL
    }

    nonisolated func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        // Extract version string before crossing actor boundary to avoid data race
        let version = item.displayVersionString
        Task { @MainActor in
            self.cancelTimeout()
            self.updateAvailable = true
            self.availableVersion = version
            self.isChecking = false
        }
    }

    nonisolated func updaterDidNotFindUpdate(_ updater: SPUUpdater, error: any Error) {
        Task { @MainActor in
            self.cancelTimeout()
            self.updateAvailable = false
            self.availableVersion = nil
            self.isChecking = false
            // Only set error if it's not "no update available"
            if (error as NSError).code != SUError.noUpdateError.rawValue {
                self.error = error.localizedDescription
            }
        }
    }

    nonisolated func updater(_ updater: SPUUpdater, didAbortWithError error: any Error) {
        Task { @MainActor in
            self.cancelTimeout()
            self.isChecking = false
            self.error = error.localizedDescription
        }
    }
}
