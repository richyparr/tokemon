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
            primaryPercentage: 50.0,
            secondaryPercentage: nil,
            inputTokens: 1000,
            outputTokens: 500
        )
        let result = BurnRateCalculator.calculateBurnRate(from: [point])
        XCTAssertNil(result)
    }

    func testCalculateBurnRate_IncreasingUsage_ReturnsPositiveRate() {
        let now = Date()
        let points = [
            UsageDataPoint(timestamp: now.addingTimeInterval(-3600), primaryPercentage: 40.0, secondaryPercentage: nil, inputTokens: 1000, outputTokens: 500),
            UsageDataPoint(timestamp: now, primaryPercentage: 50.0, secondaryPercentage: nil, inputTokens: 1500, outputTokens: 700),
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
            UsageDataPoint(timestamp: now.addingTimeInterval(-3600), primaryPercentage: 60.0, secondaryPercentage: nil, inputTokens: 2000, outputTokens: 1000),
            UsageDataPoint(timestamp: now, primaryPercentage: 40.0, secondaryPercentage: nil, inputTokens: 1000, outputTokens: 500),
        ]

        let result = BurnRateCalculator.calculateBurnRate(from: points)
        XCTAssertNotNil(result)
        if let rate = result {
            XCTAssertLessThan(rate, 0, "Burn rate should be negative for decreasing usage")
        }
    }

    // MARK: - Projection Tests

    func testProjectedTimeToThreshold_ZeroBurnRate_ReturnsNil() {
        let result = BurnRateCalculator.projectedTimeToThreshold(
            currentUsage: 50.0,
            burnRatePerHour: 0.0,
            threshold: 100.0
        )
        XCTAssertNil(result)
    }

    func testProjectedTimeToThreshold_NegativeBurnRate_ReturnsNil() {
        let result = BurnRateCalculator.projectedTimeToThreshold(
            currentUsage: 50.0,
            burnRatePerHour: -5.0,
            threshold: 100.0
        )
        XCTAssertNil(result, "Should return nil when usage is decreasing")
    }

    func testProjectedTimeToThreshold_AlreadyAtThreshold_ReturnsZero() {
        let result = BurnRateCalculator.projectedTimeToThreshold(
            currentUsage: 100.0,
            burnRatePerHour: 5.0,
            threshold: 100.0
        )
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, 0, accuracy: 0.01)
    }

    func testProjectedTimeToThreshold_PositiveBurnRate_ReturnsCorrectTime() {
        // At 50%, burning 5% per hour, should hit 100% in 10 hours
        let result = BurnRateCalculator.projectedTimeToThreshold(
            currentUsage: 50.0,
            burnRatePerHour: 5.0,
            threshold: 100.0
        )
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, 10.0, accuracy: 0.01)
    }
}
