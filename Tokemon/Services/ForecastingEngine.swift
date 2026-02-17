import Foundation
import SwiftUI

/// Stateless forecasting engine for budget predictions and pace indicators.
/// All methods are static, following the BurnRateCalculator pattern.
struct ForecastingEngine {

    // MARK: - Pace Indicator

    /// Indicates whether spending is on pace, ahead, or behind relative to the monthly budget.
    enum PaceIndicator: String, Sendable {
        case onPace = "On Pace"
        case ahead = "Ahead"
        case behind = "Behind"
        case unknown = "\u{2014}" // em dash

        /// Color for the pace indicator in UI
        var color: Color {
            switch self {
            case .onPace: return .green
            case .ahead: return .red       // Spending faster than budget allows
            case .behind: return .blue     // Under budget
            case .unknown: return .secondary
            }
        }

        /// SF Symbol icon for the pace indicator
        var icon: String {
            switch self {
            case .onPace: return "equal.circle.fill"
            case .ahead: return "arrow.up.circle.fill"
            case .behind: return "arrow.down.circle.fill"
            case .unknown: return "questionmark.circle"
            }
        }
    }

    // MARK: - Daily Spend Rate

    /// Calculate the average daily spend rate from daily cost data.
    ///
    /// - Parameter dailyCosts: Array of (date, cost) tuples for each day
    /// - Returns: Average dollars per day, or nil if insufficient data (need at least 2 points)
    static func calculateDailySpendRate(from dailyCosts: [(date: Date, cost: Double)]) -> Double? {
        guard dailyCosts.count >= 2 else { return nil }

        let totalCost = dailyCosts.reduce(0.0) { $0 + $1.cost }
        let count = Double(dailyCosts.count)

        guard count > 0 else { return nil }
        return totalCost / count
    }

    // MARK: - Predicted Monthly Spend

    /// Project total monthly spend based on current spend and daily rate.
    ///
    /// - Parameters:
    ///   - currentSpend: Total dollars spent so far this month
    ///   - dailyRate: Average daily spend rate
    ///   - dayOfMonth: Current day of the month (1-based)
    ///   - daysInMonth: Total days in the current month
    /// - Returns: Projected total spend for the full month
    static func predictedMonthlySpend(
        currentSpend: Double,
        dailyRate: Double,
        dayOfMonth: Int,
        daysInMonth: Int
    ) -> Double {
        currentSpend + dailyRate * Double(daysInMonth - dayOfMonth)
    }

    // MARK: - Pace Indicator Calculation

    /// Determine spending pace relative to the monthly budget.
    ///
    /// - Parameters:
    ///   - currentSpend: Total dollars spent so far this month
    ///   - monthlyBudget: Monthly budget limit in dollars
    ///   - dayOfMonth: Current day of the month (1-based)
    ///   - daysInMonth: Total days in the current month
    /// - Returns: Pace indicator showing if spending is on track, ahead, or behind
    static func paceIndicator(
        currentSpend: Double,
        monthlyBudget: Double,
        dayOfMonth: Int,
        daysInMonth: Int
    ) -> PaceIndicator {
        guard monthlyBudget > 0, daysInMonth > 0, dayOfMonth > 0 else { return .unknown }

        let expectedSpend = (monthlyBudget / Double(daysInMonth)) * Double(dayOfMonth)

        if currentSpend > expectedSpend * 1.10 {
            return .ahead   // Spending faster than budget allows
        } else if currentSpend < expectedSpend * 0.90 {
            return .behind  // Under budget
        } else {
            return .onPace  // Within 10% of expected
        }
    }

    // MARK: - Time to Limit

    /// Calculate how long until the budget limit is reached at the current daily rate.
    ///
    /// - Parameters:
    ///   - currentSpend: Total dollars spent so far
    ///   - monthlyBudget: Monthly budget limit in dollars
    ///   - dailyRate: Average daily spend rate
    /// - Returns: Time interval in seconds until limit, or nil if not approaching
    static func timeToLimit(
        currentSpend: Double,
        monthlyBudget: Double,
        dailyRate: Double
    ) -> TimeInterval? {
        guard dailyRate > 0, currentSpend < monthlyBudget else { return nil }

        let remainingBudget = monthlyBudget - currentSpend
        let daysRemaining = remainingBudget / dailyRate
        return daysRemaining * 86400  // Convert days to seconds
    }

    // MARK: - Formatting

    /// Format a time-to-limit interval as a human-readable string.
    ///
    /// - Parameter seconds: Time interval in seconds
    /// - Returns: Formatted string (e.g., ">30d", "5d 12h", "3h 45m", "30m", "--")
    static func formatTimeToLimit(_ seconds: TimeInterval) -> String {
        guard seconds > 0 else { return "--" }

        let totalSeconds = Int(seconds)
        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60

        if days > 30 {
            return ">30d"
        } else if days >= 1 {
            return "\(days)d \(hours)h"
        } else if hours >= 1 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "--"
        }
    }
}
