import SnapshotTesting
import SwiftUI
import AppKit
import XCTest
@testable import tokemon

/// Snapshot tests for FloatingWindowView at different usage levels.
///
/// FloatingWindowView is a compact view showing usage percentage with status text.
/// It requires three environment objects:
/// - `@Environment(UsageMonitor.self)` (provides currentUsage)
/// - `@Environment(AlertManager.self)` (provides currentAlertLevel)
/// - `@Environment(ThemeManager.self)` (provides theme colors)
@MainActor
final class FloatingWindowSnapshotTests: SnapshotTestCase {

    // MARK: - Helper

    private func makeFloatingWindow(
        usage: UsageSnapshot = .empty,
        alertLevel: AlertManager.AlertLevel = .normal,
        theme: AppTheme = .native,
        width: CGFloat = 140,
        height: CGFloat = 100
    ) -> NSViewController {
        let monitor = UsageMonitor()
        monitor.currentUsage = usage

        let alertManager = AlertManager()
        alertManager.currentAlertLevel = alertLevel

        let themeManager = ThemeManager()
        themeManager.selectedTheme = theme

        let view = FloatingWindowView(rows: [.fiveHour])
            .environment(monitor)
            .environment(alertManager)
            .environment(themeManager)

        return view.snapshotController(width: width, height: height)
    }

    // MARK: - Usage State Tests

    func testFloating_Empty() {
        let vc = makeFloatingWindow(usage: .empty)
        assertSnapshot(of: vc, as: .image(precision: snapshotPrecision))
    }

    func testFloating_Low_25Percent() {
        let vc = makeFloatingWindow(usage: .mockOAuth(percentage: 25))
        assertSnapshot(of: vc, as: .image(precision: snapshotPrecision))
    }

    func testFloating_Critical_95Percent() {
        let vc = makeFloatingWindow(
            usage: .mockOAuth(percentage: 95),
            alertLevel: .critical
        )
        assertSnapshot(of: vc, as: .image(precision: snapshotPrecision))
    }

    func testFloating_JSONL() {
        let vc = makeFloatingWindow(usage: .mockJSONL())
        assertSnapshot(of: vc, as: .image(precision: snapshotPrecision))
    }
}
