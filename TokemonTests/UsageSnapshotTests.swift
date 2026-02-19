import XCTest
@testable import tokemon

/// Unit tests for UsageSnapshot model
/// NOTE: These are placeholder tests that compile. Full rewrite in Task 2.
final class UsageSnapshotTests: XCTestCase {

    // MARK: - Static Factory Tests

    func testEmpty_HasZeroValues() {
        let snapshot = UsageSnapshot.empty

        XCTAssertEqual(snapshot.primaryPercentage, 0.0)
        XCTAssertNil(snapshot.resetsAt)
        XCTAssertEqual(snapshot.source, .none)
    }

    // MARK: - hasPercentage Tests

    func testHasPercentage_WithZero_ReturnsTrue() {
        // hasPercentage returns true for >= 0
        XCTAssertTrue(UsageSnapshot.empty.hasPercentage)
    }

    func testHasPercentage_WithPositiveValue_ReturnsTrue() {
        let snapshot = UsageSnapshot(
            primaryPercentage: 50.0,
            fiveHourUtilization: 50.0,
            sevenDayUtilization: nil,
            sevenDayOpusUtilization: nil,
            sevenDaySonnetUtilization: nil,
            resetsAt: nil,
            sevenDayResetsAt: nil,
            sevenDaySonnetResetsAt: nil,
            source: .oauth,
            inputTokens: 1000,
            outputTokens: 500,
            cacheCreationTokens: nil,
            cacheReadTokens: nil,
            model: nil,
            extraUsageEnabled: false,
            extraUsageMonthlyLimitCents: nil,
            extraUsageSpentCents: nil,
            extraUsageUtilization: nil
        )

        XCTAssertTrue(snapshot.hasPercentage)
    }

    // MARK: - Computed Properties Tests

    func testTotalTokens_SumsAllTokenTypes() {
        let snapshot = UsageSnapshot(
            primaryPercentage: 50.0,
            fiveHourUtilization: 50.0,
            sevenDayUtilization: nil,
            sevenDayOpusUtilization: nil,
            sevenDaySonnetUtilization: nil,
            resetsAt: nil,
            sevenDayResetsAt: nil,
            sevenDaySonnetResetsAt: nil,
            source: .oauth,
            inputTokens: 1000,
            outputTokens: 500,
            cacheCreationTokens: 100,
            cacheReadTokens: 200,
            model: nil,
            extraUsageEnabled: false,
            extraUsageMonthlyLimitCents: nil,
            extraUsageSpentCents: nil,
            extraUsageUtilization: nil
        )

        XCTAssertEqual(snapshot.totalTokens, 1800)
    }

    func testTotalTokens_WithNilCache_SumsAvailable() {
        let snapshot = UsageSnapshot(
            primaryPercentage: 50.0,
            fiveHourUtilization: 50.0,
            sevenDayUtilization: nil,
            sevenDayOpusUtilization: nil,
            sevenDaySonnetUtilization: nil,
            resetsAt: nil,
            sevenDayResetsAt: nil,
            sevenDaySonnetResetsAt: nil,
            source: .oauth,
            inputTokens: 1000,
            outputTokens: 500,
            cacheCreationTokens: nil,
            cacheReadTokens: nil,
            model: nil,
            extraUsageEnabled: false,
            extraUsageMonthlyLimitCents: nil,
            extraUsageSpentCents: nil,
            extraUsageUtilization: nil
        )

        XCTAssertEqual(snapshot.totalTokens, 1500)
    }
}
