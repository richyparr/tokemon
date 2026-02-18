import XCTest
@testable import tokemon

/// Unit tests for UsageSnapshot model
final class UsageSnapshotTests: XCTestCase {

    // MARK: - Static Factory Tests

    func testEmpty_HasZeroValues() {
        let snapshot = UsageSnapshot.empty

        XCTAssertEqual(snapshot.primaryPercentage, 0.0)
        XCTAssertNil(snapshot.secondaryPercentage)
        XCTAssertNil(snapshot.resetTime)
        XCTAssertFalse(snapshot.hasPercentage)
    }

    // MARK: - hasPercentage Tests

    func testHasPercentage_WithZero_ReturnsFalse() {
        let snapshot = UsageSnapshot(
            primaryPercentage: 0.0,
            secondaryPercentage: nil,
            inputTokens: 0,
            outputTokens: 0,
            cacheReadTokens: nil,
            cacheCreationTokens: nil,
            resetTime: nil
        )

        XCTAssertFalse(snapshot.hasPercentage)
    }

    func testHasPercentage_WithPositiveValue_ReturnsTrue() {
        let snapshot = UsageSnapshot(
            primaryPercentage: 50.0,
            secondaryPercentage: nil,
            inputTokens: 1000,
            outputTokens: 500,
            cacheReadTokens: nil,
            cacheCreationTokens: nil,
            resetTime: nil
        )

        XCTAssertTrue(snapshot.hasPercentage)
    }

    // MARK: - Computed Properties Tests

    func testTotalTokens_SumsAllTokenTypes() {
        let snapshot = UsageSnapshot(
            primaryPercentage: 50.0,
            secondaryPercentage: nil,
            inputTokens: 1000,
            outputTokens: 500,
            cacheReadTokens: 200,
            cacheCreationTokens: 100,
            resetTime: nil
        )

        XCTAssertEqual(snapshot.totalTokens, 1800)
    }

    func testTotalTokens_WithNilCache_SumsAvailable() {
        let snapshot = UsageSnapshot(
            primaryPercentage: 50.0,
            secondaryPercentage: nil,
            inputTokens: 1000,
            outputTokens: 500,
            cacheReadTokens: nil,
            cacheCreationTokens: nil,
            resetTime: nil
        )

        XCTAssertEqual(snapshot.totalTokens, 1500)
    }

    // MARK: - Reset Time Tests

    func testResetTimeFormatted_WithResetTime_ReturnsString() {
        let calendar = Calendar.current
        let components = DateComponents(year: 2024, month: 3, day: 15, hour: 10, minute: 30)
        let resetTime = calendar.date(from: components)!

        let snapshot = UsageSnapshot(
            primaryPercentage: 50.0,
            secondaryPercentage: nil,
            inputTokens: 1000,
            outputTokens: 500,
            cacheReadTokens: nil,
            cacheCreationTokens: nil,
            resetTime: resetTime
        )

        XCTAssertNotNil(snapshot.resetTimeFormatted)
        XCTAssertFalse(snapshot.resetTimeFormatted!.isEmpty)
    }

    func testResetTimeFormatted_WithNilResetTime_ReturnsNil() {
        let snapshot = UsageSnapshot(
            primaryPercentage: 50.0,
            secondaryPercentage: nil,
            inputTokens: 1000,
            outputTokens: 500,
            cacheReadTokens: nil,
            cacheCreationTokens: nil,
            resetTime: nil
        )

        XCTAssertNil(snapshot.resetTimeFormatted)
    }
}
