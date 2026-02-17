---
phase: 14-distribution-trust
plan: 02
subsystem: infra
tags: [homebrew, cask, tap, package-manager, distribution, github-actions]

# Dependency graph
requires:
  - phase: 14-01
    provides: "Release workflow with signed DMG output"
provides:
  - "Homebrew cask formula for installing Tokemon from GitHub Releases"
  - "Tap repository structure ready to push to GitHub"
  - "Automated SHA256 update workflow triggered by releases"
affects: [14-03]

# Tech tracking
tech-stack:
  added: [homebrew-cask, repository-dispatch]
  patterns: [homebrew-tap-distribution, release-triggered-tap-update]

key-files:
  created:
    - homebrew-tokemon/Formula/tokemon.rb
    - homebrew-tokemon/README.md
    - homebrew-tokemon/.github/workflows/update-sha.yml
  modified:
    - .github/workflows/release.yml

key-decisions:
  - "Used cask (not formula) since Tokemon is a macOS .app distributed as DMG"
  - "Added depends_on macos >= :sonoma matching Info.plist LSMinimumSystemVersion 14.0"
  - "SHA256 passed from release workflow via repository_dispatch to avoid re-downloading DMG"
  - "Used --cask flag in README install commands for clarity"

patterns-established:
  - "Release pipeline triggers tap update: build -> sign -> notarize -> release -> dispatch to tap"
  - "SHA computed once in CI and forwarded via client-payload, not re-downloaded in tap repo"

# Metrics
duration: 2min
completed: 2026-02-17
---

# Phase 14 Plan 02: Homebrew Cask Summary

**Homebrew cask formula with automated SHA256 update via release pipeline repository_dispatch**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-17T09:26:52Z
- **Completed:** 2026-02-17T09:28:26Z
- **Tasks:** 2
- **Files created:** 3
- **Files modified:** 1

## Accomplishments
- Homebrew cask formula installs Tokemon.app from GitHub Releases DMG with livecheck and zap stanza
- Tap repository includes GitHub Actions workflow for automated SHA256/version updates via PR
- Release workflow computes DMG SHA256 and triggers tap update via repository_dispatch
- README provides complete install, upgrade, and uninstall instructions

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Homebrew tap repository structure** - `54fee68` (feat)
2. **Task 2: Add tap publishing instructions to release workflow** - `c1f7885` (feat)

## Files Created/Modified
- `homebrew-tokemon/Formula/tokemon.rb` - Homebrew cask formula: version, SHA256, URL to release DMG, livecheck, macOS dependency, zap stanza (22 lines)
- `homebrew-tokemon/README.md` - Installation instructions with brew tap/install/upgrade/uninstall commands and troubleshooting (40 lines)
- `homebrew-tokemon/.github/workflows/update-sha.yml` - GitHub Actions workflow triggered by repository_dispatch or manual; updates formula version and SHA256, creates PR (56 lines)
- `.github/workflows/release.yml` - Added Compute DMG SHA256 step and Trigger Homebrew tap update step; added HOMEBREW_TAP_TOKEN to required secrets (18 lines added)

## Decisions Made
- Used cask format (not formula) since Tokemon is a native macOS .app distributed as a DMG, not a CLI tool
- Added `depends_on macos: ">= :sonoma"` matching Info.plist's LSMinimumSystemVersion of 14.0
- SHA256 is computed once in the release CI job and forwarded to the tap repo via repository_dispatch client-payload, avoiding redundant DMG download
- Used `--cask` flag in README commands for explicitness (brew install --cask tokemon)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required

External services require manual configuration before Homebrew distribution works:

**GitHub Repository:**
1. Create public repository named `homebrew-tokemon` on GitHub
2. Push contents of `homebrew-tokemon/` directory to that repository
3. Create a Personal Access Token (PAT) with `repo` scope
4. Add PAT as `HOMEBREW_TAP_TOKEN` secret in the main Tokemon repository

**Testing installation:**
```bash
brew tap AverageHelper/tokemon
brew install --cask tokemon
```

## Next Phase Readiness
- Tap repository is ready to push to GitHub as a separate repository
- Release workflow will automatically trigger tap SHA256 updates on new releases
- Formula placeholder SHA256 will be replaced on first real release

## Self-Check: PASSED

All files verified present. All commits verified in git log.

---
*Phase: 14-distribution-trust*
*Completed: 2026-02-17*
