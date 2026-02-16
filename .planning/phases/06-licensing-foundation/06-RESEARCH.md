# Phase 6: Licensing Foundation - Research

**Researched:** 2026-02-14
**Domain:** LemonSqueezy licensing, macOS trial implementation, feature gating
**Confidence:** HIGH

## Summary

LemonSqueezy provides a well-documented License API with three core operations: activate, validate, and deactivate. The `swift-lemon-squeezy-license` package (v1.0.1) wraps this API cleanly for Swift, providing async/await methods and typed response models. The package is lightweight and handles the HTTP layer, leaving storage and business logic to the app.

Trial implementation requires careful Keychain storage (not UserDefaults) to prevent easy bypass. The existing `KeychainAccess` package already in the project supports the necessary accessibility attributes for secure, device-local storage. A grace period implementation is needed since LemonSqueezy's subscription-linked licenses expire immediately when subscriptions end.

The app architecture is well-suited for licensing integration. The existing `UsageMonitor` pattern demonstrates the service-layer approach that `LicenseManager` should follow. The `StatusItemManager` shows how to update menu bar state reactively, which trial status can hook into.

**Primary recommendation:** Create a `LicenseManager` service following the `UsageMonitor` pattern, store trial/license state in Keychain with HMAC verification, and implement a `FeatureAccessManager` for centralized Pro feature gating.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| [swift-lemon-squeezy-license](https://github.com/kevinhermawan/swift-lemon-squeezy-license) | 1.0.1 | LemonSqueezy License API wrapper | Only maintained Swift package for LemonSqueezy licensing |
| [KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess) | 4.2.2 | Secure trial/license storage | Already in project, well-maintained, supports all accessibility levels |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| CryptoKit | Built-in | HMAC for tamper detection | Trial date verification |
| Foundation/URLSession | Built-in | Fallback if package insufficient | Only if package lacks needed features |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| swift-lemon-squeezy-license | Raw URLSession | More control but must handle encoding/decoding manually |
| KeychainAccess | Native Security framework | KeychainAccess already in project, easier API |
| HMAC tamper detection | CocoaFob cryptographic licenses | HMAC is simpler for trial dates; CocoaFob better for offline perpetual licenses |

**Installation:**
```swift
// Package.swift - add to dependencies
.package(url: "https://github.com/kevinhermawan/swift-lemon-squeezy-license.git", from: "1.0.1")

// Add to target dependencies
"LemonSqueezyLicense"
```

## Architecture Patterns

### Recommended Project Structure
```
Tokemon/
├── Services/
│   ├── LicenseManager.swift       # Core licensing logic, API calls, state management
│   ├── FeatureAccessManager.swift # Centralized Pro gating, trial checking
│   └── ... (existing services)
├── Models/
│   ├── LicenseState.swift         # License status enum and cached data
│   └── ... (existing models)
├── Views/
│   ├── Settings/
│   │   └── LicenseSettings.swift  # License key entry, status display
│   ├── Licensing/
│   │   ├── TrialBannerView.swift  # Popover trial status banner
│   │   └── PurchasePromptView.swift # Purchase prompt when trial expires
│   └── ... (existing views)
└── Utilities/
    └── Constants.swift            # Add LemonSqueezy constants
```

### Pattern 1: License State Machine
**What:** Model license status as a state machine with clear transitions
**When to use:** Managing app-wide license state across all features
**Example:**
```swift
// Source: Based on TrialLicensing framework pattern
enum LicenseState: Codable, Sendable {
    case onTrial(daysRemaining: Int, startDate: Date, endDate: Date)
    case licensed(licenseKey: String, instanceId: String, expiresAt: Date?)
    case trialExpired
    case gracePeriod(daysRemaining: Int, licenseKey: String)  // Subscription lapsed
    case unlicensed  // Invalid/deactivated

    var isProEnabled: Bool {
        switch self {
        case .onTrial, .licensed, .gracePeriod:
            return true
        case .trialExpired, .unlicensed:
            return false
        }
    }

    var displayText: String {
        switch self {
        case .onTrial(let days, _, _):
            return "Trial: \(days) days left"
        case .licensed:
            return "Pro"
        case .trialExpired:
            return "Trial Expired"
        case .gracePeriod(let days, _):
            return "Grace: \(days) days"
        case .unlicensed:
            return "Free"
        }
    }
}
```

### Pattern 2: Observable LicenseManager
**What:** Centralized service following UsageMonitor pattern
**When to use:** App-wide license state management
**Example:**
```swift
// Source: Following existing UsageMonitor pattern
@Observable
@MainActor
final class LicenseManager {
    // Published state
    var state: LicenseState = .unlicensed
    var isValidating: Bool = false
    var lastValidated: Date?
    var error: LicenseError?

    // Cached license data (for offline validation)
    @ObservationIgnored
    private var cachedLicense: CachedLicenseData?

    // Callbacks for status item updates
    @ObservationIgnored
    var onStateChanged: ((LicenseState) -> Void)?

    // Constants for LemonSqueezy product verification
    private let expectedStoreId = 12345  // Hard-code your store ID
    private let expectedProductId = 67890  // Hard-code your product ID

    init() {
        loadCachedState()
        Task { await validateOnLaunch() }
    }

    func activateLicense(key: String) async throws { ... }
    func validateLicense() async throws { ... }
    func deactivateLicense() async throws { ... }
}
```

### Pattern 3: FeatureAccessManager for Centralized Gating
**What:** Single source of truth for Pro feature access
**When to use:** Before enabling any Pro-only feature
**Example:**
```swift
// Source: Best practice for feature flags
@Observable
@MainActor
final class FeatureAccessManager {
    private let licenseManager: LicenseManager

    var isPro: Bool {
        licenseManager.state.isProEnabled
    }

    var trialDaysRemaining: Int? {
        if case .onTrial(let days, _, _) = licenseManager.state {
            return days
        }
        return nil
    }

    // Feature-specific checks
    func canAccessMultiAccount() -> Bool { isPro }
    func canAccessAnalytics() -> Bool { isPro }
    func canExportPDF() -> Bool { isPro }

    // For UI: returns whether to show upgrade prompt
    func requiresPurchase(for feature: ProFeature) -> Bool {
        !isPro
    }
}

enum ProFeature {
    case multiAccount
    case extendedHistory
    case export
    case projectBreakdown
}
```

### Pattern 4: Secure Trial Storage with HMAC
**What:** Store trial dates in Keychain with HMAC verification to prevent tampering
**When to use:** Initial trial setup and validation
**Example:**
```swift
// Source: Best practices from Keychain security patterns
struct TrialStorage {
    private let keychain = Keychain(service: "com.yourapp.Tokemon-license")
        .accessibility(.afterFirstUnlockThisDeviceOnly)  // Device-specific, no sync

    private let hmacKey = Data([/* compile-time secret bytes */])

    struct TrialData: Codable {
        let startDate: Date
        let endDate: Date
        let signature: Data  // HMAC of dates
    }

    func startTrial(duration: TimeInterval = 14 * 24 * 60 * 60) throws {
        let start = Date()
        let end = start.addingTimeInterval(duration)

        // Compute HMAC signature
        let message = "\(start.timeIntervalSince1970)|\(end.timeIntervalSince1970)".data(using: .utf8)!
        let signature = HMAC<SHA256>.authenticationCode(for: message, using: SymmetricKey(data: hmacKey))

        let trial = TrialData(startDate: start, endDate: end, signature: Data(signature))
        let encoded = try JSONEncoder().encode(trial)
        try keychain.set(encoded, key: "trial")
    }

    func getTrialState() throws -> (daysRemaining: Int, isValid: Bool)? {
        guard let data = try keychain.getData("trial"),
              let trial = try? JSONDecoder().decode(TrialData.self, from: data) else {
            return nil  // No trial started
        }

        // Verify HMAC
        let message = "\(trial.startDate.timeIntervalSince1970)|\(trial.endDate.timeIntervalSince1970)".data(using: .utf8)!
        let expectedSignature = HMAC<SHA256>.authenticationCode(for: message, using: SymmetricKey(data: hmacKey))

        guard Data(expectedSignature) == trial.signature else {
            return (0, false)  // Tampered
        }

        let remaining = Calendar.current.dateComponents([.day], from: Date(), to: trial.endDate).day ?? 0
        return (max(0, remaining), remaining > 0)
    }
}
```

### Anti-Patterns to Avoid
- **UserDefaults for trial dates:** Trivially bypassed by deleting plist. Use Keychain.
- **Blocking UI on license validation:** Validate async on launch, cache previous state.
- **Hardcoding license keys in binary:** Use runtime validation via LemonSqueezy API.
- **Trusting client-side trial dates alone:** HMAC signature prevents simple date editing.
- **No offline fallback:** Cache last validation result for brief offline periods.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| LemonSqueezy API calls | Custom HTTP client | swift-lemon-squeezy-license | Handles encoding, headers, response parsing |
| Secure storage | File-based storage | KeychainAccess | Hardware-backed encryption, system integration |
| License key format | Custom format/crypto | LemonSqueezy license keys | They handle generation, validation, revocation |
| Subscription billing | In-app payment flow | LemonSqueezy checkout | PCI compliance, tax handling, international billing |
| Customer portal | Account management UI | LemonSqueezy portal URL | They maintain it, just link to it |

**Key insight:** LemonSqueezy handles the complex parts (billing, taxes, subscriptions, customer portal). The app only needs to store keys, validate them, and gate features accordingly.

## Common Pitfalls

### Pitfall 1: No Product ID Verification
**What goes wrong:** Accepting any valid LemonSqueezy license key, even from different products
**Why it happens:** Developers test with any key and forget to add verification
**How to avoid:** Hard-code `store_id` and `product_id` in app, verify against API response
**Warning signs:** Validation succeeds but meta.product_id doesn't match your product

```swift
// Always verify these after activation/validation
guard response.meta?.storeId == Constants.lemonSqueezyStoreId,
      response.meta?.productId == Constants.lemonSqueezyProductId else {
    throw LicenseError.wrongProduct
}
```

### Pitfall 2: Blocking UI During Validation
**What goes wrong:** App hangs on launch while waiting for network validation
**Why it happens:** Synchronous validation in app startup path
**How to avoid:** Cache previous state, validate async, update UI when done
**Warning signs:** App takes 2-3 seconds to show content on launch

```swift
// Good: Show cached state immediately, validate in background
init() {
    self.state = loadCachedState() ?? .unlicensed
    Task { await validateInBackground() }
}
```

### Pitfall 3: No Grace Period for Subscription Lapses
**What goes wrong:** User's subscription fails to renew, app immediately locks out
**Why it happens:** LemonSqueezy expires license instantly when subscription ends
**How to avoid:** Implement 3-7 day grace period, cache last-known-good state
**Warning signs:** Users complain of sudden lockout despite active subscription

```swift
// When validation fails but we had a valid license recently
if case .licensed = cachedState,
   let lastValidated = lastValidatedDate,
   Date().timeIntervalSince(lastValidated) < 7 * 24 * 60 * 60 {
    state = .gracePeriod(daysRemaining: daysUntilGraceExpires, licenseKey: key)
}
```

### Pitfall 4: Storing Instance ID Insecurely
**What goes wrong:** Instance ID exposed, allowing unauthorized deactivation
**Why it happens:** Storing in UserDefaults or logs
**How to avoid:** Store in Keychain alongside license key
**Warning signs:** Users report being deactivated unexpectedly

### Pitfall 5: Not Handling Offline Scenarios
**What goes wrong:** App refuses to work when network unavailable
**Why it happens:** Validation failure treated as invalid license
**How to avoid:** Cache last validation timestamp and result, allow offline for limited time
**Warning signs:** Users complain app doesn't work on planes/underground

```swift
// Allow 7-day offline window for validated licenses
func validateWithOfflineFallback() async -> LicenseState {
    do {
        return try await validateOnline()
    } catch {
        if let cached = cachedValidation,
           Date().timeIntervalSince(cached.timestamp) < 7 * 24 * 60 * 60 {
            return cached.state  // Trust cached state for 7 days
        }
        return .unlicensed
    }
}
```

### Pitfall 6: Confusing Trial Expiry with License Expiry
**What goes wrong:** Mixing up trial-ended state with subscription-expired state
**Why it happens:** Both result in "not licensed" but need different messaging
**How to avoid:** Use distinct enum cases: `.trialExpired` vs `.unlicensed` vs `.gracePeriod`
**Warning signs:** Users who previously purchased see "Start Trial" instead of "Renew"

## Code Examples

### LemonSqueezy Activation
```swift
// Source: swift-lemon-squeezy-license documentation
import LemonSqueezyLicense

func activateLicense(key: String) async throws -> ActivationResult {
    let license = LemonSqueezyLicense()
    let instanceName = Host.current().localizedName ?? "Mac"

    let response = try await license.activate(key: key, instanceName: instanceName)

    // Verify product ownership
    guard response.meta?.storeId == Constants.lemonSqueezyStoreId,
          response.meta?.productId == Constants.lemonSqueezyProductId else {
        throw LicenseError.wrongProduct
    }

    guard response.activated, let instance = response.instance else {
        throw LicenseError.activationFailed(response.error ?? "Unknown error")
    }

    // Store in Keychain
    try storeLicense(key: key, instanceId: instance.id, expiresAt: response.licenseKey?.expiresAt)

    return ActivationResult(
        instanceId: instance.id,
        expiresAt: response.licenseKey?.expiresAt,
        customerEmail: response.meta?.customerEmail
    )
}
```

### LemonSqueezy Validation
```swift
// Source: LemonSqueezy License API docs
func validateLicense() async throws -> Bool {
    guard let (key, instanceId) = try loadStoredLicense() else {
        return false
    }

    let license = LemonSqueezyLicense()
    let response = try await license.validate(key: key, instanceId: instanceId)

    // Check validity
    guard response.valid else {
        // Check if subscription expired (needs grace period)
        if response.licenseKey?.status == "expired" {
            enterGracePeriod(key: key)
            return true  // Allow access during grace
        }
        return false
    }

    // Update cache
    updateValidationCache(validatedAt: Date(), expiresAt: response.licenseKey?.expiresAt)

    return true
}
```

### Trial Banner in Popover
```swift
// Source: Following existing ErrorBannerView pattern
struct TrialBannerView: View {
    let state: LicenseState
    let onPurchase: () -> Void

    var body: some View {
        switch state {
        case .onTrial(let days, _, _):
            HStack {
                Image(systemName: "clock")
                Text("Trial: \(days) days remaining")
                Spacer()
                Button("Upgrade") { onPurchase() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
            .padding(10)
            .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

        case .trialExpired:
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Trial expired")
                Spacer()
                Button("Unlock Pro") { onPurchase() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
            .padding(10)
            .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

        case .gracePeriod(let days, _):
            HStack {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.yellow)
                Text("Subscription lapsed - \(days) days to renew")
                Spacer()
                Button("Renew") { onPurchase() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
            .padding(10)
            .background(Color.yellow.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

        default:
            EmptyView()
        }
    }
}
```

### License Settings Tab
```swift
// Source: Following existing SettingsView tab pattern
struct LicenseSettings: View {
    @Environment(LicenseManager.self) private var licenseManager
    @State private var licenseKeyInput: String = ""
    @State private var isActivating: Bool = false
    @State private var activationError: String?

    var body: some View {
        Form {
            Section("License Status") {
                LabeledContent("Status", value: licenseManager.state.displayText)

                if case .licensed(_, _, let expires) = licenseManager.state,
                   let expiresAt = expires {
                    LabeledContent("Renews", value: expiresAt.formatted(date: .abbreviated, time: .omitted))
                }

                if let lastValidated = licenseManager.lastValidated {
                    LabeledContent("Last verified", value: lastValidated.formatted(date: .abbreviated, time: .shortened))
                }
            }

            Section("Activate License") {
                TextField("License Key", text: $licenseKeyInput)
                    .textFieldStyle(.roundedBorder)

                if let error = activationError {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                Button("Activate") {
                    Task { await activateLicense() }
                }
                .disabled(licenseKeyInput.isEmpty || isActivating)
            }

            Section("Manage Subscription") {
                Link("Manage in LemonSqueezy Portal",
                     destination: URL(string: "https://YOURSTORE.lemonsqueezy.com/billing")!)
                    .foregroundStyle(.blue)
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 400)
    }

    private func activateLicense() async {
        isActivating = true
        activationError = nil
        defer { isActivating = false }

        do {
            try await licenseManager.activateLicense(key: licenseKeyInput.trimmingCharacters(in: .whitespaces))
            licenseKeyInput = ""
        } catch {
            activationError = error.localizedDescription
        }
    }
}
```

### Opening LemonSqueezy Checkout
```swift
// Source: Standard macOS URL opening pattern
func openPurchasePage() {
    // Direct checkout link format from LemonSqueezy
    let checkoutURL = URL(string: "https://YOURSTORE.lemonsqueezy.com/buy/YOUR_PRODUCT_ID")!
    NSWorkspace.shared.open(checkoutURL)
}

// For customer portal (signed URL approach - requires backend)
// Since this is a standalone app without backend, use unsigned URL
func openCustomerPortal() {
    let portalURL = URL(string: "https://YOURSTORE.lemonsqueezy.com/billing")!
    NSWorkspace.shared.open(portalURL)
}
```

### Menu Bar Trial Status Display
```swift
// Source: Following existing StatusItemManager pattern
extension StatusItemManager {
    func updateWithLicenseState(_ licenseState: LicenseState, usage: UsageSnapshot, error: UsageMonitor.MonitorError?, alertLevel: AlertManager.AlertLevel) {
        guard let button = statusItem?.button else { return }

        var text = usage.menuBarText
        var color: NSColor

        // Add trial indicator if applicable
        if case .onTrial(let days, _, _) = licenseState {
            // Show trial badge only if <= 3 days remaining
            if days <= 3 {
                text = "\(text) [\(days)d]"
            }
        }

        // ... rest of existing color logic ...
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| CocoaFob cryptographic licenses | LemonSqueezy subscription licenses | 2023+ | Simpler, handles billing/refunds/cancellation |
| UserDefaults for trial | Keychain with HMAC | Always | Security requirement for paid software |
| Synchronous validation on launch | Async with cached state | Always | Better UX, no launch delays |
| Single perpetual license | Subscription with grace period | Business decision | Recurring revenue, continuous updates |

**Deprecated/outdated:**
- **Sparkle license validation**: Was popular but LemonSqueezy handles this better
- **Serial number entry**: UUID license keys are more user-friendly
- **App Store receipt validation**: Not applicable (not on App Store)

## Open Questions

1. **Grace period duration**
   - What we know: LemonSqueezy has no built-in grace period for subscriptions
   - What's unclear: Optimal duration (3 days? 7 days?)
   - Recommendation: Start with 7 days, can adjust based on user feedback

2. **Trial bypass detection**
   - What we know: HMAC prevents simple date editing, Keychain prevents plist deletion
   - What's unclear: How to handle reinstalls (Keychain may persist)
   - Recommendation: Accept that persistent Keychain allows re-trial after reinstall; this is acceptable for honest users

3. **Offline validation window**
   - What we know: Need to allow some offline usage
   - What's unclear: How long is reasonable?
   - Recommendation: 7 days for licensed users, trial doesn't need offline (always first install)

4. **Customer portal signed URL**
   - What we know: Signed URLs auto-login but require API call to generate
   - What's unclear: Without backend, cannot get signed URL
   - Recommendation: Use unsigned portal URL; user enters email for magic link auth

## Sources

### Primary (HIGH confidence)
- [LemonSqueezy License API Documentation](https://docs.lemonsqueezy.com/api/license-api) - Endpoint specs, request/response format
- [LemonSqueezy Activate Endpoint](https://docs.lemonsqueezy.com/api/license-api/activate-license-key) - Activation parameters and response
- [LemonSqueezy Validate Endpoint](https://docs.lemonsqueezy.com/api/license-api/validate-license-key) - Validation flow and status codes
- [swift-lemon-squeezy-license GitHub](https://github.com/kevinhermawan/swift-lemon-squeezy-license) - Package usage examples
- [LemonSqueezy License Key Object](https://docs.lemonsqueezy.com/api/license-keys/the-license-key-object) - Status values, attributes
- [KeychainAccess Source](https://github.com/kishikawakatsumi/KeychainAccess) - Already in project, accessibility options

### Secondary (MEDIUM confidence)
- [LemonSqueezy License Keys and Subscriptions](https://docs.lemonsqueezy.com/help/licensing/license-keys-subscriptions) - Subscription-license relationship
- [LemonSqueezy Customer Portal Guide](https://docs.lemonsqueezy.com/guides/developer-guide/customer-portal) - Portal URL format
- [TrialLicensing Framework](https://github.com/CleanCocoa/TrialLicensing) - macOS trial patterns (reference only)
- [SwiftRocks License System Article](https://swiftrocks.com/creating-a-license-system-for-paid-apps-in-swift) - Cryptographic signing concepts

### Tertiary (LOW confidence)
- WebSearch results for offline caching patterns - General guidance, not LemonSqueezy-specific

## Integration Points with Existing Codebase

### TokemonApp.swift
- Add `LicenseManager` and `FeatureAccessManager` as `@State` properties alongside `UsageMonitor`
- Pass to views via `.environment()`
- Wire `onStateChanged` callback similar to `onUsageChanged`

### StatusItemManager
- Add license state parameter to `update(with:error:alertLevel:licenseState:)` method
- Show trial days remaining in menu bar when <= 3 days

### PopoverContentView
- Add `TrialBannerView` above or below usage header based on license state
- Inject via `@Environment(FeatureAccessManager.self)`

### SettingsView
- Add new `LicenseSettings` tab with SF Symbol "key.fill" or "creditcard.fill"
- Place after Alerts tab, before Admin API tab

### Constants.swift
- Add LemonSqueezy constants: `storeId`, `productId`, `checkoutURL`, `portalURL`

### Package.swift
- Add swift-lemon-squeezy-license dependency

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - LemonSqueezy docs are comprehensive, package is simple
- Architecture: HIGH - Following existing patterns in codebase
- Pitfalls: HIGH - Well-documented in LemonSqueezy guides and common practice
- Trial security: MEDIUM - HMAC approach is sound but determined attackers can bypass

**Research date:** 2026-02-14
**Valid until:** 2026-03-14 (LemonSqueezy API is stable, package is new but simple)
