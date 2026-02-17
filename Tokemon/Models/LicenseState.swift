import Foundation

/// License status - simple Free or Pro model.
enum LicenseState: Codable, Sendable, Equatable {
    case free
    case pro(licenseKey: String, instanceId: String, expiresAt: Date?)

    /// Whether Pro features should be enabled
    var isProEnabled: Bool {
        switch self {
        case .pro:
            return true
        case .free:
            return false
        }
    }

    /// Display text for settings and status UI
    var displayText: String {
        switch self {
        case .pro(_, _, let expires):
            if let exp = expires {
                return "Pro (renews \(exp.formatted(date: .abbreviated, time: .omitted)))"
            }
            return "Pro"
        case .free:
            return "Free"
        }
    }

    /// Short status for menu bar (not shown for simple free/pro)
    var menuBarSuffix: String? {
        return nil
    }
}

/// Cached license data for persistence
struct CachedLicenseData: Codable, Sendable {
    let state: LicenseState
    let lastValidated: Date
    let licenseKey: String?
    let instanceId: String?
}
