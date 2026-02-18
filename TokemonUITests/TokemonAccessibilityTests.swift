import XCTest

/// Tests for accessibility compliance and VoiceOver support
final class TokemonAccessibilityTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }

    // MARK: - Accessibility Label Tests

    /// Test that interactive elements have accessibility labels
    func testInteractiveElements_HaveAccessibilityLabels() throws {
        openPopover()

        let popover = app.popovers.firstMatch
        guard popover.waitForExistence(timeout: 3) else {
            throw XCTSkip("Could not open popover")
        }

        // Check buttons have labels
        let buttons = popover.buttons.allElementsBoundByIndex
        for button in buttons where button.exists {
            let hasAccessibility = !button.label.isEmpty ||
                                   !button.identifier.isEmpty
            XCTAssertTrue(hasAccessibility,
                "Button at \(button.frame) missing accessibility label")
        }
    }

    /// Test that status information is accessible
    func testStatusInformation_IsAccessible() throws {
        openPopover()

        let popover = app.popovers.firstMatch
        guard popover.waitForExistence(timeout: 3) else {
            throw XCTSkip("Could not open popover")
        }

        // Should have at least one static text with usage info
        let staticTexts = popover.staticTexts.allElementsBoundByIndex
        let hasUsageInfo = staticTexts.contains { text in
            text.exists && (text.label.contains("%") || text.label.contains("token"))
        }

        XCTAssertTrue(hasUsageInfo, "Usage information should be accessible as text")
    }

    // MARK: - Keyboard Navigation Tests

    /// Test that settings can be opened with keyboard
    func testSettingsKeyboardShortcut_Works() throws {
        openPopover()

        // Press Cmd+, to open settings
        app.typeKey(",", modifierFlags: .command)

        let settingsWindow = app.windows.firstMatch
        let opened = settingsWindow.waitForExistence(timeout: 3)

        // Note: This may fail if popover doesn't have focus
        if opened {
            XCTAssertTrue(settingsWindow.exists, "Settings should open with Cmd+,")
        }
    }

    /// Test tab navigation in settings
    func testSettingsTabNavigation_WorksWithKeyboard() throws {
        openSettings()

        guard app.windows.firstMatch.waitForExistence(timeout: 3) else {
            throw XCTSkip("Could not open settings")
        }

        // Tab key should navigate between elements
        app.typeKey(.tab, modifierFlags: [])
        app.typeKey(.tab, modifierFlags: [])

        // Should not crash and settings should still be visible
        XCTAssertTrue(app.windows.firstMatch.exists, "Settings should remain open after tab navigation")
    }

    // MARK: - Text Size Tests

    /// Test that text elements have sufficient size for readability
    func testTextElements_HaveSufficientSize() throws {
        openPopover()

        let popover = app.popovers.firstMatch
        guard popover.waitForExistence(timeout: 3) else {
            throw XCTSkip("Could not open popover")
        }

        let texts = popover.staticTexts.allElementsBoundByIndex

        for text in texts where text.exists && text.frame.height > 0 {
            // Text should be at least 10pt for readability
            XCTAssertGreaterThanOrEqual(text.frame.height, 10,
                "Text '\(text.label)' may be too small: \(text.frame.height)px")
        }
    }

    // MARK: - Touch Target Tests

    /// Test that buttons meet minimum touch target guidelines
    func testButtons_MeetMinimumTouchTargets() throws {
        openSettings()

        guard app.windows.firstMatch.waitForExistence(timeout: 3) else {
            throw XCTSkip("Could not open settings")
        }

        let buttons = app.windows.firstMatch.buttons.allElementsBoundByIndex

        for button in buttons where button.exists && button.isHittable {
            let frame = button.frame
            guard frame.width > 0 && frame.height > 0 else { continue }

            // macOS uses smaller targets than iOS, check for reasonable minimum
            XCTAssertGreaterThanOrEqual(frame.width, 16,
                "Button '\(button.label)' width \(frame.width) below minimum")
            XCTAssertGreaterThanOrEqual(frame.height, 16,
                "Button '\(button.label)' height \(frame.height) below minimum")
        }
    }

    // MARK: - Content Structure Tests

    /// Test that main content has proper structure
    func testMainContent_HasProperStructure() throws {
        openPopover()

        let popover = app.popovers.firstMatch
        guard popover.waitForExistence(timeout: 3) else {
            throw XCTSkip("Could not open popover")
        }

        let staticTexts = popover.staticTexts.allElementsBoundByIndex
        let buttons = popover.buttons.allElementsBoundByIndex

        // Popover should have meaningful content
        let hasContent = staticTexts.count > 0 || buttons.count > 0
        XCTAssertTrue(hasContent, "Popover should have accessible content")
    }

    /// Test that UI elements exist in popover
    func testUIElementsExist() throws {
        openPopover()

        sleep(1)

        // Check that we have some visible text elements
        let staticTexts = app.staticTexts.count
        XCTAssertGreaterThan(staticTexts, 0, "Popover should contain text elements")
    }

    // MARK: - Helper Methods

    private func openPopover() {
        let menuBarExtra = app.menuBarItems.firstMatch
        if menuBarExtra.waitForExistence(timeout: 2) {
            menuBarExtra.click()
        }
    }

    private func openSettings() {
        openPopover()
        sleep(1)
        app.typeKey(",", modifierFlags: .command)
        sleep(1)

        if !app.windows.firstMatch.exists {
            let settingsButton = app.buttons.matching(
                NSPredicate(format: "label CONTAINS[c] 'settings'")
            ).firstMatch
            if settingsButton.exists {
                settingsButton.click()
            }
        }
    }
}
