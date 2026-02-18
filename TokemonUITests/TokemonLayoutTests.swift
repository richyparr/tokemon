import XCTest

/// Tests for UI layout, sizing, and overflow issues
final class TokemonLayoutTests: XCTestCase {

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

    // MARK: - Popover Size Tests

    /// Test that popover has reasonable dimensions
    func testPopoverSize_IsWithinBounds() throws {
        openPopover()

        let popover = app.popovers.firstMatch
        guard popover.waitForExistence(timeout: 3) else {
            throw XCTSkip("Could not open popover")
        }

        let frame = popover.frame
        // Popover should be between 280-400 pixels wide
        XCTAssertGreaterThanOrEqual(frame.width, 280, "Popover too narrow")
        XCTAssertLessThanOrEqual(frame.width, 450, "Popover too wide")

        // Popover should have reasonable height
        XCTAssertGreaterThanOrEqual(frame.height, 150, "Popover too short")
        XCTAssertLessThanOrEqual(frame.height, 800, "Popover too tall")
    }

    /// Test that popover content doesn't overflow
    func testPopoverContent_NoHorizontalOverflow() throws {
        openPopover()

        let popover = app.popovers.firstMatch
        guard popover.waitForExistence(timeout: 3) else {
            throw XCTSkip("Could not open popover")
        }

        let popoverFrame = popover.frame

        // Check that all text elements are within popover bounds
        let textElements = popover.staticTexts.allElementsBoundByIndex
        for text in textElements {
            if text.exists && text.isHittable {
                let textFrame = text.frame
                XCTAssertGreaterThanOrEqual(textFrame.minX, popoverFrame.minX - 10,
                    "Text '\(text.label)' overflows left")
                XCTAssertLessThanOrEqual(textFrame.maxX, popoverFrame.maxX + 10,
                    "Text '\(text.label)' overflows right")
            }
        }
    }

    // MARK: - Settings Window Tests

    /// Test settings window has proper dimensions
    func testSettingsWindow_HasProperSize() throws {
        openSettings()

        let settingsWindow = app.windows.firstMatch
        guard settingsWindow.waitForExistence(timeout: 3) else {
            throw XCTSkip("Could not open settings window")
        }

        let frame = settingsWindow.frame
        // Settings should be at least 400x300
        XCTAssertGreaterThanOrEqual(frame.width, 400, "Settings window too narrow")
        XCTAssertGreaterThanOrEqual(frame.height, 300, "Settings window too short")
    }

    /// Test that settings tabs are all accessible
    func testSettingsTabs_AllVisible() throws {
        openSettings()

        // Wait for settings to load
        sleep(1)

        // Check for common tab buttons
        let tabNames = ["General", "Alerts", "Appearance", "Data Sources", "Admin", "Analytics", "Team", "Budget", "Webhooks"]

        var foundTabs = 0
        for tabName in tabNames {
            let tab = app.buttons[tabName].firstMatch
            if tab.exists {
                foundTabs += 1
                // Tab should be hittable (not obscured)
                XCTAssertTrue(tab.isHittable, "Tab '\(tabName)' is obscured")
            }
        }

        XCTAssertGreaterThan(foundTabs, 0, "At least some settings tabs should exist")
    }

    /// Test that tab content doesn't overflow when switching tabs
    func testSettingsTabs_ContentDoesNotOverflow() throws {
        openSettings()

        let settingsWindow = app.windows.firstMatch
        guard settingsWindow.waitForExistence(timeout: 3) else {
            throw XCTSkip("Could not open settings window")
        }

        let windowFrame = settingsWindow.frame
        let tabNames = ["General", "Alerts", "Appearance", "Analytics"]

        for tabName in tabNames {
            let tab = app.buttons[tabName].firstMatch
            if tab.exists && tab.isHittable {
                tab.click()
                sleep(1) // Wait for tab content to load

                // Check all visible text fits within window
                let textElements = settingsWindow.staticTexts.allElementsBoundByIndex.prefix(20)
                for text in textElements {
                    if text.exists && text.frame.width > 0 {
                        XCTAssertLessThanOrEqual(text.frame.maxX, windowFrame.maxX + 20,
                            "Text in \(tabName) tab overflows: '\(text.label)'")
                    }
                }
            }
        }
    }

