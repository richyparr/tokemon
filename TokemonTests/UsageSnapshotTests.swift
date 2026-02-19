import XCTest
@testable import tokemon

/// Unit tests for UsageSnapshot model.
/// Tests the model's computed properties, factory methods, and edge cases.
final class UsageSnapshotTests: XCTestCase {

    // MARK: - Static Factory Tests

    func testEmpty_HasZeroValues() {
        let snapshot = UsageSnapshot.empty

        XCTAssertEqual(snapshot.primaryPercentage, 0.0)
        XCTAssertNil(snapshot.fiveHourUtilization)
        XCTAssertNil(snapshot.sevenDayUtilization)
        XCTAssertNil(snapshot.sevenDayOpusUtilization)
        XCTAssertNil(snapshot.sevenDaySonnetUtilization)
        XCTAssertNil(snapshot.resetsAt)
        XCTAssertNil(snapshot.sevenDayResetsAt)
        XCTAssertNil(snapshot.sevenDaySonnetResetsAt)
        XCTAssertEqual(snapshot.source, .none)
        XCTAssertNil(snapshot.inputTokens)
        XCTAssertNil(snapshot.outputTokens)
        XCTAssertNil(snapshot.cacheCreationTokens)
        XCTAssertNil(snapshot.cacheReadTokens)
        XCTAssertNil(snapshot.model)
        XCTAssertFalse(snapshot.extraUsageEnabled)
        XCTAssertNil(snapshot.extraUsageMonthlyLimitCents)
        XCTAssertNil(snapshot.extraUsageSpentCents)
        XCTAssertNil(snapshot.extraUsageUtilization)
    }

    // MARK: - hasPercentage Tests

    func testHasPercentage_WithZero_ReturnsTrue() {
        // hasPercentage returns true for primaryPercentage >= 0
        let snapshot = UsageSnapshot.empty
        XCTAssertTrue(snapshot.hasPercentage)
    }

    func testHasPercentage_WithPositiveValue_ReturnsTrue() {
        let snapshot = UsageSnapshot.mockOAuth(percentage: 50.0)
        XCTAssertTrue(snapshot.hasPercentage)
    }

    func testHasPercentage_WithNegativeValue_ReturnsFalse() {
        // JSONL snapshots use -1 as sentinel
        let snapshot = UsageSnapshot.mockJSONL()
        XCTAssertFalse(snapshot.hasPercentage)
    }

    // MARK: - totalTokens Tests

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

    func testTotalTokens_AllNil_ReturnsZero() {
        let snapshot = UsageSnapshot.empty
        XCTAssertEqual(snapshot.totalTokens, 0)
    }

    // MARK: - formattedTokenCount Tests

    func testFormattedTokenCount_SmallNumber() {
        let snapshot = UsageSnapshot.mockJSONL(inputTokens: 500, outputTokens: 100)
        // 600 total
        XCTAssertEqual(snapshot.formattedTokenCount, "600")
    }

    func testFormattedTokenCount_Thousands() {
        let snapshot = UsageSnapshot.mockJSONL(inputTokens: 10000, outputTokens: 2400)
        // 12400 total = 12.4k
        XCTAssertEqual(snapshot.formattedTokenCount, "12.4k")
    }

    func testFormattedTokenCount_Millions() {
        let snapshot = UsageSnapshot.mockJSONL(inputTokens: 800000, outputTokens: 400000)
        // 1200000 total = 1.2M
        XCTAssertEqual(snapshot.formattedTokenCount, "1.2M")
    }

    // MARK: - formattedExtraUsageSpent Tests

    func testFormattedExtraUsageSpent_WithValue() {
        let snapshot = UsageSnapshot.mockWithExtraUsage(spentCents: 1250)
        XCTAssertEqual(snapshot.formattedExtraUsageSpent, "$12.50")
    }

