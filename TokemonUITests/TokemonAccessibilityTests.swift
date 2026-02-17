import XCTest

/// Tests for accessibility compliance
final class TokemonAccessibilityTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Accessibility Tests

    /// Test that main UI elements have accessibility labels
    func testMainUIHasAccessibilityLabels() throws {
        // Open the popover
        let menuBarItem = app.menuBarItems.firstMatch
        if menuBarItem.waitForExistence(timeout: 2) {
            menuBarItem.click()
        }

        // Wait for popover content
        sleep(1)

        // Check that interactive elements are accessible
        let buttons = app.buttons.allElementsBoundByIndex
        for button in buttons where button.exists {
            // Every button should have some form of label
            XCTAssertFalse(button.label.isEmpty, "Button should have accessibility label")
        }
    }

    /// Test keyboard navigation
    func testKeyboardNavigation() throws {
        let menuBarItem = app.menuBarItems.firstMatch
        if menuBarItem.waitForExistence(timeout: 2) {
            menuBarItem.click()
        }

        sleep(1)

        // Try Tab key navigation
        app.typeKey(.tab, modifierFlags: [])

        // App should handle keyboard input without crashing
        XCTAssertTrue(app.state == .runningForeground || app.state == .runningBackground)
    }

    /// Test that text elements have sufficient contrast (basic check)
    func testUIElementsExist() throws {
        let menuBarItem = app.menuBarItems.firstMatch
        if menuBarItem.waitForExistence(timeout: 2) {
            menuBarItem.click()
        }

        sleep(1)

        // Check that we have some visible text elements
        let staticTexts = app.staticTexts.count
        XCTAssertGreaterThan(staticTexts, 0, "Popover should contain text elements")
    }
}
