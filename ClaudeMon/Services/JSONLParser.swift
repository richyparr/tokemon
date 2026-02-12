import Foundation

/// Defensive parser for Claude Code JSONL session log files.
/// Reads from `~/.claude/projects/` and extracts token usage from assistant messages.
/// Handles malformed lines gracefully -- never crashes on unexpected input.
struct JSONLParser {

    // MARK: - Types

    /// Token usage from a single session file
    struct SessionUsage {
        var inputTokens: Int = 0
        var outputTokens: Int = 0
        var cacheCreationTokens: Int = 0
        var cacheReadTokens: Int = 0
        var model: String?
        var sessionId: String?
        var timestamp: Date?
    }

    /// Aggregated usage across all parsed sessions
    struct AggregateUsage {
        var inputTokens: Int = 0
        var outputTokens: Int = 0
        var cacheCreationTokens: Int = 0
        var cacheReadTokens: Int = 0
        var sessionCount: Int = 0

        /// Total tokens across all categories
        var totalTokens: Int {
            inputTokens + outputTokens + cacheCreationTokens + cacheReadTokens
        }
    }

    /// Errors that can occur during JSONL parsing
    enum JSONLError: Error, LocalizedError {
        case noProjectsDirectory
        case noSessionFiles
        case parseError(Error)

