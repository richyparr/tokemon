import Foundation

/// Types of shareable insight cards derived from local usage data.
enum InsightCardType: String, CaseIterable, Sendable {
    case streak = "streak"
    case growth = "growth"
    case pattern = "pattern"
    case milestone = "milestone"

    var emoji: String {
        switch self {
        case .streak: return "🔥"
        case .growth: return "📈"
        case .pattern: return "🦉"
        case .milestone: return "🎯"
        }
    }
}

/// A shareable insight derived from local usage data.
/// Each insight type has different data requirements.
struct ShareableInsight: Sendable {
    let type: InsightCardType
    let headline: String        // Main text: "12-Day Streak"
    let subheadline: String     // Supporting text: "Daily coding on Tokemon"
    let score: Double           // For ranking which card is "best" (higher = more impressive)

    // Type-specific data
    let streakDays: Int?
    let growthPercentage: Double?
    let peakHourStart: Int?     // 0-23
    let peakHourEnd: Int?       // 0-23
    let milestoneDays: Int?
    let patternLabel: String?   // "Night Owl", "Early Bird", "Midday Warrior"
}

/// Calculates shareable insights from local usage history.
enum InsightCalculator {

    /// Calculate all available insights from usage history.
    /// Returns insights sorted by score (most impressive first).
    static func calculateInsights(from history: [UsageDataPoint]) -> [ShareableInsight] {
        var insights: [ShareableInsight] = []

        if let streak = calculateStreak(from: history) {
            insights.append(streak)
        }

        if let growth = calculateGrowth(from: history) {
            insights.append(growth)
        }

        if let pattern = calculatePattern(from: history) {
            insights.append(pattern)
        }

        if let milestone = calculateMilestone(from: history) {
            insights.append(milestone)
        }

        return insights.sorted { $0.score > $1.score }
    }

    /// Get the best (highest scoring) insight, or nil if no data.
    static func bestInsight(from history: [UsageDataPoint]) -> ShareableInsight? {
        calculateInsights(from: history).first
    }

    // MARK: - Streak Calculation

    /// Calculate consecutive days with usage data.
    private static func calculateStreak(from history: [UsageDataPoint]) -> ShareableInsight? {
        guard !history.isEmpty else { return nil }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Get unique days with data, sorted descending
        let uniqueDays = Set(history.map { calendar.startOfDay(for: $0.timestamp) })
            .sorted(by: >)

        guard !uniqueDays.isEmpty else { return nil }

        // Count consecutive days from today (or yesterday if no data today yet)
        var streakDays = 0
        var expectedDay = today

        // Allow streak to start from yesterday if no data today yet
        if !uniqueDays.contains(today), let yesterday = calendar.date(byAdding: .day, value: -1, to: today) {
            expectedDay = yesterday
        }

        for day in uniqueDays {
            if day == expectedDay {
                streakDays += 1
                expectedDay = calendar.date(byAdding: .day, value: -1, to: expectedDay) ?? expectedDay
            } else if day < expectedDay {
                // Gap found, streak ends
                break
            }
        }

        guard streakDays >= 2 else { return nil }  // Only show if streak is meaningful

        // Score: logarithmic scale so 30-day streak scores ~3x a 3-day streak
        let score = log(Double(streakDays) + 1) * 20

        return ShareableInsight(
            type: .streak,
            headline: "\(streakDays)-Day Streak",
            subheadline: "Daily coding on Tokemon",
            score: score,
            streakDays: streakDays,
            growthPercentage: nil,
            peakHourStart: nil,
            peakHourEnd: nil,
            milestoneDays: nil,
            patternLabel: nil
        )
    }

    // MARK: - Growth Calculation

    /// Calculate week-over-week utilization change.
    private static func calculateGrowth(from history: [UsageDataPoint]) -> ShareableInsight? {
        let calendar = Calendar.current
        let now = Date()

        guard let oneWeekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: now),
              let twoWeeksAgo = calendar.date(byAdding: .weekOfYear, value: -2, to: now) else {
            return nil
        }

        // This week's data
        let thisWeekData = history.filter { $0.timestamp >= oneWeekAgo && $0.timestamp <= now }
        // Last week's data
        let lastWeekData = history.filter { $0.timestamp >= twoWeeksAgo && $0.timestamp < oneWeekAgo }

        guard !thisWeekData.isEmpty, !lastWeekData.isEmpty else { return nil }

        let thisWeekAvg = thisWeekData.map(\.primaryPercentage).reduce(0, +) / Double(thisWeekData.count)
        let lastWeekAvg = lastWeekData.map(\.primaryPercentage).reduce(0, +) / Double(lastWeekData.count)

        guard lastWeekAvg > 0 else { return nil }

        let growthPercent = ((thisWeekAvg - lastWeekAvg) / lastWeekAvg) * 100

        // Only show meaningful growth (at least 10% change)
        guard abs(growthPercent) >= 10 else { return nil }

