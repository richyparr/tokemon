import XCTest
@testable import tokemon

/// Unit tests for JSONLParser
final class JSONLParserTests: XCTestCase {

    // MARK: - Line Parsing Tests

    func testParseLine_ValidTokenUsage_ReturnsTokens() {
        let line = """
        {"type":"usage","data":{"input_tokens":1000,"output_tokens":500}}
        """

        let result = JSONLParser.parseUsageLine(line)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.inputTokens, 1000)
        XCTAssertEqual(result?.outputTokens, 500)
    }

    func testParseLine_InvalidJSON_ReturnsNil() {
        let line = "this is not json"
        let result = JSONLParser.parseUsageLine(line)
        XCTAssertNil(result)
    }

    func testParseLine_EmptyLine_ReturnsNil() {
        let result = JSONLParser.parseUsageLine("")
        XCTAssertNil(result)
    }

    func testParseLine_NonUsageType_ReturnsNil() {
        let line = """
        {"type":"message","data":{"content":"hello"}}
        """
        let result = JSONLParser.parseUsageLine(line)
        XCTAssertNil(result)
    }

    // MARK: - File Path Discovery Tests

    func testExpandPath_TildeExpansion() {
        let path = "~/.claude/projects/"
        let expanded = JSONLParser.expandPath(path)
        XCTAssertFalse(expanded.hasPrefix("~"), "Tilde should be expanded")
        XCTAssertTrue(expanded.hasPrefix("/"), "Path should be absolute")
    }

    func testExpandPath_AlreadyAbsolute() {
        let path = "/Users/test/.claude/projects/"
        let expanded = JSONLParser.expandPath(path)
        XCTAssertEqual(expanded, path, "Already absolute path should not change")
    }

    // MARK: - Session File Pattern Tests

    func testIsSessionFile_ValidPattern_ReturnsTrue() {
        XCTAssertTrue(JSONLParser.isSessionFile("session_abc123.jsonl"))
        XCTAssertTrue(JSONLParser.isSessionFile("session_12345.jsonl"))
    }

    func testIsSessionFile_InvalidPattern_ReturnsFalse() {
        XCTAssertFalse(JSONLParser.isSessionFile("config.json"))
        XCTAssertFalse(JSONLParser.isSessionFile("readme.md"))
        XCTAssertFalse(JSONLParser.isSessionFile("session.txt"))
    }
}
