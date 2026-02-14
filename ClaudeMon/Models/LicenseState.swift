import Foundation

/// License status state machine with clear transitions.
/// Each state indicates what features are available and what UI to show.
enum LicenseState: Codable, Sendable, Equatable {
    case onTrial(daysRemaining: Int, startDate: Date, endDate: Date)
    case licensed(licenseKey: String, instanceId: String, expiresAt: Date?)
    case trialExpired
    case gracePeriod(daysRemaining: Int, licenseKey: String)
    case unlicensed

    /// Whether Pro features should be enabled
    var isProEnabled: Bool {
        switch self {
        case .onTrial, .licensed, .gracePeriod:
            return true
        case .trialExpired, .unlicensed:
            return false
        }
    }

    /// Display text for settings and status UI
    var displayText: String {
        switch self {
        case .onTrial(let days, _, _):
            return "Trial: \(days) day\(days == 1 ? "" : "s") left"
        case .licensed(_, _, let expires):
            if let exp = expires {
                return "Pro (renews \(exp.formatted(date: .abbreviated, time: .omitted)))"
            }
            return "Pro"
        case .trialExpired:
            return "Trial Expired"
        case .gracePeriod(let days, _):
            return "Renew within \(days) day\(days == 1 ? "" : "s")"
        case .unlicensed:
            return "Free"
        }
    }

    /// Short status for menu bar (only shown when relevant)
    var menuBarSuffix: String? {
        switch self {
        case .onTrial(let days, _, _) where days <= 3:
            return "[\(days)d]"
        case .trialExpired:
            return "[!]"
        case .gracePeriod(let days, _) where days <= 3:
            return "[!\(days)d]"
        default:
            return nil
        }
    }
}

/// Cached license data for persistence
struct CachedLicenseData: Codable, Sendable {
    let state: LicenseState
    let lastValidated: Date
    let licenseKey: String?
    let instanceId: String?
}
