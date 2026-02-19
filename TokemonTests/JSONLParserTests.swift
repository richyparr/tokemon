import XCTest
@testable import tokemon

/// Unit tests for JSONLParser
final class JSONLParserTests: XCTestCase {

    // MARK: - Type Tests

    func testSessionUsage_DefaultValues() {
        let usage = JSONLParser.SessionUsage()
        XCTAssertEqual(usage.inputTokens, 0)
        XCTAssertEqual(usage.outputTokens, 0)
        XCTAssertEqual(usage.cacheCreationTokens, 0)
        XCTAssertEqual(usage.cacheReadTokens, 0)
        XCTAssertNil(usage.model)
        XCTAssertNil(usage.sessionId)
        XCTAssertNil(usage.timestamp)
    }

    func testAggregateUsage_TotalTokens() {
        var aggregate = JSONLParser.AggregateUsage()
        aggregate.inputTokens = 1000
        aggregate.outputTokens = 500
        aggregate.cacheCreationTokens = 200
        aggregate.cacheReadTokens = 100

        XCTAssertEqual(aggregate.totalTokens, 1800)
    }

    func testAggregateUsage_DefaultZeroTotals() {
        let aggregate = JSONLParser.AggregateUsage()
        XCTAssertEqual(aggregate.totalTokens, 0)
        XCTAssertEqual(aggregate.sessionCount, 0)
    }

    // MARK: - Snapshot Conversion Tests

    func testToSnapshot_SetsJSONLSource() {
        var aggregate = JSONLParser.AggregateUsage()
        aggregate.inputTokens = 5000
        aggregate.outputTokens = 2000

        let snapshot = JSONLParser.toSnapshot(from: aggregate)
        XCTAssertEqual(snapshot.source, .jsonl)
    }

    func testToSnapshot_SetsNegativePercentage() {
        let aggregate = JSONLParser.AggregateUsage()
        let snapshot = JSONLParser.toSnapshot(from: aggregate)
        XCTAssertEqual(snapshot.primaryPercentage, -1)
    }

    func testToSnapshot_CopiesTokenCounts() {
        var aggregate = JSONLParser.AggregateUsage()
        aggregate.inputTokens = 5000
        aggregate.outputTokens = 2000
        aggregate.cacheCreationTokens = 300
        aggregate.cacheReadTokens = 150

        let snapshot = JSONLParser.toSnapshot(from: aggregate)
        XCTAssertEqual(snapshot.inputTokens, 5000)
        XCTAssertEqual(snapshot.outputTokens, 2000)
        XCTAssertEqual(snapshot.cacheCreationTokens, 300)
        XCTAssertEqual(snapshot.cacheReadTokens, 150)
    }

    func testToSnapshot_DisablesExtraUsage() {
        let aggregate = JSONLParser.AggregateUsage()
        let snapshot = JSONLParser.toSnapshot(from: aggregate)
        XCTAssertFalse(snapshot.extraUsageEnabled)
        XCTAssertNil(snapshot.extraUsageMonthlyLimitCents)
        XCTAssertNil(snapshot.extraUsageSpentCents)
    }

    // MARK: - Error Tests

    func testJSONLError_Descriptions() {
        let dirError = JSONLParser.JSONLError.noProjectsDirectory
        XCTAssertNotNil(dirError.errorDescription)
        XCTAssertTrue(dirError.errorDescription!.contains("projects directory"))

        let sessionError = JSONLParser.JSONLError.noSessionFiles
        XCTAssertNotNil(sessionError.errorDescription)
        XCTAssertTrue(sessionError.errorDescription!.contains("session files"))
    }

    // MARK: - Parse Session Tests (empty file)

    func testParseSession_NonexistentFile_ReturnsEmpty() {
        let fakeURL = URL(fileURLWithPath: "/tmp/nonexistent_session_\(UUID().uuidString).jsonl")
        let usage = JSONLParser.parseSession(at: fakeURL)
        XCTAssertEqual(usage.inputTokens, 0)
        XCTAssertEqual(usage.outputTokens, 0)
    }

    func testParseSession_ValidJSONL_ParsesTokens() throws {
        // Create a temporary JSONL file with assistant message
        let tmpFile = FileManager.default.temporaryDirectory.appendingPathComponent("test_session_\(UUID().uuidString).jsonl")

        let jsonLine = """
        {"type":"assistant","message":{"usage":{"input_tokens":1000,"output_tokens":500,"cache_creation_input_tokens":100,"cache_read_input_tokens":50},"model":"claude-sonnet-4-20250514"},"sessionId":"test123","timestamp":"2026-02-19T10:00:00.000Z"}
        """

        try jsonLine.write(to: tmpFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tmpFile) }

        let usage = JSONLParser.parseSession(at: tmpFile)
        XCTAssertEqual(usage.inputTokens, 1000)
        XCTAssertEqual(usage.outputTokens, 500)
        XCTAssertEqual(usage.cacheCreationTokens, 100)
        XCTAssertEqual(usage.cacheReadTokens, 50)
        XCTAssertEqual(usage.model, "claude-sonnet-4-20250514")
        XCTAssertEqual(usage.sessionId, "test123")
    }

    func testParseSession_MalformedLine_SkipsGracefully() throws {
        let tmpFile = FileManager.default.temporaryDirectory.appendingPathComponent("test_malformed_\(UUID().uuidString).jsonl")

        let content = """
        this is not json
        {"type":"assistant","message":{"usage":{"input_tokens":500,"output_tokens":200},"model":"test"}}
        also not json {{{
        """

        try content.write(to: tmpFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tmpFile) }

        let usage = JSONLParser.parseSession(at: tmpFile)
        XCTAssertEqual(usage.inputTokens, 500)
        XCTAssertEqual(usage.outputTokens, 200)
    }
}
