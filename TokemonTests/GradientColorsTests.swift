import XCTest
import AppKit
@testable import tokemon

/// Unit tests for GradientColors utility
final class GradientColorsTests: XCTestCase {

    // MARK: - Color for Percentage Tests

    func testColorForPercentage_LowUsage_ReturnsGreen() {
        let color = GradientColors.color(for: 30.0)
        // Low usage should be greenish (higher green component)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.usingColorSpace(.sRGB)?.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        XCTAssertGreaterThan(green, red, "Low usage should have more green than red")
    }

    func testColorForPercentage_HighUsage_ReturnsRed() {
        let color = GradientColors.color(for: 95.0)
        // High usage should be reddish (higher red component)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.usingColorSpace(.sRGB)?.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        XCTAssertGreaterThan(red, green, "High usage should have more red than green")
    }

    func testColorForPercentage_MidUsage_ReturnsYellowish() {
        let color = GradientColors.color(for: 60.0)
        // Mid usage should be yellowish (both red and green, low blue)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.usingColorSpace(.sRGB)?.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        XCTAssertGreaterThan(red, blue, "Mid usage should have red component")
        XCTAssertGreaterThan(green, blue, "Mid usage should have green component")
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
}
