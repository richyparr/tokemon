import XCTest
@testable import tokemon

/// Unit tests for AnalyticsEngine calculations
final class AnalyticsEngineTests: XCTestCase {

    // MARK: - Weekly Summaries Tests

    func testWeeklySummaries_EmptyInput_ReturnsEmpty() {
        let summaries = AnalyticsEngine.weeklySummaries(from: [])
        XCTAssertTrue(summaries.isEmpty)
    }

    func testWeeklySummaries_SinglePoint_ReturnsOneSummary() {
        let point = UsageDataPoint(
            timestamp: Date(),
            primaryPercentage: 50.0
        )
        let summaries = AnalyticsEngine.weeklySummaries(from: [point], weeks: 1)
        XCTAssertEqual(summaries.count, 1)
        XCTAssertEqual(summaries.first?.averageUtilization ?? 0, 50.0, accuracy: 0.1)
    }

    func testWeeklySummaries_MultiplePoints_CalculatesCorrectAverage() {
        let now = Date()
        let points = [
            UsageDataPoint(timestamp: now, primaryPercentage: 40.0),
            UsageDataPoint(timestamp: now.addingTimeInterval(-3600), primaryPercentage: 60.0),
            UsageDataPoint(timestamp: now.addingTimeInterval(-7200), primaryPercentage: 80.0),
        ]

        let summaries = AnalyticsEngine.weeklySummaries(from: points, weeks: 1)
        XCTAssertEqual(summaries.count, 1)
        // Average of 40, 60, 80 = 60
        XCTAssertEqual(summaries.first?.averageUtilization ?? 0, 60.0, accuracy: 0.1)
        // Peak should be 80
        XCTAssertEqual(summaries.first?.peakUtilization ?? 0, 80.0, accuracy: 0.1)
    }

    // MARK: - Monthly Summaries Tests

    func testMonthlySummaries_EmptyInput_ReturnsEmpty() {
        let summaries = AnalyticsEngine.monthlySummaries(from: [])
        XCTAssertTrue(summaries.isEmpty)
    }

    // MARK: - Token Formatting Tests

    func testFormatTokenCount_SmallNumber() {
        XCTAssertEqual(AnalyticsEngine.formatTokenCount(500), "500")
    }

    func testFormatTokenCount_Thousands() {
        XCTAssertEqual(AnalyticsEngine.formatTokenCount(1500), "1.5K")
        XCTAssertEqual(AnalyticsEngine.formatTokenCount(10000), "10.0K")
    }

    func testFormatTokenCount_Millions() {
        XCTAssertEqual(AnalyticsEngine.formatTokenCount(1500000), "1.5M")
        XCTAssertEqual(AnalyticsEngine.formatTokenCount(10000000), "10.0M")
    }

    func testFormatTokenCount_VeryLarge_StillUsesMillions() {
        // Implementation caps at M suffix; 1.5B = 1500.0M
        XCTAssertEqual(AnalyticsEngine.formatTokenCount(1500000000), "1500.0M")
    }
}
