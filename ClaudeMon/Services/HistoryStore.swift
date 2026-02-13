import Foundation

/// Thread-safe store for historical usage data.
/// Persists data as JSON to Application Support/ClaudeMon/usage_history.json.
/// Uses actor isolation to prevent concurrent file access issues.
actor HistoryStore {
    static let shared = HistoryStore()

    private let fileURL: URL
    private var cache: [UsageDataPoint] = []
    private let maxAgeDays: Int = 30

    init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let appDir = appSupport.appendingPathComponent("ClaudeMon", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        self.fileURL = appDir.appendingPathComponent("usage_history.json")
    }

    /// Load history from disk into cache. Call once at app startup.
    func load() throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            cache = []
            return
        }
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        cache = try decoder.decode([UsageDataPoint].self, from: data)
    }

    /// Append a new data point and persist.
    /// Automatically trims old entries beyond maxAgeDays.
    func append(_ point: UsageDataPoint) throws {
        cache.append(point)
        trimOldEntries()
        try save()
    }

    /// Get all cached data points (for chart rendering).
    func getHistory() -> [UsageDataPoint] {
        return cache
    }

    /// Get data points within a time range.
    func getHistory(since cutoff: Date) -> [UsageDataPoint] {
        return cache.filter { $0.timestamp > cutoff }
    }

    /// Clear all history (for testing or user reset).
    func clear() throws {
        cache = []
        try save()
    }

    // MARK: - Private

    private func trimOldEntries() {
        let cutoff = Date().addingTimeInterval(-Double(maxAgeDays) * 24 * 3600)
        cache = cache.filter { $0.timestamp > cutoff }
    }

    private func save() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(cache)
        try data.write(to: fileURL)
    }
}
