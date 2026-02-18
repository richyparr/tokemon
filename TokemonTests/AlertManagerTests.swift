import XCTest
@testable import tokemon

/// Unit tests for AlertManager alert level calculations
final class AlertManagerTests: XCTestCase {

    // MARK: - Alert Level Tests

    func testAlertLevel_BelowWarning_ReturnsNormal() {
        // Default threshold is 80%, so 70% should be normal
        let level = AlertManager.calculateAlertLevel(for: 70.0, threshold: 80)
        XCTAssertEqual(level, .normal)
    }

    func testAlertLevel_AtWarningThreshold_ReturnsWarning() {
        let level = AlertManager.calculateAlertLevel(for: 80.0, threshold: 80)
        XCTAssertEqual(level, .warning)
    }

    func testAlertLevel_AboveWarningBelowCritical_ReturnsWarning() {
        let level = AlertManager.calculateAlertLevel(for: 85.0, threshold: 80)
        XCTAssertEqual(level, .warning)
    }

    func testAlertLevel_AtCriticalThreshold_ReturnsCritical() {
        // Critical is typically threshold + 10%
        let level = AlertManager.calculateAlertLevel(for: 90.0, threshold: 80)
        XCTAssertEqual(level, .critical)
    }

    func testAlertLevel_AboveCritical_ReturnsCritical() {
        let level = AlertManager.calculateAlertLevel(for: 95.0, threshold: 80)
        XCTAssertEqual(level, .critical)
    }

    func testAlertLevel_AtHundredPercent_ReturnsCritical() {
        let level = AlertManager.calculateAlertLevel(for: 100.0, threshold: 80)
        XCTAssertEqual(level, .critical)
    }

    // MARK: - Custom Threshold Tests

    func testAlertLevel_CustomLowThreshold() {
        // With threshold at 50%, 45% should be normal
        let level = AlertManager.calculateAlertLevel(for: 45.0, threshold: 50)
        XCTAssertEqual(level, .normal)

        // 55% should be warning
        let warningLevel = AlertManager.calculateAlertLevel(for: 55.0, threshold: 50)
        XCTAssertEqual(warningLevel, .warning)
    }

    func testAlertLevel_CustomHighThreshold() {
        // With threshold at 95%, 90% should be normal
        let level = AlertManager.calculateAlertLevel(for: 90.0, threshold: 95)
        XCTAssertEqual(level, .normal)
    }

    // MARK: - Edge Cases

    func testAlertLevel_ZeroUsage_ReturnsNormal() {
        let level = AlertManager.calculateAlertLevel(for: 0.0, threshold: 80)
        XCTAssertEqual(level, .normal)
    }

    func testAlertLevel_NegativeUsage_ReturnsNormal() {
        let level = AlertManager.calculateAlertLevel(for: -10.0, threshold: 80)
        XCTAssertEqual(level, .normal)
    }
}
