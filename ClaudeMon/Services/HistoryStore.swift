import Foundation

/// Thread-safe store for historical usage data.
/// Supports per-account history storage with backward-compatible legacy methods.
/// Persists data as JSON to Application Support/ClaudeMon/history/{accountId}.json.
/// Uses actor isolation to prevent concurrent file access issues.
actor HistoryStore {
    static let shared = HistoryStore()

    private var fileURLs: [UUID: URL] = [:]  // Account ID -> history file
    private var caches: [UUID: [UsageDataPoint]] = [:]  // Account ID -> cached points
    private let maxAgeDays: Int = 30

    /// Legacy file URL for single-account storage
    private var legacyFileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("ClaudeMon", isDirectory: true)
        return appDir.appendingPathComponent("usage_history.json")
    }

    /// Sentinel UUID for legacy single-account data
    private let legacyUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

    init() {
        // Create app directory if needed (for legacy compatibility)
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let appDir = appSupport.appendingPathComponent("ClaudeMon", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
    }

    private func fileURL(for accountId: UUID) -> URL {
        if let cached = fileURLs[accountId] { return cached }

        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let historyDir = appSupport.appendingPathComponent("ClaudeMon/history", isDirectory: true)
        try? FileManager.default.createDirectory(at: historyDir, withIntermediateDirectories: true)

        let url = historyDir.appendingPathComponent("\(accountId.uuidString).json")
        fileURLs[accountId] = url
        return url
    }

    // MARK: - Per-Account Methods

    /// Load history for a specific account
    func load(for accountId: UUID) throws {
        let url = fileURL(for: accountId)
        guard FileManager.default.fileExists(atPath: url.path) else {
            caches[accountId] = []
            return
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        caches[accountId] = try decoder.decode([UsageDataPoint].self, from: data)
    }

    /// Append a data point for a specific account
    func append(_ point: UsageDataPoint, for accountId: UUID) throws {
        var cache = caches[accountId] ?? []
        cache.append(point)
        caches[accountId] = cache
        trimOldEntries(for: accountId)
        try save(for: accountId)
    }

    /// Get history for a specific account
    func getHistory(for accountId: UUID) -> [UsageDataPoint] {
        return caches[accountId] ?? []
    }

    /// Clear history for a specific account
    func clear(for accountId: UUID) throws {
        caches[accountId] = []
        try save(for: accountId)
    }

    // MARK: - Legacy Single-Account Methods

    /// Load history from disk into cache (legacy single-account). Call once at app startup.
    func load() throws {
        guard FileManager.default.fileExists(atPath: legacyFileURL.path) else {
            caches[legacyUUID] = []
            return
        }
        let data = try Data(contentsOf: legacyFileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        caches[legacyUUID] = try decoder.decode([UsageDataPoint].self, from: data)
    }

    /// Append a new data point and persist (legacy single-account).
    /// Automatically trims old entries beyond maxAgeDays.
    func append(_ point: UsageDataPoint) throws {
        var cache = caches[legacyUUID] ?? []
        cache.append(point)
        caches[legacyUUID] = cache
        trimOldEntries(for: legacyUUID)

        // Legacy: write to single file
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(caches[legacyUUID])
        try data.write(to: legacyFileURL)
    }

    /// Get all cached data points (legacy single-account, for chart rendering).
    func getHistory() -> [UsageDataPoint] {
        return caches[legacyUUID] ?? []
    }

    /// Get data points within a time range (legacy single-account).
    func getHistory(since cutoff: Date) -> [UsageDataPoint] {
        let cache = caches[legacyUUID] ?? []
        return cache.filter { $0.timestamp > cutoff }
    }

    /// Clear all history (legacy single-account).
    func clear() throws {
        caches[legacyUUID] = []
        try? FileManager.default.removeItem(at: legacyFileURL)
    }

    // MARK: - Private

    private func trimOldEntries(for accountId: UUID) {
        let cutoff = Date().addingTimeInterval(-Double(maxAgeDays) * 24 * 3600)
        if var cache = caches[accountId] {
            cache = cache.filter { $0.timestamp > cutoff }
            caches[accountId] = cache
        }
    }

    private func save(for accountId: UUID) throws {
        let cache = caches[accountId] ?? []
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(cache)
        try data.write(to: fileURL(for: accountId))
    }
}
