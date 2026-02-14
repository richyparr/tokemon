# Domain Pitfalls: v2 Pro Features

**Domain:** Adding licensing, multi-account, PDF reports, and trials to existing macOS menu bar app
**Researched:** 2026-02-14
**Confidence:** MEDIUM-HIGH (LemonSqueezy API verified against official docs; Keychain patterns verified across multiple Swift sources; trial/licensing patterns verified via community frameworks)

---

## Critical Pitfalls

Mistakes that cause rewrites, user trust issues, or feature failure.

### Pitfall 1: LemonSqueezy License API is Separate from Main API

**What goes wrong:**
Developers assume LemonSqueezy has one unified API. In reality, the License API (`api.lemonsqueezy.com/v1/licenses/*`) is completely separate from the main Lemon Squeezy API and has different requirements. Using the wrong API, wrong auth method, or wrong Content-Type causes silent failures or cryptic errors.

**Why it happens:**
The main Lemon Squeezy API uses Bearer token auth and JSON request bodies. The License API uses `Content-Type: application/x-www-form-urlencoded` and no auth header (the license key itself is the credential). Developers copy-paste patterns from the wrong API.

**Consequences:**
- License validation always fails with 400/401 errors
- Users cannot activate the app
- Time wasted debugging auth when the issue is Content-Type

