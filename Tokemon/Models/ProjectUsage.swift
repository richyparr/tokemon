import Foundation

/// Token usage breakdown for a single Claude Code project.
/// Aggregated from JSONL session files across all accounts on the machine.
struct ProjectUsage: Identifiable, Sendable {
    let id: UUID
    let projectPath: String        // Decoded path (e.g., "/Users/richardparr/Tokemon")
    let projectName: String        // Last path component (e.g., "Tokemon")
    let inputTokens: Int
    let outputTokens: Int
    let cacheCreationTokens: Int
    let cacheReadTokens: Int
    let sessionCount: Int

    var totalTokens: Int {
        inputTokens + outputTokens + cacheCreationTokens + cacheReadTokens
    }
}
