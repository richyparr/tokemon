import Foundation

// MARK: - Date Extensions

extension Date {
    /// Returns a human-readable relative time string like "just now", "2 min ago", "1 hour ago".
    func relativeTimeString() -> String {
        let now = Date()
        let interval = now.timeIntervalSince(self)

        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return minutes == 1 ? "1 min ago" : "\(minutes) min ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else {
            let days = Int(interval / 86400)
            return days == 1 ? "1 day ago" : "\(days) days ago"
        }
    }

    /// Returns a formatted reset time string like "in 2h 15m" or "Tomorrow at 3:00 PM".
    func formattedResetTime() -> String {
        let now = Date()
        let interval = self.timeIntervalSince(now)

        // If the reset time is in the past, show "expired"
        if interval <= 0 {
            return "expired"
        }

        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)

        if hours == 0 {
            return "in \(minutes)m"
        } else if hours < 24 {
            if minutes > 0 {
                return "in \(hours)h \(minutes)m"
            }
            return "in \(hours)h"
        } else {
            // More than 24 hours away -- show date/time
            let formatter = DateFormatter()
            let calendar = Calendar.current
            if calendar.isDateInTomorrow(self) {
                formatter.dateFormat = "'Tomorrow at' h:mm a"
            } else {
                formatter.dateFormat = "MMM d 'at' h:mm a"
            }
            return formatter.string(from: self)
        }
    }
}

// MARK: - Int Extensions

extension Int {
    /// Formatted token count: "12,450" for moderate numbers, "1.2M" for large numbers.
    var formattedTokenCount: String {
        if self >= 1_000_000 {
            let millions = Double(self) / 1_000_000
            return String(format: "%.1fM", millions)
        } else if self >= 10_000 {
            let thousands = Double(self) / 1_000
            return String(format: "%.1fk", thousands)
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.groupingSeparator = ","
            return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
        }
    }
}

// MARK: - Double Extensions

extension Double {
    /// Formatted percentage with one decimal: "45.0%"
    var percentageFormatted: String {
        return String(format: "%.1f%%", self)
    }
}