**Prevention:**
- Use the dedicated Swift package [swift-lemon-squeezy-license](https://github.com/kevinhermawan/swift-lemon-squeezy-license) which handles these differences
- If implementing manually, explicitly set:
  - `Content-Type: application/x-www-form-urlencoded`
  - `Accept: application/json`
  - No Authorization header (license key goes in request body)
- Test against the actual License API endpoints, not the main API docs

**Detection:**
- 400 Bad Request on license validation calls
- JSON parsing errors (response format differs from main API)
- Integration works in Postman but fails in app (Content-Type mismatch)

**Phase to address:** Licensing Phase -- use the Swift package from day one; don't hand-roll the API client.

**Confidence:** HIGH -- verified against [LemonSqueezy License API docs](https://docs.lemonsqueezy.com/api/license-api)

---

### Pitfall 2: License Keys Tied to Subscription Status Without Grace Period Handling

**What goes wrong:**
With subscription-based licensing in LemonSqueezy, the license key expires the moment the subscription ends -- not when the user requests cancellation, but when the billing cycle ends or payment retries are exhausted. Developers assume there's a buffer period. There isn't. The user's app instantly downgrades to free tier.

**Why it happens:**
LemonSqueezy's subscription-license coupling means "the license key will remain active as long as the subscription is active" and expires simultaneously when the subscription terminates. Unlike Apple's 16-day billing grace period for App Store subscriptions, LemonSqueezy has no built-in grace period.

**Consequences:**
- User forgets to update payment method, loses Pro features mid-work
- User gets angry 1-star review because "app suddenly stopped working"
- Support tickets flood in around billing dates

**Prevention:**
- Implement your own grace period: when license validation returns expired, give users 3-7 days of continued access while showing a warning
- Cache the last-known-valid license status locally (in Keychain, encrypted) with a "grace_until" timestamp
- Send proactive notifications when subscription is about to expire (use webhook `subscription_payment_failed` event)
- On grace period expiration, downgrade gracefully to free tier rather than hard-locking the app

**Detection:**
- User reports "Pro features disappeared without warning"
- Support tickets spike on 1st/15th of month (common billing dates)
- Analytics show users churning immediately after payment failures

**Phase to address:** Licensing Phase -- design grace period logic before implementing license checks.

**Confidence:** HIGH -- verified via [LemonSqueezy License Keys and Subscriptions docs](https://docs.lemonsqueezy.com/help/licensing/license-keys-subscriptions)

---

### Pitfall 3: Keychain Credential Update Fails Silently with errSecDuplicateItem

**What goes wrong:**
When storing OAuth credentials for multiple accounts, `SecItemAdd` fails with `errSecDuplicateItem` (-25299) if an item already exists for that service+account combination. Developers don't handle this error, so credential updates silently fail. The user re-authenticates, but the old (possibly expired) token remains in Keychain. OAuth refreshes then fail repeatedly.

**Why it happens:**
`SecItemAdd` is add-only. To update, you must catch `errSecDuplicateItem`, then call `SecItemUpdate` with a separate attributes dictionary. Many developers assume "add or update" is a single operation.

**Consequences:**
- OAuth token refresh fails because old token is stuck in Keychain
- Users must manually run `/login` multiple times per day (as seen in [claude-code issue #19456](https://github.com/anthropics/claude-code/issues/19456))
- Multi-account switching appears to work but silently corrupts credentials

**Prevention:**
```swift
// Correct pattern: Add-or-Update
let addStatus = SecItemAdd(query as CFDictionary, nil)
if addStatus == errSecDuplicateItem {
    let updateQuery: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: serviceName,
        kSecAttrAccount as String: accountIdentifier
    ]
    let updateAttributes: [String: Any] = [
        kSecValueData as String: tokenData
    ]
    let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
    // Handle updateStatus
}
```
- Use a Keychain wrapper library like [KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess) that handles this automatically
- Unit test credential update flows, not just initial storage

**Detection:**
- OAuth refresh succeeds server-side but app still uses old token
- Users report needing to re-authenticate repeatedly
- Debug logs show `errSecDuplicateItem` being silently ignored

**Phase to address:** Multi-Account Phase -- implement correct Keychain update pattern before any OAuth flow.

**Confidence:** HIGH -- verified via [Apple Developer Forums thread on SecItemUpdate](https://developer.apple.com/forums/thread/107339) and [Swift Keychain examples](https://swiftsenpai.com/development/persist-data-using-keychain/)

---

### Pitfall 4: Multi-Account Keychain Items Collide Without Unique Account Identifiers

**What goes wrong:**
When adding multi-account support, developers use a single `kSecAttrAccount` value (like "oauth_token") for all accounts. Keychain items are uniquely identified by (service + account). With identical account values, the second account's credentials overwrite the first.

**Why it happens:**
The app started as single-account, with hardcoded account identifiers. Adding multi-account without changing the Keychain schema causes collisions.

**Consequences:**
- Only one account's credentials are stored at a time
- Switching accounts appears to work but loads wrong credentials
- Users lose access to their secondary accounts

**Prevention:**
- Use a unique identifier per account in `kSecAttrAccount`: email, user ID, or a UUID assigned at auth time
- Store a mapping of account identifiers separately (UserDefaults is fine for the ID list, not for credentials)
- Migration: on first launch after update, detect single-account items and rename them with the user's identifier

```swift
// Multi-account pattern
let keychainAccount = "oauth_\(user.id)"  // Unique per user
let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrService as String: "com.yourapp.oauth",
    kSecAttrAccount as String: keychainAccount,  // User-specific
    kSecValueData as String: tokenData
]
```

**Detection:**
- Adding second account "forgets" first account
- Account list shows multiple accounts but all resolve to same credentials
- OAuth errors reference wrong user after account switch

**Phase to address:** Multi-Account Phase -- design Keychain schema for multi-account before implementing account list UI.

**Confidence:** HIGH -- verified via [Medium article on multi-account Keychain](https://medium.com/@leekiereloo/seamlessly-manage-multiple-user-accounts-in-ios-with-keychain-9ed080638a25)

---

### Pitfall 5: Trial Period Based on Local Clock is Trivially Bypassable

**What goes wrong:**
Trial implementation stores the trial start date in UserDefaults or a local file and compares against `Date()`. Users bypass this by:
1. Setting system clock back
2. Deleting the app's container/preferences
3. Using tools like "RunAsDate" that freeze the app's clock

**Why it happens:**
Server-side trial validation requires infrastructure. Local-only trials are easier to implement. Developers underestimate how many users will cheat.

**Consequences:**
- Unlimited free trials for savvy users
- Paying users see non-paying users getting same features, feel cheated
- Revenue loss

**Prevention:**
- **Hybrid validation**: Store trial start date locally AND validate against server (LemonSqueezy can track this via instance metadata)
- **Hardware-anchored identifier**: Use a device identifier (serial number hash) that persists across reinstalls
- **NTP-verified time**: Check against network time on first launch and when trial is about to expire; if system clock is more than 24 hours behind NTP time, flag as suspicious
- **Grace, not hard block**: If clock manipulation is detected, don't accusatorily lock the app. Show "Unable to verify trial status -- please check your internet connection" and allow limited use

Example using TrialLicensing framework pattern:
```swift
// Store trial in Keychain (harder to delete than UserDefaults)
// Include device identifier hash
// Validate against NTP time periodically
```

**Detection:**
- Trial start date is in the future
- System clock is significantly behind network time
- User has "reinstalled" multiple times (tracked via hardware ID)

**Phase to address:** Trial Phase -- implement server-validated trial from the start; don't add it later.

**Confidence:** MEDIUM -- patterns verified via [TrialLicensing framework](https://github.com/CleanCocoa/TrialLicensing) and trial bypass tools like [RunAsDate](https://github.com/babysofthack/mac-trial-reset)

---

### Pitfall 6: Feature Gating Logic Scattered Throughout Codebase

**What goes wrong:**
Developers add `if isPro { ... }` checks in dozens of places: views, view models, services, and API calls. When licensing logic needs to change (new tier, grace period, feature unlock), every check must be found and updated. Bugs emerge from inconsistent checks.

**Why it happens:**
It's the path of least resistance when adding a single Pro feature. By the time there are 10 features, the pattern is established and hard to refactor.

**Consequences:**
- Grace period implemented in some checks but not others
- New features forget to add Pro check
- Subscription status cached differently in different places, causing inconsistent behavior
- Testing requires manually checking every gated feature

**Prevention:**
- Create a centralized `FeatureAccessManager` that is the single source of truth:
```swift
enum Feature {
    case multiAccount
    case pdfReports
    case prioritySupport
    case advancedAnalytics
}

class FeatureAccessManager {
    static let shared = FeatureAccessManager()

    func canAccess(_ feature: Feature) -> Bool {
        let license = LicenseManager.shared.currentStatus
        switch (feature, license) {
        case (_, .pro): return true
        case (_, .trial): return true  // All features in trial
        case (_, .grace): return true  // Grace period = temporary pro
        case (.multiAccount, .free): return false
        // etc.
        }
    }

    func gatedAction(_ feature: Feature, action: () -> Void, fallback: () -> Void) {
        if canAccess(feature) { action() } else { fallback() }
    }
}
```
- Use SwiftUI environment injection for reactive updates
- Views subscribe to feature access changes, not raw license status

**Detection:**
- Searching for "isPro" or license status finds 20+ call sites
- Grace period works for some features but not others
- QA reports "this feature is locked but that one isn't" after subscription change

**Phase to address:** Licensing Phase -- implement `FeatureAccessManager` before adding any feature gates.

**Confidence:** HIGH -- standard pattern from [Feature flags in Swift](https://www.swiftbysundell.com/articles/feature-flags-in-swift/)

---

### Pitfall 7: PDF Generation Fails on macOS Without UIKit

**What goes wrong:**
Developers follow iOS PDF generation tutorials that use `UIGraphicsPDFRenderer` or `UIGraphicsBeginPDFContext`. These are UIKit APIs. On macOS, UIKit is not available. The code compiles against Catalyst but fails on native macOS, or doesn't compile at all.

**Why it happens:**
Most Swift PDF tutorials target iOS. macOS has different APIs (`NSPrintOperation`, `PDFDocument`/`PDFPage` from PDFKit, or Core Graphics directly). Search results for "Swift PDF generation" are iOS-heavy.

**Consequences:**
- Code that works in iOS mode fails when building for native macOS
- Last-minute scramble to rewrite PDF generation
- Charts and complex layouts are harder without UIKit's graphics context

**Prevention:**
- Use PDFKit's `PDFDocument` and `PDFPage` APIs which work on both platforms
- For rendering SwiftUI views to PDF on macOS:
  - Use `ImageRenderer` (macOS 13+) to render view to image, then add to PDF page
  - Or use `NSHostingView` to render SwiftUI, then draw to Core Graphics PDF context
- Use cross-platform library like [TPPDF](https://github.com/techprimate/TPPDF) for complex reports

Example macOS-native approach:
```swift
import PDFKit

func generateReport() -> PDFDocument {
    let pdf = PDFDocument()

    // Create PDF page with content
    let page = PDFPage()
    // ... configure page
    pdf.insert(page, at: 0)

    return pdf
}
```

**Detection:**
- Build errors mentioning `UIGraphicsRenderer` unavailable on macOS
- Crash at runtime when PDF generation runs on native macOS
- PDF works in Catalyst but not native macOS target

**Phase to address:** PDF Reports Phase -- choose macOS-native PDF approach before implementing.

**Confidence:** HIGH -- verified via [Swift Forums discussion on macOS PDF generation](https://forums.swift.org/t/creating-pdfs-on-macos-without-uikit/54968) and [TPPDF library](https://github.com/techprimate/TPPDF)

---

### Pitfall 8: Webhook-Based License Status is Unreliable Without Fallback

**What goes wrong:**
The app relies solely on LemonSqueezy webhooks to update license status. When a user upgrades/downgrades/renews, the webhook notifies the app's backend, which updates the user's status. But:
- Webhooks can be blocked by firewalls (Cloudflare blocks LemonSqueezy IPs)
- Webhooks can fail silently if endpoint returns non-200
- Webhook retries only happen 3 times (5s, 25s, 125s), then give up

**Why it happens:**
Webhooks feel like real-time updates. Developers assume they're reliable. They're not -- they're "mostly reliable with edge cases."

**Consequences:**
- User pays, but app still shows "Free" tier
- Subscription renewal not reflected for hours/days
- Support tickets: "I paid but I don't have Pro"

**Prevention:**
- **Validate license on app launch**: Always call LemonSqueezy's `/validate` endpoint on startup
- **Validate periodically**: Re-validate every 24 hours while app is running
- **Validate on user action**: When user clicks "Restore Purchase" or opens Settings
- **Webhook as optimization**: Use webhooks to push updates faster, but never trust them as the only source
- **Local caching**: Cache the last validated status with a timestamp; show cached status if validation fails (network down)

```swift
// Layered license checking
class LicenseManager {
    func refreshStatus() async {
        // Try API validation first
        if let status = try? await validateWithLemonSqueezy() {
            self.cachedStatus = status
            self.cachedAt = Date()
            return
        }

        // Fall back to cached status if recent enough
        if let cached = cachedStatus,
           let cachedAt = cachedAt,
           Date().timeIntervalSince(cachedAt) < 86400 {
            return  // Use cached status
        }

        // Grace: if we can't validate and cache is stale, assume valid temporarily
        // (Better UX than locking out paying customer due to network issues)
    }
}
```

**Detection:**
- User upgrades but status doesn't change
- License status is inconsistent between devices
- Backend logs show webhook delivery failures

**Phase to address:** Licensing Phase -- design validate-on-launch from day one; don't rely solely on webhooks.

**Confidence:** HIGH -- verified via [LemonSqueezy Webhook docs](https://docs.lemonsqueezy.com/help/webhooks) showing retry limits and [Cloudflare blocking issue](https://community.cloudflare.com/t/cloudflare-is-blocking-lemon-squeezy-webhook/807437)

---

### Pitfall 9: License Validation Rate Limits Block High-Usage Patterns

**What goes wrong:**
LemonSqueezy License API is rate limited to 60 requests per minute. If the app validates license on every feature access, or validates too frequently during debugging, the API returns 429 errors. The app interprets this as "license invalid" and downgrades the user.

**Why it happens:**
Rate limits aren't considered during development. Debugging involves rapid restarts. Production code validates too often "just to be safe."

**Consequences:**
- Users randomly lose Pro features during heavy use
- Debug builds constantly downgrade to free tier
- API integration appears unreliable when it's just rate-limited

**Prevention:**
- Cache license status locally for 24 hours minimum
- Validate only on: app launch, user-initiated "Check License" action, and after purchase flow
- Never validate on feature access -- use cached status
- Handle 429 explicitly: don't treat as invalid license, retain current status, schedule retry with exponential backoff
- Log rate limit hits for monitoring

```swift
// Rate limit handling
if response.statusCode == 429 {
    // DON'T invalidate license
    // DO schedule retry in 60 seconds
    // DO continue using cached status
    scheduleRetry(delay: 60)
    return .useCachedStatus
}
```

**Detection:**
- Users report "features flickering" between Pro and Free
- Backend logs show 429 responses from LemonSqueezy
- Issue happens more to power users who restart frequently

**Phase to address:** Licensing Phase -- implement caching and rate limit handling before any license checks.

**Confidence:** HIGH -- rate limit documented at [LemonSqueezy License API docs](https://docs.lemonsqueezy.com/api/license-api)

---

### Pitfall 10: Device Activation Limit UX is Hostile Without Deactivation Flow

**What goes wrong:**
LemonSqueezy licenses can have activation limits (e.g., 3 devices). Users hit the limit, get an error "Activation limit reached," and have no way to deactivate old devices from the app. They email support, who manually deactivates. This happens repeatedly.

**Why it happens:**
Developers implement activation but not deactivation. They assume users won't hit the limit, or that manual support intervention is acceptable.

**Consequences:**
- Frustrated users who just want to use the app they paid for
- Support burden for trivial deactivation requests
- Users creating multiple accounts to work around limits

**Prevention:**
- Implement in-app deactivation: show list of activated devices, allow user to deactivate old ones
- Store instance IDs returned from activation to enable targeted deactivation
- On activation failure, show which devices are active and offer to deactivate one
- Consider "auto-deactivate oldest" option for users who frequently switch devices

```swift
// Activation response includes instance_id
let activation = try await LemonSqueezy.activate(key: licenseKey, instanceName: "MacBook Pro (work)")
// Store instance_id for later deactivation
self.instanceId = activation.instanceId

// Later, to deactivate:
try await LemonSqueezy.deactivate(key: licenseKey, instanceId: oldInstanceId)
```

**Detection:**
- Support emails about "can't activate, hit limit"
- Users with 3+ accounts for same email
- Activation success rate drops over time

**Phase to address:** Licensing Phase -- implement deactivation UI alongside activation, not as an afterthought.

**Confidence:** HIGH -- activation limits documented, patterns from [Keyforge licensing blog](https://keyforge.dev/blog/how-to-license-mac-app)

---

## Moderate Pitfalls

Issues that cause friction but are recoverable.

### Pitfall 11: PDF Reports Include Sensitive Session Content

**What goes wrong:**
PDF reports for usage analytics accidentally include session content (prompts, responses) from the JSONL parsing. User shares PDF with colleague, exposing proprietary code they were discussing with Claude.

**Prevention:**
- PDF reports show ONLY: token counts, timestamps, cost estimates, aggregate statistics
- Never include message content, even truncated
- Add a warning if any content fields are detected in the report data model

**Phase to address:** PDF Reports Phase -- define report data model before building export.

---

### Pitfall 12: Multi-Account Picker Defaults to Wrong Account After Migration

**What goes wrong:**
Single-account users upgrade to multi-account version. The app migrates their credentials but doesn't set a default account. On next launch, no account is selected, and the app appears logged out.

**Prevention:**
- Migration sets the existing account as default/active
- Account picker always has a selection (even if "none")
- First account added is automatically set as default

**Phase to address:** Multi-Account Phase -- include migration flow in acceptance criteria.

---

### Pitfall 13: Trial Start Timestamp Not Stored in Keychain

**What goes wrong:**
Trial start date stored in UserDefaults. User clears preferences (or clean installs macOS with same user account). Trial resets, giving unlimited trials.

**Prevention:**
- Store trial metadata in Keychain (survives preference resets)
- Include a device-specific identifier that persists across reinstalls
- Server-side trial tracking as ultimate source of truth

**Phase to address:** Trial Phase -- design storage strategy before implementation.

---

### Pitfall 14: License Check Blocks App Launch

**What goes wrong:**
App validates license synchronously on launch. Network is slow or unavailable. App appears to hang for 30 seconds, then either crashes (timeout) or launches with wrong status.

**Prevention:**
- Launch with cached status immediately (show stale data)
- Validate async in background
- Update UI when validation completes
- Never block main thread for network calls

**Phase to address:** Licensing Phase -- design async validation from the start.

---

### Pitfall 15: No Offline License Validation Fallback

**What goes wrong:**
User has valid Pro subscription. They get on a flight (no internet). App tries to validate license, fails, downgrades to free tier. User can't use Pro features they paid for while offline.

**Prevention:**
- Cache validated license for 7+ days
- Offline = use cached status
- Only downgrade if cache is very stale (30+ days) AND user was online recently AND validation failed
- Consider cryptographically signed license tokens that can be validated offline

**Phase to address:** Licensing Phase -- define offline behavior in requirements.

**Confidence:** MEDIUM -- patterns from [Keygen offline validation example](https://github.com/keygen-sh/example-python-offline-validation-caching)

---

## Minor Pitfalls

Issues that are annoying but have straightforward fixes.

### Pitfall 16: PDF Export Saves to Desktop Without Asking

**What goes wrong:**
User clicks "Export PDF" and file silently saves to ~/Desktop. User expects a save dialog.

**Prevention:**
- Always show `NSSavePanel` for user to choose location
- Remember last-used location for convenience
- Respect user's choice, don't assume Desktop

---

### Pitfall 17: Account Switcher Doesn't Update Menu Bar Display

**What goes wrong:**
User switches from Account A to Account B. Menu bar still shows Account A's stats until manual refresh or app restart.

**Prevention:**
- Account switch triggers full data refresh
- Menu bar observes current account state reactively
- Visual confirmation that account switched (brief indicator)

---

### Pitfall 18: Trial Countdown Shows Negative Days

**What goes wrong:**
Trial expired 3 days ago. UI shows "Trial: -3 days remaining" instead of "Trial Expired."

**Prevention:**
- Clamp countdown to minimum of 0
- Distinct UI state for "expired" vs "active"
- Test with expired trial dates, not just active ones

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| LemonSqueezy Integration | Wrong API (main vs license) | Use swift-lemon-squeezy-license package |
| LemonSqueezy Integration | Rate limiting on validation | Cache status 24+ hours, handle 429 |
| LemonSqueezy Integration | No grace period built-in | Implement your own 3-7 day grace |
| Multi-Account OAuth | Keychain credential collision | Unique kSecAttrAccount per user |
| Multi-Account OAuth | Update vs Add confusion | Use KeychainAccess wrapper or proper error handling |
| Trial Implementation | Clock manipulation bypass | Server-side validation + NTP checks |
| Trial Implementation | Preference deletion resets trial | Store in Keychain, not UserDefaults |
| PDF Generation | UIKit APIs on macOS | Use PDFKit or TPPDF |
| PDF Generation | Including sensitive content | Define data model with only metadata |
| Feature Gating | Scattered isPro checks | Centralized FeatureAccessManager |
| Feature Gating | Grace period inconsistency | Single source of truth for status |

---

## "Looks Done But Isn't" Checklist: v2 Features

- [ ] **License Validation:** Handles 429 rate limit without downgrading user
- [ ] **License Validation:** Works offline using cached status
- [ ] **License Validation:** Grace period continues access after expiration
- [ ] **Webhooks:** Fallback validation exists if webhook never arrives
- [ ] **Device Activation:** Deactivation UI implemented, not just activation
- [ ] **Multi-Account:** Keychain uses unique account identifier per user
- [ ] **Multi-Account:** Credential update handles errSecDuplicateItem
- [ ] **Multi-Account:** Migration from single-account sets default
- [ ] **Trial:** Start date stored in Keychain, not just UserDefaults
- [ ] **Trial:** Server-side or NTP validation prevents clock manipulation
- [ ] **Trial:** Expired state handled distinctly from active
- [ ] **Feature Gating:** Centralized FeatureAccessManager, not scattered checks
- [ ] **Feature Gating:** Grace period applied consistently to all features
- [ ] **PDF Export:** Uses macOS-native APIs (PDFKit), not UIKit
- [ ] **PDF Export:** Contains only metadata, no session content
- [ ] **PDF Export:** Shows NSSavePanel, doesn't auto-save to Desktop

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Wrong LemonSqueezy API used | LOW | Swap to correct API endpoints; swift-lemon-squeezy-license handles this |
| No grace period implemented | MEDIUM | Add grace logic to FeatureAccessManager; cache last-valid status with grace timestamp |
| Keychain credentials colliding | HIGH | Migration to add user IDs to existing items; may need to prompt re-auth |
| Trial stored in UserDefaults | MEDIUM | Migrate to Keychain on next launch; accept that some users got free resets |
| Clock manipulation not prevented | LOW | Add NTP checks; server-side validation; accept this is anti-piracy theater |
| Feature checks scattered | HIGH | Major refactor to centralize; add comprehensive tests to ensure consistency |
| PDF uses UIKit | MEDIUM | Rewrite with PDFKit/TPPDF; same business logic, different rendering |
| Webhook-only license updates | MEDIUM | Add validate-on-launch; implement local caching with timestamps |
| Rate limit downgrades users | LOW | Add 429 handling to retain cached status; schedule retries |
| Device limit blocks users | MEDIUM | Add deactivation UI; may need to increase limits for existing users |

---

## Sources

- [LemonSqueezy License API](https://docs.lemonsqueezy.com/api/license-api) -- HIGH confidence
- [LemonSqueezy License Keys and Subscriptions](https://docs.lemonsqueezy.com/help/licensing/license-keys-subscriptions) -- HIGH confidence
- [LemonSqueezy Webhooks](https://docs.lemonsqueezy.com/help/webhooks) -- HIGH confidence
- [swift-lemon-squeezy-license package](https://github.com/kevinhermawan/swift-lemon-squeezy-license) -- HIGH confidence
- [Keychain SecItemUpdate pattern](https://developer.apple.com/forums/thread/107339) -- HIGH confidence
- [Multi-account Keychain pattern](https://medium.com/@leekiereloo/seamlessly-manage-multiple-user-accounts-in-ios-with-keychain-9ed080638a25) -- MEDIUM confidence
- [Claude Code OAuth Keychain issue #19456](https://github.com/anthropics/claude-code/issues/19456) -- HIGH confidence (real-world example of this pitfall)
- [TrialLicensing Swift framework](https://github.com/CleanCocoa/TrialLicensing) -- MEDIUM confidence
- [Trial bypass tools](https://github.com/babysofthack/mac-trial-reset) -- MEDIUM confidence (demonstrates vulnerability)
- [Feature flags in Swift](https://www.swiftbysundell.com/articles/feature-flags-in-swift/) -- HIGH confidence
- [macOS PDF generation without UIKit](https://forums.swift.org/t/creating-pdfs-on-macos-without-uikit/54968) -- HIGH confidence
- [TPPDF library](https://github.com/techprimate/TPPDF) -- HIGH confidence
- [Keygen offline validation](https://github.com/keygen-sh/example-python-offline-validation-caching) -- MEDIUM confidence
- [Keyforge macOS licensing blog](https://keyforge.dev/blog/how-to-license-mac-app) -- MEDIUM confidence
- [Cloudflare blocking LemonSqueezy webhooks](https://community.cloudflare.com/t/cloudflare-is-blocking-lemon-squeezy-webhook/807437) -- HIGH confidence

---
*Pitfalls research for: ClaudeMon v2 Pro Features*
*Domain: Adding licensing, multi-account, PDF reports, and trials to existing macOS menu bar app*
*Researched: 2026-02-14*
