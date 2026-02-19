import XCTest
@testable import tokemon

/// Unit tests for UsageDataPoint model
final class UsageDataPointTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInit_WithAllValues() {
        let timestamp = Date()
        let point = UsageDataPoint(
            timestamp: timestamp,
            primaryPercentage: 75.5,
            sevenDayPercentage: 50.0,
            source: "oauth"
        )

        XCTAssertEqual(point.timestamp, timestamp)
        XCTAssertEqual(point.primaryPercentage, 75.5)
        XCTAssertEqual(point.sevenDayPercentage, 50.0)
        XCTAssertEqual(point.source, "oauth")
    }

    func testInit_WithNilSevenDayPercentage() {
        let point = UsageDataPoint(
            timestamp: Date(),
            primaryPercentage: 50.0,
            sevenDayPercentage: nil,
            source: "oauth"
        )

        XCTAssertNil(point.sevenDayPercentage)
    }

    func testInit_WithDefaultSource() {
        let point = UsageDataPoint(
            timestamp: Date(),
            primaryPercentage: 50.0
        )

        XCTAssertEqual(point.source, "oauth")
    }

    func testInit_FromUsageSnapshot() {
        let snapshot = UsageSnapshot(
            primaryPercentage: 75.0,
            fiveHourUtilization: 75.0,
            sevenDayUtilization: 30.0,
            sevenDayOpusUtilization: nil,
            sevenDaySonnetUtilization: nil,
            resetsAt: nil,
            sevenDayResetsAt: nil,
            sevenDaySonnetResetsAt: nil,
            source: .oauth,
            inputTokens: nil,
            outputTokens: nil,
            cacheCreationTokens: nil,
            cacheReadTokens: nil,
            model: nil,
            extraUsageEnabled: false,
            extraUsageMonthlyLimitCents: nil,
            extraUsageSpentCents: nil,
            extraUsageUtilization: nil
        )

        let point = UsageDataPoint(from: snapshot)
        XCTAssertEqual(point.primaryPercentage, 75.0)
        XCTAssertEqual(point.sevenDayPercentage, 30.0)
        XCTAssertEqual(point.source, "oauth")
    }

    // MARK: - Identifiable Tests

    func testIdentifiable_UniqueIds() {
        let point1 = UsageDataPoint(
            timestamp: Date(),
            primaryPercentage: 50.0
        )
        let point2 = UsageDataPoint(
            timestamp: Date(),
            primaryPercentage: 60.0
        )

        XCTAssertNotEqual(point1.id, point2.id)
    }
}
