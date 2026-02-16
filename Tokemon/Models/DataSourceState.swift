import Foundation

/// Tracks per-source availability state for OAuth and JSONL data sources.
enum DataSourceState: Sendable {
    case available
    case failed(String) // Store error description for Sendable conformance
    case disabled
    case notConfigured

    /// Whether this data source can be used for fetching
    var isUsable: Bool {
        if case .available = self {
            return true
        }
        return false
    }
}