        // Score: absolute growth percentage (both up and down are interesting)
        let score = abs(growthPercent) * 0.5

        let direction = growthPercent >= 0 ? "+" : ""
        let headline = "\(direction)\(Int(growthPercent))% This Week"
        let subheadline = growthPercent >= 0 ? "Usage is trending up" : "Taking it easy this week"

        return ShareableInsight(
            type: .growth,
            headline: headline,
            subheadline: subheadline,
            score: score,
            streakDays: nil,
            growthPercentage: growthPercent,
            peakHourStart: nil,
            peakHourEnd: nil,
            milestoneDays: nil,
            patternLabel: nil
        )
    }

    // MARK: - Pattern Calculation

    /// Analyze peak usage hours to determine usage pattern.
    private static func calculatePattern(from history: [UsageDataPoint]) -> ShareableInsight? {
        guard history.count >= 20 else { return nil }  // Need enough data

        let calendar = Calendar.current

        // Count data points per hour
        var hourCounts: [Int: Int] = [:]
        for point in history {
            let hour = calendar.component(.hour, from: point.timestamp)
            hourCounts[hour, default: 0] += 1
        }

        guard !hourCounts.isEmpty else { return nil }

        // Find the 3-hour window with most activity
        var bestWindowStart = 0
        var bestWindowCount = 0

        for startHour in 0..<24 {
            let windowCount = (0..<3).reduce(0) { sum, offset in
                sum + (hourCounts[(startHour + offset) % 24] ?? 0)
            }
            if windowCount > bestWindowCount {
                bestWindowCount = windowCount
                bestWindowStart = startHour
            }
        }

        let endHour = (bestWindowStart + 3) % 24

        // Determine pattern label
        let (label, _) = patternLabel(for: bestWindowStart)

        // Score based on how concentrated the activity is
        let totalPoints = hourCounts.values.reduce(0, +)
        let concentration = Double(bestWindowCount) / Double(totalPoints)
        let score = concentration * 40  // Max ~40 if all activity in one window

        let hourFormatter = { (hour: Int) -> String in
            if hour == 0 { return "12am" }
            if hour == 12 { return "12pm" }
            if hour < 12 { return "\(hour)am" }
            return "\(hour - 12)pm"
        }

        return ShareableInsight(
            type: .pattern,
            headline: label,
            subheadline: "Peak hours: \(hourFormatter(bestWindowStart)) - \(hourFormatter(endHour))",
            score: score,
            streakDays: nil,
            growthPercentage: nil,
            peakHourStart: bestWindowStart,
            peakHourEnd: endHour,
            milestoneDays: nil,
            patternLabel: label
        )
    }

    private static func patternLabel(for hour: Int) -> (String, String) {
        switch hour {
        case 5..<9:
            return ("Early Bird", "🌅")
        case 9..<12:
            return ("Morning Coder", "☀️")
        case 12..<14:
            return ("Lunch Hustler", "🥪")
        case 14..<17:
            return ("Afternoon Flow", "⚡")
        case 17..<21:
            return ("Evening Builder", "🌆")
        case 21..<24:
            return ("Night Owl", "🦉")
        default:  // 0-5
            return ("Midnight Hacker", "🌙")
        }
    }

    // MARK: - Milestone Calculation

    /// Calculate days since first tracked usage.
    private static func calculateMilestone(from history: [UsageDataPoint]) -> ShareableInsight? {
        guard let firstPoint = history.min(by: { $0.timestamp < $1.timestamp }) else {
            return nil
        }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: firstPoint.timestamp, to: Date())

        guard let days = components.day, days >= 7 else { return nil }  // At least a week

        // Nice milestones: 7, 14, 30, 60, 90, 100, 180, 365
        let niceMilestones = [7, 14, 30, 60, 90, 100, 180, 365, 500, 1000]
        let nearestMilestone = niceMilestones.first { $0 >= days } ?? days

        // Score: higher for rounder milestones
        let score: Double
        if niceMilestones.contains(days) {
            score = Double(days) * 0.2  // Bonus for hitting exact milestone
        } else if days > nearestMilestone - 3 {
            score = Double(days) * 0.15  // Close to milestone
        } else {
            score = Double(days) * 0.1
        }

        let headline = "\(days) Days on Tokemon"
        let subheadline: String
        if days >= 365 {
            subheadline = "Over a year of tracking!"
        } else if days >= 100 {
            subheadline = "Triple digits!"
        } else if days >= 30 {
            subheadline = "A whole month and counting"
        } else {
            subheadline = "Just getting started"
        }

        return ShareableInsight(
            type: .milestone,
            headline: headline,
            subheadline: subheadline,
            score: score,
            streakDays: nil,
            growthPercentage: nil,
            peakHourStart: nil,
            peakHourEnd: nil,
            milestoneDays: days,
            patternLabel: nil
        )
    }
}
