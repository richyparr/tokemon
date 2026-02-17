import XCTest

/// Tests for app launch scenarios and initial state
final class TokemonLaunchTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }

    // MARK: - Launch Tests

    /// Test normal app launch
    func testNormalLaunch() throws {
        app.launch()

        // App should launch without crashing
        XCTAssertTrue(app.state == .runningForeground || app.state == .runningBackground)
    }

    /// Test launch with clean state (for first-run experience testing)
    func testFirstRunLaunch() throws {
        // Pass launch argument to simulate first run
        app.launchArguments = ["--reset-state"]
        app.launch()

        XCTAssertTrue(app.state == .runningForeground || app.state == .runningBackground)
    }

    // MARK: - Performance Tests

    /// Test app launch performance
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
        }
    }
}
