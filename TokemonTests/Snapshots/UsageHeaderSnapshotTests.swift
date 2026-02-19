import SnapshotTesting
import SwiftUI
import AppKit
import XCTest
@testable import tokemon

/// Snapshot tests for UsageHeaderView across multiple usage states and themes.
///
/// UsageHeaderView shows the big percentage number, subtitle text, and
/// optional critical warning banner. It requires:
/// - `usage: UsageSnapshot` (parameter)
/// - `alertLevel: AlertManager.AlertLevel` (parameter)
/// - `@Environment(ThemeManager.self)` (injected)
@MainActor
final class UsageHeaderSnapshotTests: SnapshotTestCase {

    // MARK: - Helper

    private func makeHeader(
        usage: UsageSnapshot,
        alertLevel: AlertManager.AlertLevel = .normal,
        theme: AppTheme = .native,
        width: CGFloat = 320,
        height: CGFloat = 140
    ) -> NSViewController {
        let themeManager = ThemeManager()
        themeManager.selectedTheme = theme

        let view = UsageHeaderView(usage: usage, alertLevel: alertLevel)
            .environment(themeManager)

        return view.snapshotController(width: width, height: height)
    }

    // MARK: - Usage State Tests

    func testHeader_Empty() {
        let vc = makeHeader(usage: .empty)
        assertSnapshot(of: vc, as: .image(precision: snapshotPrecision))
    }

    func testHeader_Low_25Percent() {
        let vc = makeHeader(usage: .mockOAuth(percentage: 25))
        assertSnapshot(of: vc, as: .image(precision: snapshotPrecision))
    }

    func testHeader_Medium_60Percent() {
        let vc = makeHeader(usage: .mockOAuth(percentage: 60))
        assertSnapshot(of: vc, as: .image(precision: snapshotPrecision))
    }

    func testHeader_High_80Percent() {
        let vc = makeHeader(usage: .mockOAuth(percentage: 80), alertLevel: .warning)
        assertSnapshot(of: vc, as: .image(precision: snapshotPrecision))
    }

    func testHeader_Critical_95Percent() {
        // Critical shows warning banner, needs extra height
        let vc = makeHeader(
            usage: .mockOAuth(percentage: 95),
            alertLevel: .critical,
            height: 180
        )
        assertSnapshot(of: vc, as: .image(precision: snapshotPrecision))
    }

    func testHeader_JSONL_TokenCount() {
        let vc = makeHeader(usage: .mockJSONL())
        assertSnapshot(of: vc, as: .image(precision: snapshotPrecision))
    }

    // MARK: - Theme Tests

    func testHeader_AllThemes_Medium() {
        for theme in AppTheme.allCases {
            let vc = makeHeader(
                usage: .mockOAuth(percentage: 60),
                theme: theme
            )
            assertSnapshot(
                of: vc,
                as: .image(precision: snapshotPrecision),
                named: "theme-\(theme.rawValue.replacingOccurrences(of: " ", with: "_"))"
            )
        }
    }
}
