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
            secondaryPercentage: 50.0,
            inputTokens: 1000,
            outputTokens: 500
        )

        XCTAssertEqual(point.timestamp, timestamp)
        XCTAssertEqual(point.primaryPercentage, 75.5)
        XCTAssertEqual(point.secondaryPercentage, 50.0)
        XCTAssertEqual(point.inputTokens, 1000)
        XCTAssertEqual(point.outputTokens, 500)
    }

    func testInit_WithNilSecondaryPercentage() {
        let point = UsageDataPoint(
            timestamp: Date(),
            primaryPercentage: 50.0,
            secondaryPercentage: nil,
            inputTokens: 0,
            outputTokens: 0
        )

        XCTAssertNil(point.secondaryPercentage)
    }

    // MARK: - Computed Properties Tests

    func testTotalTokens_ReturnsSum() {
        let point = UsageDataPoint(
            timestamp: Date(),
            primaryPercentage: 50.0,
            secondaryPercentage: nil,
            inputTokens: 1000,
            outputTokens: 500
        )

        XCTAssertEqual(point.totalTokens, 1500)
    }

    func testTotalTokens_ZeroValues() {
        let point = UsageDataPoint(
            timestamp: Date(),
            primaryPercentage: 0.0,
            secondaryPercentage: nil,
            inputTokens: 0,
            outputTokens: 0
        )

        XCTAssertEqual(point.totalTokens, 0)
    }

    // MARK: - Identifiable Tests

    func testIdentifiable_UniqueIds() {
        let point1 = UsageDataPoint(
            timestamp: Date(),
            primaryPercentage: 50.0,
            secondaryPercentage: nil,
            inputTokens: 1000,
            outputTokens: 500
        )
        let point2 = UsageDataPoint(
            timestamp: Date(),
            primaryPercentage: 60.0,
            secondaryPercentage: nil,
            inputTokens: 2000,
            outputTokens: 1000
        )

        XCTAssertNotEqual(point1.id, point2.id)
    }
}