    func testFormattedExtraUsageSpent_WithZero() {
        let snapshot = UsageSnapshot.mockWithExtraUsage(spentCents: 0)
        XCTAssertEqual(snapshot.formattedExtraUsageSpent, "$0.00")
    }

    func testFormattedExtraUsageSpent_WithNil() {
        let snapshot = UsageSnapshot.empty
        XCTAssertEqual(snapshot.formattedExtraUsageSpent, "--")
    }

    // MARK: - formattedMonthlyLimit Tests

    func testFormattedMonthlyLimit_WithValue() {
        let snapshot = UsageSnapshot.mockWithExtraUsage(limitCents: 5000)
        XCTAssertEqual(snapshot.formattedMonthlyLimit, "$50")
    }

    func testFormattedMonthlyLimit_WithNil() {
        let snapshot = UsageSnapshot.empty
        XCTAssertEqual(snapshot.formattedMonthlyLimit, "--")
    }

    // MARK: - menuBarText Tests

    func testMenuBarText_NoSource_ReturnsDash() {
        let snapshot = UsageSnapshot.empty
        // Source is .none but primaryPercentage is 0 and hasPercentage is true
        // Actually .none source returns "--"
        XCTAssertEqual(snapshot.menuBarText, "--")
    }

    func testMenuBarText_OAuthWithPercentage() {
        let snapshot = UsageSnapshot.mockOAuth(percentage: 75)
        XCTAssertEqual(snapshot.menuBarText, "75%")
    }

    func testMenuBarText_JSONLFallback_ShowsTokenCount() {
        let snapshot = UsageSnapshot.mockJSONL(inputTokens: 5000, outputTokens: 2000)
        // 7000 total = 7.0k
        XCTAssertEqual(snapshot.menuBarText, "7.0k tok")
    }

    // MARK: - Mock Factory Tests

    func testMockOAuth_SetsCorrectSource() {
        let snapshot = UsageSnapshot.mockOAuth(percentage: 50)
        XCTAssertEqual(snapshot.source, .oauth)
        XCTAssertEqual(snapshot.primaryPercentage, 50)
    }

    func testMockJSONL_SetsCorrectSource() {
        let snapshot = UsageSnapshot.mockJSONL()
        XCTAssertEqual(snapshot.source, .jsonl)
        XCTAssertEqual(snapshot.primaryPercentage, -1)
    }

    func testMockWithExtraUsage_EnablesExtraUsage() {
        let snapshot = UsageSnapshot.mockWithExtraUsage()
        XCTAssertTrue(snapshot.extraUsageEnabled)
        XCTAssertEqual(snapshot.extraUsageSpentCents, 1250)
        XCTAssertEqual(snapshot.extraUsageMonthlyLimitCents, 5000)
        XCTAssertEqual(snapshot.extraUsageUtilization, 25.0)
    }

    func testMockCritical_HasHighPercentage() {
        let snapshot = UsageSnapshot.mockCritical()
        XCTAssertEqual(snapshot.primaryPercentage, 100)
    }

    func testMockWarning_HasMediumPercentage() {
        let snapshot = UsageSnapshot.mockWarning()
        XCTAssertEqual(snapshot.primaryPercentage, 85)
    }

    func testMockWithSevenDay_SetsAllMetrics() {
        let snapshot = UsageSnapshot.mockWithSevenDay()
        XCTAssertEqual(snapshot.sevenDayUtilization, 30)
        XCTAssertEqual(snapshot.sevenDayOpusUtilization, 20)
        XCTAssertEqual(snapshot.sevenDaySonnetUtilization, 40)
    }

    // MARK: - DataSource Tests

    func testDataSource_RawValues() {
        XCTAssertEqual(UsageSnapshot.DataSource.oauth.rawValue, "oauth")
        XCTAssertEqual(UsageSnapshot.DataSource.jsonl.rawValue, "jsonl")
        XCTAssertEqual(UsageSnapshot.DataSource.none.rawValue, "none")
    }
}
