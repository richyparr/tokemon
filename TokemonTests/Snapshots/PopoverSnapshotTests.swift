import SnapshotTesting
import SwiftUI
import AppKit
import XCTest
@testable import tokemon

/// Snapshot tests for PopoverContentView, the main composite view displayed when
/// clicking the menu bar icon. Tests cover key state combinations: OAuth, JSONL,
/// critical alerts, chart, extra usage, themes, and multi-profile.
///
/// PopoverContentView requires 5 environment objects:
/// - UsageMonitor (provides currentUsage, showExtraUsage, usageHistory, isRefreshing, etc.)
/// - AlertManager (provides currentAlertLevel)
/// - ThemeManager (provides selectedTheme and ThemeColors)
/// - ProfileManager (provides profiles list for multi-profile display)
/// - UpdateManager (provides updateAvailable for UpdateBannerView)
@MainActor
final class PopoverSnapshotTests: SnapshotTestCase {

    // MARK: - Test Helper

    /// Constructs a PopoverContentView with all required environment objects injected.
    ///
    /// - Parameters:
    ///   - usage: The usage snapshot to display. Defaults to 50% OAuth.
    ///   - alertLevel: The alert level for visual warnings. Defaults to `.normal`.
    ///   - theme: The app theme. Defaults to `.native`.
    ///   - showChart: Whether to show the usage trend chart. Defaults to `false`.
    ///   - showExtraUsage: Whether to show extra usage billing info. Defaults to `false`.
    ///   - multiProfileCount: Number of profiles to create. Defaults to 1 (no profile switcher).
    /// - Returns: A configured view ready for snapshotting.
    private func makePopoverView(
        usage: UsageSnapshot = .mockOAuth(percentage: 50, resetsAt: nil),
        alertLevel: AlertManager.AlertLevel = .normal,
        theme: AppTheme = .native,
        showChart: Bool = false,
        showExtraUsage: Bool = false,
        multiProfileCount: Int = 1
    ) -> some View {
        let monitor = UsageMonitor()
        monitor.stopPolling()  // Prevent network/timer side effects
        monitor.currentUsage = usage
        monitor.showExtraUsage = showExtraUsage

        let alertManager = AlertManager()
        alertManager.currentAlertLevel = alertLevel

        let themeManager = ThemeManager()
        themeManager.selectedTheme = theme

        let profileManager = ProfileManager()
        // Add extra profiles if multi-profile testing is requested
        if multiProfileCount > 1 {
            for i in 2...multiProfileCount {
                let profile = profileManager.createProfile(name: "Profile \(i)")
                // Give non-active profiles some mock usage for display
                profileManager.updateProfileUsage(
                    profileId: profile.id,
                    usage: .mockOAuth(percentage: Double(i * 20), resetsAt: nil)
                )
            }
        }

        let updateManager = UpdateManager()

        // Configure chart display via UserDefaults (PopoverContentView reads @AppStorage)
        UserDefaults.standard.set(showChart, forKey: "showUsageTrend")

        return PopoverContentView()
            .environment(monitor)
            .environment(alertManager)
            .environment(themeManager)
            .environment(profileManager)
            .environment(updateManager)
    }

    // MARK: - Basic State Tests

    func testPopover_OAuthBasic_50Percent() {
        let view = makePopoverView(
            usage: .mockOAuth(percentage: 50, resetsAt: nil)
        )
        let vc = view.snapshotController(width: 320, height: 300)
        assertSnapshot(of: vc, as: .image(precision: snapshotPrecision))
    }

    func testPopover_Empty_NoData() {
        let view = makePopoverView(
            usage: .empty
        )
        let vc = view.snapshotController(width: 320, height: 300)
        assertSnapshot(of: vc, as: .image(precision: snapshotPrecision))
    }

    func testPopover_Critical_95Percent() {
        let view = makePopoverView(
            usage: .mockCritical(percentage: 95, resetsAt: nil),
            alertLevel: .critical
        )
        let vc = view.snapshotController(width: 320, height: 340)
        assertSnapshot(of: vc, as: .image(precision: snapshotPrecision))
    }

    func testPopover_JSONL_TokenView() {
        let view = makePopoverView(
            usage: .mockJSONL()
        )
        let vc = view.snapshotController(width: 320, height: 300)
        assertSnapshot(of: vc, as: .image(precision: snapshotPrecision))
    }

    // MARK: - Extended State Tests

    func testPopover_WithChart() {
        let view = makePopoverView(
            usage: .mockOAuth(percentage: 50, resetsAt: nil),
            showChart: true
        )
        // Chart adds ~230px to height (chart section + burn rate)
        let vc = view.snapshotController(width: 320, height: 530)
        assertSnapshot(of: vc, as: .image(precision: relaxedPrecision))
    }

    func testPopover_WithExtraUsage() {
        // mockWithExtraUsage calls mockOAuth which defaults resetsAt to now+3600.
        // Use explicit resetsAt: nil to avoid time-dependent subtitle text.
        let view = makePopoverView(
            usage: .mockOAuth(
                percentage: 60,
                resetsAt: nil,
                extraUsageEnabled: true,
                extraUsageSpentCents: 1250,
                extraUsageLimitCents: 5000,
                extraUsageUtilization: 25.0
            ),
            showExtraUsage: true
        )
        // Extra usage adds ~75px for billing info
        let vc = view.snapshotController(width: 320, height: 375)
        assertSnapshot(of: vc, as: .image(precision: snapshotPrecision))
    }

    // MARK: - Theme Tests

    func testPopover_AllThemes() {
        for theme in AppTheme.allCases {
            let view = makePopoverView(
                usage: .mockOAuth(percentage: 50, resetsAt: nil),
                theme: theme
            )
            let vc = view.snapshotController(width: 320, height: 300)
            assertSnapshot(
                of: vc,
                as: .image(precision: snapshotPrecision),
                named: theme.rawValue.replacingOccurrences(of: " ", with: "_")
            )
        }
    }

    // MARK: - Multi-Profile Tests

    func testPopover_MultiProfile_TwoProfiles() {
        let view = makePopoverView(
            usage: .mockOAuth(percentage: 50, resetsAt: nil),
            multiProfileCount: 2
        )
        // Multi-profile adds profile switcher (~28px) + "All Profiles" section (~80px)
        let vc = view.snapshotController(width: 320, height: 420)
        assertSnapshot(of: vc, as: .image(precision: snapshotPrecision))
    }
}
