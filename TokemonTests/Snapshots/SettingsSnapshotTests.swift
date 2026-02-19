import SnapshotTesting
import SwiftUI
import AppKit
import XCTest
@testable import tokemon

/// Snapshot tests for individual settings tab views.
///
/// Tests the tabs most likely to have layout issues at the standard settings window size.
/// Complex tabs that depend on API state or external services (AdminAPISettings,
/// TeamDashboardView, AnalyticsDashboardView, BudgetDashboardView, WebhookSettings)
/// are skipped as they require complex external state.
///
/// Each tab view is tested independently with its required environment objects.
@MainActor
final class SettingsSnapshotTests: SnapshotTestCase {

    /// Standard settings tab snapshot dimensions.
    /// Matches the SettingsView frame: minWidth: 560, minHeight: 400.
    private let settingsWidth: CGFloat = 560
    private let settingsHeight: CGFloat = 400

    // MARK: - GeneralSettings (Updates tab)

    func testGeneralSettings_Default() {
        // GeneralSettings requires UpdateManager. UpdateManager init() sets up Sparkle,
        // but defaults are safe (updateAvailable=false, isChecking=false, error=nil).
        let updateManager = UpdateManager()

        let view = GeneralSettings()
            .environment(updateManager)

        let vc = view.snapshotController(width: settingsWidth, height: settingsHeight)
        assertSnapshot(of: vc, as: .image(precision: snapshotPrecision))
    }

    // MARK: - AppearanceSettings

    func testAppearanceSettings_Default() {
        let monitor = UsageMonitor()
        monitor.stopPolling()

        let themeManager = ThemeManager()

        let view = AppearanceSettings()
            .environment(monitor)
            .environment(themeManager)

        let vc = view.snapshotController(width: settingsWidth, height: settingsHeight)
        assertSnapshot(of: vc, as: .image(precision: snapshotPrecision))
    }

    // MARK: - AlertSettings

    func testAlertSettings_Default() {
        let alertManager = AlertManager()

        let view = AlertSettings()
            .environment(alertManager)

        let vc = view.snapshotController(width: settingsWidth, height: settingsHeight)
        assertSnapshot(of: vc, as: .image(precision: snapshotPrecision))
    }

    // MARK: - RefreshSettings

    func testRefreshSettings_Default() {
        let monitor = UsageMonitor()
        monitor.stopPolling()

        let view = RefreshSettings()
            .environment(monitor)

        let vc = view.snapshotController(width: settingsWidth, height: settingsHeight)
        assertSnapshot(of: vc, as: .image(precision: snapshotPrecision))
    }

    // MARK: - StatuslineSettings

    func testStatuslineSettings_Default() {
        // StatuslineSettings uses only @State (no environment dependencies).
        let view = StatuslineSettings()

        let vc = view.snapshotController(width: settingsWidth, height: settingsHeight)
        assertSnapshot(of: vc, as: .image(precision: snapshotPrecision))
    }
}
