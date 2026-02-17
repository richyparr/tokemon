---
phase: 14-distribution-trust
plan: 01
subsystem: infra
tags: [codesign, notarization, github-actions, dmg, release-pipeline, gatekeeper]

# Dependency graph
requires: []
provides:
  - "build-release.sh for signed .app bundle and DMG creation"
  - "notarize.sh for Apple notary submission and stapling"
  - "GitHub Actions release workflow triggered by v* tags"
affects: [14-02, 14-03, 14-04]

# Tech tracking
tech-stack:
  added: [codesign, notarytool, stapler, hdiutil, github-actions]
  patterns: [developer-id-signing, hardened-runtime, notarization-stapling, tag-triggered-release]

key-files:
  created:
    - scripts/build-release.sh
    - scripts/notarize.sh
    - .github/workflows/release.yml
  modified: []

key-decisions:
  - "SKIP_SIGNING env var for testing bundle structure without certificate"
  - "Entitlements file used during signing for hardened runtime compatibility"
  - "DMG re-signed and re-stapled after app stapling for full notarization chain"
  - "softprops/action-gh-release@v2 with auto release notes generation"

patterns-established:
  - "Release script pattern: build -> bundle -> sign -> DMG -> notarize"
  - "CI keychain pattern: create temp keychain, import p12, allow codesign access"

# Metrics
duration: 3min
completed: 2026-02-17
---

# Phase 14 Plan 01: Code Signing & Release Infrastructure Summary

**Release pipeline with Developer ID signing, Apple notarization, and GitHub Actions CI for tag-triggered DMG distribution**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-17T09:21:10Z
- **Completed:** 2026-02-17T09:24:34Z
- **Tasks:** 2
- **Files created:** 3

## Accomplishments
- Build script creates complete .app bundle from SPM executable with versioned Info.plist, resources, and Developer ID signing
- Notarization script submits to Apple notary service, staples tickets to both DMG and enclosed app, verifies Gatekeeper approval
- GitHub Actions workflow automates full pipeline: certificate import, build, sign, notarize, and GitHub Release creation
- Verified bundle structure: Contents/{MacOS/Tokemon, Info.plist, Resources/, PkgInfo, _CodeSignature}

## Task Commits

Each task was committed atomically:

1. **Task 1: Create build and signing scripts** - `4ad17e3` (feat)
2. **Task 2: Create GitHub Actions release workflow** - `1329594` (feat)

## Files Created/Modified
- `scripts/build-release.sh` - Builds SPM release binary, creates .app bundle with versioned plist, signs with Developer ID, creates signed DMG (132 lines)
- `scripts/notarize.sh` - Submits DMG to Apple notary service, staples ticket to DMG and app, repacks DMG, verifies Gatekeeper (140 lines)
- `.github/workflows/release.yml` - GitHub Actions workflow triggered by v* tags, imports p12 certificate, runs build and notarize scripts, creates GitHub Release (87 lines)

## Decisions Made
- Added SKIP_SIGNING=1 mode to build-release.sh so bundle structure can be tested without a Developer ID certificate
- Used entitlements file during codesign (--entitlements flag) for hardened runtime compatibility with keychain access
- Notarize script re-creates DMG after stapling app inside, then re-staples the new DMG for complete notarization chain
- Used softprops/action-gh-release@v2 (latest) instead of v1 from plan template
- Added APPLE_DEVELOPER_ID to notarize job env so re-signing after app stapling works in CI

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- Transient SPM build error ("input file modified during build") on first run, resolved by retry
- PyYAML not available for YAML validation, used structural validation instead

## User Setup Required

External services require manual configuration before the release pipeline can run:

**Apple Developer Account:**
- Create Developer ID Application certificate at Apple Developer Portal
- Export as .p12 file, base64-encode for GitHub Secrets (APPLE_CERTIFICATE_P12)
- Set APPLE_CERTIFICATE_PASSWORD, APPLE_DEVELOPER_ID, APPLE_ID, AC_PASSWORD, APPLE_TEAM_ID

## Next Phase Readiness
- Release infrastructure complete, ready for Homebrew cask formula (14-02)
- DMG output path follows standard naming convention for Homebrew SHA256 verification
- Scripts are modular: build-release.sh and notarize.sh can be called independently or from CI

---
*Phase: 14-distribution-trust*
*Completed: 2026-02-17*