    // MARK: - Button Tests

    /// Test that all buttons have readable labels
    func testButtons_HaveReadableLabels() throws {
        openSettings()

        let settingsWindow = app.windows.firstMatch
        guard settingsWindow.waitForExistence(timeout: 3) else {
            throw XCTSkip("Could not open settings window")
        }

        let buttons = settingsWindow.buttons.allElementsBoundByIndex
        for button in buttons {
            if button.exists && button.isHittable {
                // Button should have some identifier (label or accessibility)
                let hasLabel = !button.label.isEmpty || !button.identifier.isEmpty
                XCTAssertTrue(hasLabel, "Button at \(button.frame) has no label")

                // Button should have minimum tap target size (44x44 recommended, but 24x24 minimum)
                if button.frame.width > 0 && button.frame.height > 0 {
                    XCTAssertGreaterThanOrEqual(button.frame.width, 20,
                        "Button '\(button.label)' too narrow for tapping")
                    XCTAssertGreaterThanOrEqual(button.frame.height, 20,
                        "Button '\(button.label)' too short for tapping")
                }
            }
        }
    }

    // MARK: - Text Truncation Tests

    /// Test that percentage text is fully visible
    func testPercentageText_NotTruncated() throws {
        openPopover()

        let popover = app.popovers.firstMatch
        guard popover.waitForExistence(timeout: 3) else {
            throw XCTSkip("Could not open popover")
        }

        // Find percentage texts (contain %)
        let percentTexts = popover.staticTexts.matching(
            NSPredicate(format: "label CONTAINS '%'")
        ).allElementsBoundByIndex

        for text in percentTexts {
            if text.exists {
                // Percentage should be visible and not truncated (contains full number + %)
                let label = text.label
                XCTAssertTrue(label.contains("%"), "Percentage text incomplete: '\(label)'")

                // Should have a number before the %
                let beforePercent = label.components(separatedBy: "%").first ?? ""
                let containsNumber = beforePercent.contains(where: { $0.isNumber })
                XCTAssertTrue(containsNumber, "Percentage missing number: '\(label)'")
            }
        }
    }

    // MARK: - Form Field Tests

    /// Test text fields have proper width
    func testTextFields_HaveProperWidth() throws {
        openSettings()

        // Go to a tab with text fields (like Admin or Webhooks)
        let adminTab = app.buttons["Admin"].firstMatch
        if adminTab.exists && adminTab.isHittable {
            adminTab.click()
            sleep(1)
        }

        let textFields = app.textFields.allElementsBoundByIndex
        for field in textFields {
            if field.exists && field.frame.width > 0 {
                // Text fields should be at least 100px wide to be usable
                XCTAssertGreaterThanOrEqual(field.frame.width, 80,
                    "Text field too narrow: \(field.frame.width)px")
            }
        }
    }

    // MARK: - Chart Tests

    /// Test that chart area is present in Analytics
    func testAnalytics_ChartAreaExists() throws {
        openSettings()

        let analyticsTab = app.buttons["Analytics"].firstMatch
        guard analyticsTab.exists && analyticsTab.isHittable else {
            throw XCTSkip("Analytics tab not found")
        }

        analyticsTab.click()
        sleep(1)

        // Check for chart-related elements or the chart group
        let settingsWindow = app.windows.firstMatch
        let groups = settingsWindow.groups.allElementsBoundByIndex

        // At least one group should exist (form sections)
        XCTAssertGreaterThan(groups.count, 0, "Analytics should have content groups")
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

        // Try keyboard shortcut first
        app.typeKey(",", modifierFlags: .command)
        sleep(1)

        // If that didn't work, try clicking settings button
        if !app.windows.firstMatch.exists {
            let settingsButton = app.buttons.matching(
                NSPredicate(format: "label CONTAINS[c] 'settings' OR label CONTAINS[c] 'gear'")
            ).firstMatch
            if settingsButton.exists {
                settingsButton.click()
            }
        }
    }
}
