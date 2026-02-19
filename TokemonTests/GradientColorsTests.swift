import XCTest
import AppKit
@testable import tokemon

/// Unit tests for GradientColors utility
final class GradientColorsTests: XCTestCase {

    // MARK: - Color for Percentage Tests

    func testColorForPercentage_LowUsage_ReturnsWhite() {
        // 0-64% returns white (neutral)
        let color = GradientColors.color(for: 30.0)
        XCTAssertEqual(color, NSColor.white)
    }

    func testColorForPercentage_AmberRange_ReturnsAmber() {
        // 65-79% returns amber (calibratedRed 1.0, 0.8, 0.2)
        let color = GradientColors.color(for: 70.0)
        // Read in same color space it was created in
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        XCTAssertEqual(red, 1.0, accuracy: 0.05, "Amber should have full red")
        XCTAssertGreaterThan(green, 0.5, "Amber should have significant green")
        XCTAssertLessThan(blue, 0.4, "Amber should have low blue")
    }

    func testColorForPercentage_OrangeRange_ReturnsOrange() {
        // 80-94% returns orange (calibratedRed 1.0, 0.5, 0.2)
        let color = GradientColors.color(for: 85.0)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        XCTAssertEqual(red, 1.0, accuracy: 0.05, "Orange should have full red")
        XCTAssertGreaterThan(red, green, "Orange should have more red than green")
    }

    func testColorForPercentage_HighUsage_ReturnsRed() {
        // 95-100% returns red (calibratedRed 1.0, 0.3, 0.3)
        let color = GradientColors.color(for: 95.0)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        XCTAssertEqual(red, 1.0, accuracy: 0.05, "Red should have full red")
        XCTAssertGreaterThan(red, green, "High usage should have more red than green")
    }

    // MARK: - Edge Cases

    func testColorForPercentage_Zero_DoesNotCrash() {
        let color = GradientColors.color(for: 0.0)
        XCTAssertNotNil(color)
    }

    func testColorForPercentage_Hundred_DoesNotCrash() {
        let color = GradientColors.color(for: 100.0)
        XCTAssertNotNil(color)
    }

    func testColorForPercentage_OverHundred_DoesNotCrash() {
        let color = GradientColors.color(for: 150.0)
        XCTAssertNotNil(color)
    }

    func testColorForPercentage_Negative_DoesNotCrash() {
        let color = GradientColors.color(for: -10.0)
        XCTAssertNotNil(color)
    }

    // MARK: - Monochrome Override Tests

    func testNsColor_MonochromeTrue_ReturnsLabelColor() {
        let color = GradientColors.nsColor(for: 95.0, isMonochrome: true)
        XCTAssertEqual(color, NSColor.labelColor)
    }

    func testNsColor_MonochromeFalse_ReturnsGradientColor() {
        let color = GradientColors.nsColor(for: 95.0, isMonochrome: false)
        XCTAssertNotEqual(color, NSColor.labelColor)
    }

    // MARK: - Boundary Tests

    func testColorForPercentage_AtBoundary65_ReturnsAmber() {
        let color = GradientColors.color(for: 65.0)
        XCTAssertNotEqual(color, NSColor.white, "65% should transition from white to amber")
    }

    func testColorForPercentage_JustBelow65_ReturnsWhite() {
        let color = GradientColors.color(for: 64.9)
        XCTAssertEqual(color, NSColor.white, "Below 65% should be white")
    }
}
