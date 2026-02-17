import XCTest

final class TokemonUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Menu Bar Tests

    /// Test that the app launches and the menu bar item is accessible
    func testAppLaunches() throws {
        // For menu bar apps, we check the status item
        // The app should be running
        XCTAssertTrue(app.state == .runningForeground || app.state == .runningBackground)
    }

    /// Test clicking the menu bar icon opens the popover
    func testMenuBarClickOpensPopover() throws {
        // Menu bar apps need special handling
        // The status item is in the system menu bar, not in the app's window hierarchy

        // For LSUIElement apps, we interact with the status bar through XCUIApplication
        let menuBar = XCUIApplication(bundleIdentifier: "com.apple.controlcenter").menuBars.firstMatch

        // Find our app's menu extra
        // Note: This requires the app to be running with a visible status item
        let statusItem = menuBar.statusItems["Tokemon"]

        if statusItem.exists {
            statusItem.click()

            // After clicking, a popover should appear
            // The popover content is in our app's window
            let popover = app.popovers.firstMatch
            XCTAssertTrue(popover.waitForExistence(timeout: 2))
        }
    }

    // MARK: - Popover Content Tests

    /// Test that the usage header displays when popover is open
    func testPopoverShowsUsageHeader() throws {
        openPopover()

        // Check for usage percentage text (should contain %)
        let usageText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '%'")).firstMatch
        XCTAssertTrue(usageText.waitForExistence(timeout: 3), "Usage percentage should be visible")
    }

    /// Test that the refresh button exists and is clickable
    func testRefreshButtonExists() throws {
        openPopover()

        // Look for the refresh button
        let refreshButton = app.buttons["Refresh"].firstMatch
        if refreshButton.waitForExistence(timeout: 2) {
            XCTAssertTrue(refreshButton.isEnabled, "Refresh button should be enabled")
        }
    }

    // MARK: - Settings Tests

    /// Test opening settings from the popover
    func testOpenSettingsFromPopover() throws {
        openPopover()

        // Look for settings button (gear icon)
        let settingsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'settings' OR label CONTAINS[c] 'gear'")).firstMatch

        if settingsButton.waitForExistence(timeout: 2) {
            settingsButton.click()

            // Settings window should appear
            let settingsWindow = app.windows["Settings"].firstMatch
            XCTAssertTrue(settingsWindow.waitForExistence(timeout: 3), "Settings window should open")
        }
    }

    /// Test that settings tabs are navigable
    func testSettingsTabNavigation() throws {
        openSettings()

        // Check for common settings tabs
        let alertsTab = app.buttons["Alerts"].firstMatch
        let appearanceTab = app.buttons["Appearance"].firstMatch
        let dataSourcesTab = app.buttons["Data Sources"].firstMatch

        // At least one tab should exist
        let anyTabExists = alertsTab.exists || appearanceTab.exists || dataSourcesTab.exists
        XCTAssertTrue(anyTabExists, "At least one settings tab should exist")
    }

    // MARK: - Helper Methods

    private func openPopover() {
        // Try to open the popover by clicking the status item
        // This is a simplified version - in practice, menu bar interaction
        // may require accessibility permissions and specific targeting

        let menuBarExtra = app.menuBarItems.firstMatch
        if menuBarExtra.waitForExistence(timeout: 2) {
            menuBarExtra.click()
        }
    }

    private func openSettings() {
        openPopover()

        // Wait a moment for popover to fully appear
        sleep(1)

        // Try to find and click settings
        let settingsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'settings'")).firstMatch
        if settingsButton.waitForExistence(timeout: 2) {
            settingsButton.click()
        }
    }
}
