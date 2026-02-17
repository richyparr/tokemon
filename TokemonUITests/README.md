# Tokemon UI Tests

XCUITest suite for automated UI testing of the Tokemon macOS app.

## Prerequisites

1. **Xcode** must be installed and configured:
   ```bash
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -license accept
   ```

2. **Accessibility permissions** may be required for XCUITest to interact with the menu bar.

## Running Tests

### Via Script
```bash
./scripts/build-xcode.sh test
```

### Via Xcode
1. Open `Tokemon.xcodeproj` in Xcode
2. Select the `Tokemon` scheme
3. Press `Cmd+U` to run all tests

### Via Command Line
```bash
xcodebuild -project Tokemon.xcodeproj -scheme Tokemon test
```

## Test Structure

### TokemonUITests.swift
Core UI tests for:
- App launch
- Menu bar interaction
- Popover content
- Settings navigation

### TokemonLaunchTests.swift
- Launch scenarios (normal, first run)
- Launch performance metrics

### TokemonAccessibilityTests.swift
- Accessibility label coverage
- Keyboard navigation
- Basic UI element verification

## Writing New Tests

### Menu Bar App Considerations

Tokemon is an `LSUIElement` app (menu bar app), which requires special handling:

1. **Status Items**: The menu bar item is in the system menu bar, not the app window hierarchy
2. **Popovers**: After clicking the status item, content appears in the app's popover
3. **No Main Window**: Unlike regular apps, there's no main window to query

### Example Test

```swift
func testNewFeature() throws {
    // Open the popover first
    let menuBarItem = app.menuBarItems.firstMatch
    if menuBarItem.waitForExistence(timeout: 2) {
        menuBarItem.click()
    }

    // Now interact with popover content
    let element = app.staticTexts["Expected Text"]
    XCTAssertTrue(element.waitForExistence(timeout: 3))
}
```

## Regenerating the Project

If you modify `project.yml`, regenerate the Xcode project:

```bash
./scripts/build-xcode.sh regenerate
```

## Troubleshooting

### "Failed to launch app"
- Ensure the app is code-signed (even with ad-hoc signing)
- Check that no other instance of Tokemon is running

### "Element not found"
- Menu bar apps need time to set up their status items
- Add `waitForExistence(timeout:)` calls
- Check accessibility labels match what you're searching for

### "Accessibility permissions"
- System Preferences > Security & Privacy > Privacy > Accessibility
- Grant Xcode and Terminal access if running tests from command line
