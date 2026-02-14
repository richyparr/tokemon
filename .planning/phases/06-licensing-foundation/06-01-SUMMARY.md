---
phase: 06-licensing-foundation
plan: 01
subsystem: licensing
tags: [lemonsqueezy, keychain, hmac, cryptokit, trial, subscription]

# Dependency graph
requires:
  - phase: 01-core-monitoring
    provides: "UsageMonitor pattern, KeychainAccess dependency, Constants.swift"
provides:
  - "LicenseManager service with @Observable @MainActor pattern"
  - "LicenseState enum with 5-state machine"
  - "LicenseStorage actor with HMAC-signed trial data"
  - "LemonSqueezyLicense package dependency"
  - "Licensing constants in Constants.swift"
affects: [06-02, 06-03, 07-multi-account, 08-analytics-export]

# Tech tracking
tech-stack:
  added: [swift-lemon-squeezy-license v1.0.1]
  patterns: [actor-based storage, HMAC trial verification, @preconcurrency import for Swift 6]

key-files:
  created:
    - ClaudeMon/Models/LicenseState.swift
    - ClaudeMon/Services/LicenseStorage.swift
    - ClaudeMon/Services/LicenseManager.swift
  modified:
    - Package.swift
    - Package.resolved
    - ClaudeMon/Utilities/Constants.swift

key-decisions:
  - "Used @preconcurrency import for LemonSqueezyLicense to handle Swift 6 Sendable compliance"
  - "Used .product(name:package:) syntax for SPM dependency resolution"
  - "Adapted error handling to match actual LemonSqueezyLicense API (thrown errors, not response.error)"
  - "Used enum status comparison (.expired) instead of string comparison for type safety"

patterns-established:
  - "Actor-based secure storage: LicenseStorage uses actor isolation for thread-safe Keychain access"
  - "HMAC trial verification: Trial dates signed with CryptoKit HMAC-SHA256 to detect tampering"
  - "License state machine: 5-state enum drives all licensing UI and feature gating"

# Metrics
duration: 4min
completed: 2026-02-14
---

# Phase 6 Plan 1: Core Licensing Infrastructure Summary

**LemonSqueezy license activation/validation with HMAC-signed trial storage and 7-day offline/grace period support**

## Performance

- **Duration:** 4 min
- **Started:** 2026-02-14T09:46:00Z
- **Completed:** 2026-02-14T09:50:36Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments
- LicenseManager service with full licensing lifecycle: activate, validate, deactivate
- Product ownership verification prevents cross-product license key acceptance
- Non-blocking validation on launch with cached state shown immediately
- HMAC-signed trial storage prevents casual date tampering
- 7-day offline validation window and 7-day grace period for subscription lapses

## Task Commits

Each task was committed atomically:

1. **Task 1: Add LemonSqueezy package and constants** - `37645d4` (feat)
2. **Task 2: Create LicenseState model and LicenseStorage** - `983f990` (feat)
3. **Task 3: Create LicenseManager service** - `b39893c` (feat)

## Files Created/Modified
- `Package.swift` - Added swift-lemon-squeezy-license v1.0.1 dependency
- `Package.resolved` - Updated with LemonSqueezy package resolution
- `ClaudeMon/Utilities/Constants.swift` - Added LemonSqueezy licensing constants (store ID, product ID, checkout URL, portal URL, trial/grace/offline durations, Keychain service)
- `ClaudeMon/Models/LicenseState.swift` - License state machine enum with 5 states, isProEnabled, displayText, menuBarSuffix
- `ClaudeMon/Services/LicenseStorage.swift` - Actor-based secure Keychain storage with HMAC trial verification
- `ClaudeMon/Services/LicenseManager.swift` - Central licensing service with activation, validation, deactivation, offline fallback

## Decisions Made
- Used `@preconcurrency import LemonSqueezyLicense` to handle Swift 6 strict concurrency (response types lack Sendable conformance)
- Used `.product(name: "LemonSqueezyLicense", package: "swift-lemon-squeezy-license")` for SPM target dependency (bare string failed resolution)
- Adapted error handling from plan: `ActivateResponse` has no `error` field; errors come via thrown `LemonSqueezyLicenseError`
- Used enum comparison (`.expired`) instead of string comparison for `ValidateResponse.LicenseKey.status` type safety

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] SPM product dependency resolution**
- **Found during:** Task 1 (Add LemonSqueezy package)
- **Issue:** `"LemonSqueezyLicense"` as bare string dependency failed with "product not found"
- **Fix:** Changed to `.product(name: "LemonSqueezyLicense", package: "swift-lemon-squeezy-license")`
- **Files modified:** Package.swift
- **Verification:** `swift build` succeeds
- **Committed in:** 37645d4 (Task 1 commit)

**2. [Rule 1 - Bug] ActivateResponse.error property does not exist**
- **Found during:** Task 3 (Create LicenseManager)
- **Issue:** Plan referenced `response.error` on ActivateResponse, but the actual API throws LemonSqueezyLicenseError instead
- **Fix:** Catch `LemonSqueezyLicenseError` and map to `LicenseError.activationFailed` with extracted error message
- **Files modified:** ClaudeMon/Services/LicenseManager.swift
- **Verification:** `swift build` succeeds, all error paths handled
- **Committed in:** b39893c (Task 3 commit)

**3. [Rule 1 - Bug] License status is enum, not string**
- **Found during:** Task 3 (Create LicenseManager)
- **Issue:** Plan used `response.licenseKey?.status == "expired"` but status is `Status` enum type
- **Fix:** Changed to `response.licenseKey?.status == .expired`
- **Files modified:** ClaudeMon/Services/LicenseManager.swift
- **Verification:** `swift build` succeeds with type-safe comparison
- **Committed in:** b39893c (Task 3 commit)

**4. [Rule 3 - Blocking] Swift 6 Sendable compliance for LemonSqueezyLicense responses**
- **Found during:** Task 3 (Create LicenseManager)
- **Issue:** LemonSqueezyLicense response types don't conform to Sendable, causing errors with @MainActor isolation
- **Fix:** Used `@preconcurrency import LemonSqueezyLicense` to suppress Sendable warnings for known-safe immutable structs
- **Files modified:** ClaudeMon/Services/LicenseManager.swift
- **Verification:** `swift build` succeeds with zero errors
- **Committed in:** b39893c (Task 3 commit)

---

**Total deviations:** 4 auto-fixed (2 bugs, 2 blocking)
**Impact on plan:** All fixes necessary for correctness and Swift 6 compatibility. No scope creep.

## Issues Encountered
None beyond the deviations documented above.

## User Setup Required

LemonSqueezy store and product IDs are placeholders (set to 0). Before release:
- Replace `Constants.lemonSqueezyStoreId` with actual store ID from LemonSqueezy Dashboard
- Replace `Constants.lemonSqueezyProductId` with actual product ID
- Replace `Constants.lemonSqueezyCheckoutURL` with actual checkout link
- Replace `Constants.lemonSqueezyPortalURL` with actual customer portal URL

## Next Phase Readiness
- LicenseManager ready for integration with app lifecycle (06-02: FeatureAccessManager and UI wiring)
- LicenseState.displayText and menuBarSuffix ready for StatusItemManager integration
- LicenseStorage ready for FeatureAccessManager to query Pro status
- All 5 license states (onTrial, licensed, trialExpired, gracePeriod, unlicensed) available for UI branching

## Self-Check: PASSED

All 4 created files exist. All 3 task commits verified in git log.

---
*Phase: 06-licensing-foundation*
*Completed: 2026-02-14*
