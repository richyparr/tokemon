import XCTest
@testable import tokemon

/// Unit tests for AlertManager alert level calculations
@MainActor
final class AlertManagerTests: XCTestCase {

    // MARK: - Helpers

    /// Create an OAuth snapshot at the given percentage for alert testing
    private func oauthSnapshot(percentage: Double, resetsAt: Date? = Date().addingTimeInterval(3600)) -> UsageSnapshot {
        UsageSnapshot(
            primaryPercentage: percentage,
            fiveHourUtilization: percentage,
            sevenDayUtilization: nil,
            sevenDayOpusUtilization: nil,
            sevenDaySonnetUtilization: nil,
            resetsAt: resetsAt,
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
    }

    // MARK: - Alert Level Tests (via checkUsage)

    func testCheckUsage_BelowThreshold_RemainsNormal() {
        let manager = AlertManager()
        manager.checkUsage(oauthSnapshot(percentage: 70.0))
        XCTAssertEqual(manager.currentAlertLevel, .normal)
    }

    func testCheckUsage_AtThreshold_BecomesWarning() {
        let manager = AlertManager()
        // Default threshold is 80
        manager.checkUsage(oauthSnapshot(percentage: 80.0))
        XCTAssertEqual(manager.currentAlertLevel, .warning)
    }

    func testCheckUsage_AboveThreshold_BecomesWarning() {
        let manager = AlertManager()
        manager.checkUsage(oauthSnapshot(percentage: 85.0))
        XCTAssertEqual(manager.currentAlertLevel, .warning)
    }

    func testCheckUsage_AtHundredPercent_BecomesCritical() {
        let manager = AlertManager()
        manager.checkUsage(oauthSnapshot(percentage: 100.0))
        XCTAssertEqual(manager.currentAlertLevel, .critical)
    }

    func testCheckUsage_AboveHundredPercent_BecomesCritical() {
        let manager = AlertManager()
        manager.checkUsage(oauthSnapshot(percentage: 105.0))
        XCTAssertEqual(manager.currentAlertLevel, .critical)
    }

    // MARK: - Edge Cases

    func testCheckUsage_ZeroUsage_RemainsNormal() {
        let manager = AlertManager()
        manager.checkUsage(oauthSnapshot(percentage: 0.0))
        XCTAssertEqual(manager.currentAlertLevel, .normal)
    }

    func testResetNotificationState_ResetsToNormal() {
        let manager = AlertManager()
        manager.checkUsage(oauthSnapshot(percentage: 100.0))
        XCTAssertEqual(manager.currentAlertLevel, .critical)

        manager.resetNotificationState()
        XCTAssertEqual(manager.currentAlertLevel, .normal)
    }

    // MARK: - Alert Level Enum Tests

    func testAlertLevel_Comparable() {
        XCTAssertTrue(AlertManager.AlertLevel.normal < AlertManager.AlertLevel.warning)
        XCTAssertTrue(AlertManager.AlertLevel.warning < AlertManager.AlertLevel.critical)
        XCTAssertFalse(AlertManager.AlertLevel.critical < AlertManager.AlertLevel.normal)
    }
}