        var errorDescription: String? {
            switch self {
            case .noProjectsDirectory:
                return "Claude Code projects directory not found (~/.claude/projects/)"
            case .noSessionFiles:
                return "No session files found in Claude Code projects"
            case .parseError(let error):
                return "Failed to parse JSONL files: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Directory Discovery

    /// Find all project directories under `~/.claude/projects/`.
    /// Each directory represents a Claude Code project (e.g., `-Users-richardparr-ClaudeMon`).
    /// - Returns: Array of directory URLs.
    /// - Throws: `JSONLError.noProjectsDirectory` if the projects directory does not exist.
    static func findProjectDirectories() throws -> [URL] {
        let projectsPath = (Constants.claudeProjectsPath as NSString).expandingTildeInPath
        let projectsURL = URL(fileURLWithPath: projectsPath, isDirectory: true)

        guard FileManager.default.fileExists(atPath: projectsURL.path) else {
            throw JSONLError.noProjectsDirectory
        }

        let contents: [URL]
        do {
            contents = try FileManager.default.contentsOfDirectory(
                at: projectsURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
        } catch {
            throw JSONLError.noProjectsDirectory
        }

        // Filter to directories only
        return contents.filter { url in
            var isDirectory: ObjCBool = false
            FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
            return isDirectory.boolValue
        }
    }

    /// Find JSONL session files in a project directory.
    /// - Parameters:
    ///   - projectDir: The project directory URL.
    ///   - since: Optional date filter -- only return files modified after this date.
    /// - Returns: Array of `.jsonl` file URLs, sorted by modification date (newest first).
    static func findSessionFiles(in projectDir: URL, since: Date? = nil) -> [URL] {
        let fileManager = FileManager.default

        guard let contents = try? fileManager.contentsOfDirectory(
            at: projectDir,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var jsonlFiles = contents.filter { $0.pathExtension == "jsonl" }

        // Filter by modification date if provided
        if let since = since {
            jsonlFiles = jsonlFiles.filter { url in
                guard let values = try? url.resourceValues(forKeys: [.contentModificationDateKey]),
                      let modDate = values.contentModificationDate else {
                    return false
                }
                return modDate >= since
            }
        }

        // Sort by modification date descending (newest first)
        jsonlFiles.sort { url1, url2 in
            let date1 = (try? url1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
            let date2 = (try? url2.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
            return date1 > date2
        }

        return jsonlFiles
    }

    // MARK: - Parsing

    /// Parse a single JSONL session file and extract token usage.
    ///
    /// - CRITICAL: Defensive parsing throughout. Never force-unwraps.
    ///   Every field access uses optional chaining with defaults.
    ///   Lines that fail to decode are skipped silently (count logged for debugging).
    ///
    /// - Parameter url: The `.jsonl` file URL to parse.
    /// - Returns: Accumulated `SessionUsage` from all assistant messages in the file.
    static func parseSession(at url: URL) -> SessionUsage {
        var usage = SessionUsage()
        var skippedLines = 0

        guard let fileHandle = try? FileHandle(forReadingFrom: url) else {
            return usage
        }
        defer { try? fileHandle.close() }

        let data = fileHandle.readDataToEndOfFile()
        guard let content = String(data: data, encoding: .utf8) else {
            return usage
        }

        let lines = content.split(separator: "\n", omittingEmptySubsequences: true)

        for line in lines {
            // Defensive: skip empty lines
            guard !line.isEmpty else { continue }

            // Defensive: wrap entire parse in do/catch
            do {
                guard let lineData = line.data(using: .utf8) else {
                    skippedLines += 1
                    continue
                }

                guard let json = try JSONSerialization.jsonObject(with: lineData) as? [String: Any] else {
                    skippedLines += 1
                    continue
                }

                // Only process assistant messages with usage data
                guard json["type"] as? String == "assistant",
                      let message = json["message"] as? [String: Any],
                      let usageObj = message["usage"] as? [String: Any] else {
                    continue // Not an assistant message with usage -- skip (not an error)
                }

                // Accumulate tokens (defensive: default to 0 for missing fields)
                usage.inputTokens += usageObj["input_tokens"] as? Int ?? 0
                usage.outputTokens += usageObj["output_tokens"] as? Int ?? 0
                usage.cacheCreationTokens += usageObj["cache_creation_input_tokens"] as? Int ?? 0
                usage.cacheReadTokens += usageObj["cache_read_input_tokens"] as? Int ?? 0

                // Capture model from first assistant message
                if usage.model == nil {
                    usage.model = message["model"] as? String
                }

                // Capture session metadata
                if usage.sessionId == nil {
                    usage.sessionId = json["sessionId"] as? String
                }

                // Capture timestamp from first message
                if usage.timestamp == nil {
                    if let timestampStr = json["timestamp"] as? String {
                        let formatter = ISO8601DateFormatter()
                        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                        usage.timestamp = formatter.date(from: timestampStr)
                    }
                }
            } catch {
                skippedLines += 1
                continue
            }
        }

        if skippedLines > 0 {
            print("[ClaudeMon] JSONL parser: skipped \(skippedLines) malformed lines in \(url.lastPathComponent)")
        }

        return usage
    }

    /// Parse recent usage across all Claude Code projects.
    /// - Parameter since: Only parse sessions modified after this date. Defaults to 24 hours ago.
    /// - Returns: Aggregated usage from all matching sessions.
    /// - Throws: `JSONLError` if the projects directory is not found or no sessions exist.
    static func parseRecentUsage(since: Date? = nil) throws -> AggregateUsage {
        let cutoffDate = since ?? Date().addingTimeInterval(-24 * 3600) // Default: last 24 hours

        let projectDirs = try findProjectDirectories()

        var aggregate = AggregateUsage()
        var totalSessionFiles = 0

        for projectDir in projectDirs {
            let sessionFiles = findSessionFiles(in: projectDir, since: cutoffDate)
            totalSessionFiles += sessionFiles.count

            for sessionFile in sessionFiles {
                let sessionUsage = parseSession(at: sessionFile)
                aggregate.inputTokens += sessionUsage.inputTokens
                aggregate.outputTokens += sessionUsage.outputTokens
                aggregate.cacheCreationTokens += sessionUsage.cacheCreationTokens
                aggregate.cacheReadTokens += sessionUsage.cacheReadTokens
                aggregate.sessionCount += 1
            }
        }

        if totalSessionFiles == 0 {
            throw JSONLError.noSessionFiles
        }

        return aggregate
    }

    /// Convert aggregate JSONL usage into a UsageSnapshot for display.
    ///
    /// JSONL does not provide utilization percentages (no limit info available),
    /// so `primaryPercentage` is set to -1 as a sentinel indicating "tokens only, no percentage".
    /// The menu bar will display a token count instead of a percentage.
    ///
    /// - Parameter aggregate: The aggregated JSONL usage data.
    /// - Returns: A `UsageSnapshot` with token counts and `.jsonl` source.
    static func toSnapshot(from aggregate: AggregateUsage) -> UsageSnapshot {
        return UsageSnapshot(
            primaryPercentage: -1, // Sentinel: no percentage available from JSONL
            fiveHourUtilization: nil,
            sevenDayUtilization: nil,
            sevenDayOpusUtilization: nil,
            resetsAt: nil,
            source: .jsonl,
            inputTokens: aggregate.inputTokens,
            outputTokens: aggregate.outputTokens,
            cacheCreationTokens: aggregate.cacheCreationTokens,
            cacheReadTokens: aggregate.cacheReadTokens,
            model: nil
        )
    }
}
