import XCTest
@testable import tokemon

/// Unit tests for Constants configuration values
final class ConstantsTests: XCTestCase {

    // MARK: - API Endpoints Tests

    func testOAuthUsageURL_IsValid() {
        let url = URL(string: Constants.oauthUsageURL)
        XCTAssertNotNil(url, "OAuth usage URL should be a valid URL")
        XCTAssertEqual(url?.scheme, "https", "Should use HTTPS")
    }

    func testOAuthTokenRefreshURL_IsValid() {
        let url = URL(string: Constants.oauthTokenRefreshURL)
        XCTAssertNotNil(url, "Token refresh URL should be a valid URL")
        XCTAssertEqual(url?.scheme, "https", "Should use HTTPS")
    }

    // MARK: - Default Values Tests

    func testDefaultRefreshInterval_IsReasonable() {
        XCTAssertGreaterThanOrEqual(Constants.defaultRefreshInterval, 30, "Refresh interval should be at least 30 seconds")
        XCTAssertLessThanOrEqual(Constants.defaultRefreshInterval, 300, "Refresh interval should be at most 5 minutes")
    }

    func testDefaultAlertThreshold_IsWithinRange() {
        XCTAssertGreaterThan(Constants.defaultAlertThreshold, 0)
        XCTAssertLessThanOrEqual(Constants.defaultAlertThreshold, 100)
    }

    func testMaxRetryAttempts_IsPositive() {
        XCTAssertGreaterThan(Constants.maxRetryAttempts, 0)
    }

    // MARK: - Keychain Service Names Tests

    func testKeychainService_IsNotEmpty() {
        XCTAssertFalse(Constants.keychainService.isEmpty)
    }

    func testAccountsKeychainService_IsNotEmpty() {
        XCTAssertFalse(Constants.accountsKeychainService.isEmpty)
    }

    func testClaudeCodeKeychainService_MatchesKeychainService() {
        XCTAssertEqual(Constants.claudeCodeKeychainService, Constants.keychainService)
    }

    // MARK: - Path Tests

    func testClaudeProjectsPath_ContainsClaude() {
        XCTAssertTrue(Constants.claudeProjectsPath.contains("claude"))
    }

    func testStatuslineDirectory_ContainsTokemon() {
        XCTAssertTrue(Constants.statuslineDirectory.contains("tokemon"))
    }

    // MARK: - Sparkle Updates Tests

    func testSparkleAppcastURL_IsValidURL() {
        let url = URL(string: Constants.sparkleAppcastURL)
        XCTAssertNotNil(url, "Appcast URL should be valid")
        XCTAssertEqual(url?.scheme, "https", "Should use HTTPS")
    }
}
