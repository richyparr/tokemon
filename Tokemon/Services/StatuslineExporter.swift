import Foundation
import AppKit

/// Service that exports usage data to disk for terminal statusline integration.
/// Writes plain text and colored versions of the statusline plus JSON for custom integrations.
@MainActor
final class StatuslineExporter {
    /// Notification posted when statusline config changes
    static let configChangedNotification = Notification.Name("StatuslineConfigChanged")

    private var config: StatuslineConfig
    private let statuslineDirectory: URL
    private let statuslineFile: URL
    private let statuslineColorFile: URL
    private let statusJsonFile: URL

    init() {
        config = StatuslineConfig.load()

        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        statuslineDirectory = homeDir.appendingPathComponent(".tokemon")
        statuslineFile = statuslineDirectory.appendingPathComponent("statusline")
        statuslineColorFile = statuslineDirectory.appendingPathComponent("statusline-color")
        statusJsonFile = statuslineDirectory.appendingPathComponent("status.json")

        // Create directory if needed
        try? FileManager.default.createDirectory(at: statuslineDirectory, withIntermediateDirectories: true)
    }

    /// Reload configuration from UserDefaults
    func reloadConfig() {
        config = StatuslineConfig.load()
    }

    /// Export usage data to disk files
    func export(_ usage: UsageSnapshot) {
        // If disabled, clean up files and return
        guard config.enabled else {
            cleanupFiles()
            return
        }

        // Build the statusline string
        let plainText = buildStatusline(usage: usage, colored: false)
        let coloredText = config.useColors ? buildStatusline(usage: usage, colored: true) : plainText

        // Write files atomically
        writeFile(plainText, to: statuslineFile)
        writeFile(coloredText, to: statuslineColorFile)
        writeStatusJson(usage)
    }

    /// Install shell helper script to ~/.tokemon/
    func installShellHelper() {
        let destPath = statuslineDirectory.appendingPathComponent("tokemon-statusline.sh")

        // Get the shell script from the app bundle
        guard let sourceURL = Bundle.main.url(forResource: "tokemon-statusline", withExtension: "sh") else {
            // Script not found in bundle - this is expected during development
            return
        }

        do {
            // Check if destination exists and compare modification dates
            if FileManager.default.fileExists(atPath: destPath.path) {
                let sourceAttrs = try FileManager.default.attributesOfItem(atPath: sourceURL.path)
                let destAttrs = try FileManager.default.attributesOfItem(atPath: destPath.path)

                if let sourceDate = sourceAttrs[.modificationDate] as? Date,
                   let destDate = destAttrs[.modificationDate] as? Date,
                   destDate >= sourceDate {
                    // Destination is newer or same, skip copy
                    return
                }
            }

            // Copy the file
            try? FileManager.default.removeItem(at: destPath)
            try FileManager.default.copyItem(at: sourceURL, to: destPath)

            // Make executable (chmod +x)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: destPath.path)
        } catch {
            // Silently fail - not critical for app operation
        }
    }

    // MARK: - Private

    private func buildStatusline(usage: UsageSnapshot, colored: Bool) -> String {
        var fields: [String] = []

        // Session percentage (5-hour window)
        if config.showSessionPercent {
            let pct = Int(usage.primaryPercentage)
            let field = "S:\(pct)%"
            fields.append(colored ? colorize(field, percentage: usage.primaryPercentage) : field)
        }

        // Weekly percentage (7-day window)
        if config.showWeeklyPercent {
            let pct = Int(usage.sevenDayUtilization ?? 0)
            let field = "W:\(pct)%"
            let weeklyPct = usage.sevenDayUtilization ?? 0
            fields.append(colored ? colorize(field, percentage: weeklyPct) : field)
        }

        // Reset timer
        if config.showResetTimer {
            let field = formatResetTimer(resetsAt: usage.resetsAt)
            fields.append(field) // Reset timer doesn't get colored
        }

        // Join and wrap
        let content = fields.joined(separator: config.separator)
        let result = "\(config.prefix)\(content)\(config.suffix)"

        // Add reset code at the end if colored
        if colored {
            return result + "\u{001B}[0m"
        }
        return result
    }

    private func colorize(_ text: String, percentage: Double) -> String {
        let colorCode: String
        if percentage < 50 {
            colorCode = "\u{001B}[32m" // Green
        } else if percentage < 80 {
            colorCode = "\u{001B}[33m" // Yellow
        } else {
            colorCode = "\u{001B}[31m" // Red
        }
        return colorCode + text
    }

    private func formatResetTimer(resetsAt: Date?) -> String {
        guard let resetDate = resetsAt else {
            return "R:--"
        }

        let now = Date()
        let remaining = resetDate.timeIntervalSince(now)

        if remaining <= 0 {
            return "R:0m"
        }

        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60

        if hours > 0 {
            return "R:\(hours)h\(minutes)m"
        }
        return "R:\(minutes)m"
    }

    private func writeFile(_ content: String, to url: URL) {
        guard let data = content.data(using: .utf8) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private func writeStatusJson(_ usage: UsageSnapshot) {
        var dict: [String: Any] = [:]

        dict["session_pct"] = usage.primaryPercentage

        if let weekly = usage.sevenDayUtilization {
            dict["weekly_pct"] = weekly
        }

        if let resetsAt = usage.resetsAt {
            let remaining = resetsAt.timeIntervalSince(Date())
            if remaining > 0 {
                dict["reset_minutes"] = Int(remaining / 60)
            }
            let formatter = ISO8601DateFormatter()
            dict["reset_time"] = formatter.string(from: resetsAt)
        }

        let formatter = ISO8601DateFormatter()
        dict["updated"] = formatter.string(from: Date())

        if let data = try? JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys]) {
            try? data.write(to: statusJsonFile, options: .atomic)
        }
    }

    private func cleanupFiles() {
        try? FileManager.default.removeItem(at: statuslineFile)
        try? FileManager.default.removeItem(at: statuslineColorFile)
        try? FileManager.default.removeItem(at: statusJsonFile)
    }
}
