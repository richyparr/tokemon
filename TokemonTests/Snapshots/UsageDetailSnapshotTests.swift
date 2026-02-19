import SnapshotTesting
import SwiftUI
import AppKit
import XCTest
@testable import tokemon

/// Snapshot tests for UsageDetailView across OAuth and JSONL data sources.
///
/// UsageDetailView shows usage breakdown rows. It takes plain parameters
/// (no environment objects needed):
/// - `usage: UsageSnapshot`
/// - `showExtraUsage: Bool`
@MainActor
final class UsageDetailSnapshotTests: SnapshotTestCase {

    // MARK: - Helper

    private func makeDetail(
        usage: UsageSnapshot,
        showExtraUsage: Bool = false,
        width: CGFloat = 320,
        height: CGFloat = 200
    ) -> NSViewController {
        let view = UsageDetailView(usage: usage, showExtraUsage: showExtraUsage)
        return view.snapshotController(width: width, height: height)
    }

    // MARK: - OAuth Tests

    func testDetail_OAuth_BasicUsage() {
        let vc = makeDetail(
            usage: .mockOAuth(percentage: 50, sevenDay: 30)
        )
        assertSnapshot(of: vc, as: .image(precision: snapshotPrecision))
    }

    func testDetail_OAuth_WithSonnet() {
        let vc = makeDetail(
            usage: .mockOAuth(percentage: 50, sevenDay: 30, sevenDaySonnet: 45)
        )
        assertSnapshot(of: vc, as: .image(precision: snapshotPrecision))
    }

    func testDetail_OAuth_WithOpus() {
        let vc = makeDetail(
            usage: .mockOAuth(percentage: 50, sevenDay: 30, sevenDayOpus: 15)
        )
        assertSnapshot(of: vc, as: .image(precision: snapshotPrecision))
    }

    func testDetail_OAuth_WithExtraUsage() {
        let vc = makeDetail(
            usage: .mockWithExtraUsage(),
            showExtraUsage: true,
            height: 300 // Extra usage rows need more space
        )
        assertSnapshot(of: vc, as: .image(precision: snapshotPrecision))
    }

    // MARK: - JSONL Tests

    func testDetail_JSONL_TokenBreakdown() {
        let vc = makeDetail(
            usage: .mockJSONL(inputTokens: 5000, outputTokens: 2000)
        )
        assertSnapshot(of: vc, as: .image(precision: snapshotPrecision))
    }

    func testDetail_JSONL_WithCache() {
        let vc = makeDetail(
            usage: .mockJSONL(
                inputTokens: 5000,
                outputTokens: 2000,
                cacheRead: 3000,
                cacheCreation: 1500
            )
        )
        assertSnapshot(of: vc, as: .image(precision: snapshotPrecision))
    }
}
