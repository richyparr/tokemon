import XCTest
@testable import tokemon

/// Unit tests for BurnRateCalculator
final class BurnRateCalculatorTests: XCTestCase {

    // MARK: - Burn Rate Calculation Tests

    func testCalculateBurnRate_EmptyHistory_ReturnsNil() {
        let result = BurnRateCalculator.calculateBurnRate(from: [])
        XCTAssertNil(result)
    }

    func testCalculateBurnRate_SinglePoint_ReturnsNil() {
        let point = UsageDataPoint(
            timestamp: Date(),
            primaryPercentage: 50.0
        )
        let result = BurnRateCalculator.calculateBurnRate(from: [point])
        XCTAssertNil(result)
    }

    func testCalculateBurnRate_IncreasingUsage_ReturnsPositiveRate() {
        let now = Date()
        let points = [
            UsageDataPoint(timestamp: now.addingTimeInterval(-3600), primaryPercentage: 40.0),
            UsageDataPoint(timestamp: now, primaryPercentage: 50.0),
        ]

        let result = BurnRateCalculator.calculateBurnRate(from: points)
        XCTAssertNotNil(result)
        if let rate = result {
            XCTAssertGreaterThan(rate, 0, "Burn rate should be positive for increasing usage")
        }
    }

    func testCalculateBurnRate_DecreasingUsage_ReturnsNegativeRate() {
        let now = Date()
        let points = [
            UsageDataPoint(timestamp: now.addingTimeInterval(-3600), primaryPercentage: 60.0),
            UsageDataPoint(timestamp: now, primaryPercentage: 40.0),
        ]

        let result = BurnRateCalculator.calculateBurnRate(from: points)
        XCTAssertNotNil(result)
        if let rate = result {
            XCTAssertLessThan(rate, 0, "Burn rate should be negative for decreasing usage")
        }
    }

    // MARK: - Projection Tests

    func testProjectTimeToLimit_ZeroBurnRate_ReturnsNil() {
        let result = BurnRateCalculator.projectTimeToLimit(
            currentUsage: 50.0,
            burnRate: 0.0
        )
        XCTAssertNil(result)
    }

    func testProjectTimeToLimit_NegativeBurnRate_ReturnsNil() {
        let result = BurnRateCalculator.projectTimeToLimit(
            currentUsage: 50.0,
            burnRate: -5.0
        )
        XCTAssertNil(result, "Should return nil when usage is decreasing")
    }

    func testProjectTimeToLimit_AlreadyAtLimit_ReturnsNil() {
        let result = BurnRateCalculator.projectTimeToLimit(
            currentUsage: 100.0,
            burnRate: 5.0
        )
        XCTAssertNil(result, "Should return nil when already at 100%")
    }

    func testProjectTimeToLimit_PositiveBurnRate_ReturnsPositiveTime() {
        // At 50%, burning 5% per hour, should hit 100% in ~10 hours = 36000 seconds
        let result = BurnRateCalculator.projectTimeToLimit(
            currentUsage: 50.0,
            burnRate: 5.0
        )
        XCTAssertNotNil(result)
        if let seconds = result {
            XCTAssertEqual(seconds, 36000.0, accuracy: 1.0)
        }
    }

    // MARK: - Format Tests

    func testFormatTimeRemaining_Hours() {
        let result = BurnRateCalculator.formatTimeRemaining(7200) // 2 hours
        XCTAssertEqual(result, "2h 0m")
    }

    func testFormatTimeRemaining_Minutes() {
        let result = BurnRateCalculator.formatTimeRemaining(2700) // 45 min
        XCTAssertEqual(result, "45m")
    }

    func testFormatTimeRemaining_OverADay() {
        let result = BurnRateCalculator.formatTimeRemaining(100000) // >24h
        XCTAssertEqual(result, ">24h")
    }
}
