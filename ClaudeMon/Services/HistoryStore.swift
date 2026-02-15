import Foundation

/// Thread-safe store for historical usage data.
/// Supports per-account history storage with backward-compatible legacy methods.
/// Persists data as JSON to Application Support/ClaudeMon/history/{accountId}.json.
/// Uses actor isolation to prevent concurrent file access issues.
actor HistoryStore {
    static let shared = HistoryStore()

    private var fileURLs: [UUID: URL] = [:]  // Account ID -> history file
    private var caches: [UUID: [UsageDataPoint]] = [:]  // Account ID -> cached points
    private let maxAgeDays: Int = 90
    private let recentWindowDays: Int = 7
    private var lastDownsampleDates: [UUID: Date] = [:]  // Track last downsample per account

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
        // Always downsample on load
        try downsampleOldEntries(for: accountId)
    }

    /// Append a data point for a specific account
    func append(_ point: UsageDataPoint, for accountId: UUID) throws {
        var cache = caches[accountId] ?? []
        cache.append(point)
        caches[accountId] = cache
        trimOldEntries(for: accountId)
        // Downsample at most once per hour on append
        if shouldDownsample(for: accountId) {
            try downsampleOldEntries(for: accountId)
        }
        try save(for: accountId)
    }

    /// Get history for a specific account
    func getHistory(for accountId: UUID) -> [UsageDataPoint] {
        return caches[accountId] ?? []
    }

    /// Get data points within a time range for a specific account
    func getHistory(for accountId: UUID, since cutoff: Date) -> [UsageDataPoint] {
        let cache = caches[accountId] ?? []
        return cache.filter { $0.timestamp > cutoff }
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
        // Always downsample on load
        try downsampleOldEntries(for: legacyUUID)
    }

    /// Append a new data point and persist (legacy single-account).
    /// Automatically trims old entries beyond maxAgeDays.
    func append(_ point: UsageDataPoint) throws {
        var cache = caches[legacyUUID] ?? []
        cache.append(point)
        caches[legacyUUID] = cache
        trimOldEntries(for: legacyUUID)
        // Downsample at most once per hour on append
        if shouldDownsample(for: legacyUUID) {
            try downsampleOldEntries(for: legacyUUID)
        }

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

    /// Check whether downsampling should run (at most once per hour on append)
    private func shouldDownsample(for accountId: UUID) -> Bool {
        guard let lastDate = lastDownsampleDates[accountId] else { return true }
        return Date().timeIntervalSince(lastDate) >= 3600
    }

    /// Downsample data points older than recentWindowDays to hourly averages.
    /// Points within the recent window keep full resolution.
    /// Reduces storage from ~25MB to ~2.4MB for 90 days of data.
    func downsampleOldEntries(for accountId: UUID) throws {
        guard var cache = caches[accountId], !cache.isEmpty else { return }

        let recentCutoff = Date().addingTimeInterval(-Double(recentWindowDays) * 24 * 3600)
        let calendar = Calendar.current

        // Split into recent (full resolution) and old (to be downsampled)
        let recentPoints = cache.filter { $0.timestamp > recentCutoff }
        let oldPoints = cache.filter { $0.timestamp <= recentCutoff }

        guard !oldPoints.isEmpty else {
            lastDownsampleDates[accountId] = Date()
            return
        }

        // Group old points by hour
        var hourGroups: [Date: [UsageDataPoint]] = [:]
        for point in oldPoints {
            guard let hourInterval = calendar.dateInterval(of: .hour, for: point.timestamp) else {
                continue
            }
            let hourStart = hourInterval.start
            hourGroups[hourStart, default: []].append(point)
        }

        // Create one averaged point per hour
        var downsampledPoints: [UsageDataPoint] = []
        for (hourStart, points) in hourGroups {
            let avgPrimary = points.map(\.primaryPercentage).reduce(0, +) / Double(points.count)

            // Average non-nil sevenDayPercentage values; nil if all are nil
            let sevenDayValues = points.compactMap(\.sevenDayPercentage)
            let avgSevenDay: Double? = sevenDayValues.isEmpty
                ? nil
                : sevenDayValues.reduce(0, +) / Double(sevenDayValues.count)

            let source = points.first?.source ?? "oauth"

            let averaged = UsageDataPoint(
                id: UUID(),
                timestamp: hourStart,
                primaryPercentage: avgPrimary,
                sevenDayPercentage: avgSevenDay,
                source: source
            )
            downsampledPoints.append(averaged)
        }

        // Combine downsampled + recent, sorted by timestamp
        cache = (downsampledPoints + recentPoints).sorted { $0.timestamp < $1.timestamp }
        caches[accountId] = cache
        lastDownsampleDates[accountId] = Date()
        try save(for: accountId)
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
