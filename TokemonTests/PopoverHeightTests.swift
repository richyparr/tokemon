import XCTest
@testable import tokemon

/// Unit tests for PopoverHeightCalculator.
/// Verifies that the popover height is computed correctly for every combination
/// of content visibility flags: profile count, extra usage, update banner, chart.
final class PopoverHeightTests: XCTestCase {

    // MARK: - Single Feature Tests

    func testBaseHeight_SingleProfile_NoExtras() {
        let height = PopoverHeightCalculator.calculate(
            profileCount: 1,
            showExtraUsage: false,
            extraUsageEnabled: false,
            updateAvailable: false,
            showUsageTrend: false
        )
        XCTAssertEqual(height, 300, "Base height with single profile and no extras should be 300")
    }

    func testWithChart_AddsChartHeight() {
        let height = PopoverHeightCalculator.calculate(
            profileCount: 1,
            showExtraUsage: false,
            extraUsageEnabled: false,
            updateAvailable: false,
            showUsageTrend: true
        )
        XCTAssertEqual(height, 530, "Chart adds 230 to base 300 = 530")
    }

    func testWithUpdateBanner_AddsBannerHeight() {
        let height = PopoverHeightCalculator.calculate(
            profileCount: 1,
            showExtraUsage: false,
            extraUsageEnabled: false,
            updateAvailable: true,
            showUsageTrend: false
        )
        XCTAssertEqual(height, 356, "Update banner adds 56 to base 300 = 356")
    }

    func testWithExtraUsage_AddsExtraHeight() {
        let height = PopoverHeightCalculator.calculate(
            profileCount: 1,
            showExtraUsage: true,
            extraUsageEnabled: true,
            updateAvailable: false,
            showUsageTrend: false
        )
        XCTAssertEqual(height, 375, "Extra usage adds 75 to base 300 = 375")
    }

    func testExtraUsage_OnlyWhenBothFlags() {
        // showExtraUsage=true but extraUsageEnabled=false -> no addition
        let height = PopoverHeightCalculator.calculate(
            profileCount: 1,
            showExtraUsage: true,
            extraUsageEnabled: false,
            updateAvailable: false,
            showUsageTrend: false
        )
        XCTAssertEqual(height, 300, "Extra usage requires both flags to be true")
    }

    // MARK: - Multi-Profile Tests

    func testMultiProfile_TwoProfiles() {
        let height = PopoverHeightCalculator.calculate(
            profileCount: 2,
            showExtraUsage: false,
            extraUsageEnabled: false,
            updateAvailable: false,
            showUsageTrend: false
        )
        // 300 + 28 (switcher) + 32 (header) + 2*24 (rows) = 300 + 108 = 408
        XCTAssertEqual(height, 408, "Two profiles: 300 + 28 + 32 + 48 = 408")
    }

    func testMultiProfile_ThreeProfiles() {
        let height = PopoverHeightCalculator.calculate(
            profileCount: 3,
            showExtraUsage: false,
            extraUsageEnabled: false,
            updateAvailable: false,
            showUsageTrend: false
        )
        // 300 + 28 + 32 + 3*24 = 300 + 132 = 432
        XCTAssertEqual(height, 432, "Three profiles: 300 + 28 + 32 + 72 = 432")
    }

    func testSingleProfile_NoProfileSwitcher() {
        let height = PopoverHeightCalculator.calculate(
            profileCount: 1,
            showExtraUsage: false,
            extraUsageEnabled: false,
            updateAvailable: false,
            showUsageTrend: false
        )
        XCTAssertEqual(height, 300, "Single profile should not add profile switcher height")
    }

    func testZeroProfiles_NoProfileSwitcher() {
        let height = PopoverHeightCalculator.calculate(
            profileCount: 0,
            showExtraUsage: false,
            extraUsageEnabled: false,
            updateAvailable: false,
            showUsageTrend: false
        )
        XCTAssertEqual(height, 300, "Zero profiles (edge case) should not add profile switcher height")
    }

    // MARK: - Combined Tests

    func testAllExtras_Combined() {
        let height = PopoverHeightCalculator.calculate(
            profileCount: 3,
            showExtraUsage: true,
            extraUsageEnabled: true,
            updateAvailable: true,
            showUsageTrend: true
        )
        // 300 (base) + 132 (3 profiles: 28+32+72) + 75 (extra) + 56 (update) + 230 (chart) = 793
        XCTAssertEqual(height, 793, "All extras with 3 profiles: 300 + 132 + 75 + 56 + 230 = 793")
    }
}
