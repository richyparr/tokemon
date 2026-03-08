---
phase: 23
slug: seo-content-marketing
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-08
---

# Phase 23 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Playwright 1.58.2 |
| **Config file** | `tokemon-site/playwright.config.ts` |
| **Quick run command** | `cd tokemon-site && npx playwright test --project="Desktop Chrome" -x` |
| **Full suite command** | `cd tokemon-site && npx playwright test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd tokemon-site && npm run build 2>&1 | tail -20`
- **After every plan wave:** Run `cd tokemon-site && npx playwright test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | Status |
|---------|------|------|-------------|-----------|-------------------|--------|
| 23-01-01 | 01 | 1 | SEO-01 | Build | `cd tokemon-site && npm run build 2>&1 \| tail -20` | pending |
| 23-01-02 | 01 | 1 | SEO-02 | Build | `cd tokemon-site && npm run build 2>&1 \| tail -20` | pending |
| 23-02-01 | 02 | 2 | SEO-03, SEO-05 | Build | `cd tokemon-site && npm run build 2>&1 \| tail -20` | pending |
| 23-02-02 | 02 | 2 | SEO-04 | Build | `cd tokemon-site && npm run build 2>&1 \| tail -30` | pending |
| 23-02-03 | 02 | 2 | SEO-07 | Build | `cd tokemon-site && npm run build 2>&1 \| tail -20` | pending |
| 23-03-01 | 03 | 3 | SEO-06 | Build | `cd tokemon-site && npm run build 2>&1 \| tail -20` | pending |
| 23-03-02 | 03 | 3 | SEO-01-06 | E2E | `cd tokemon-site && npx playwright test e2e/blog.spec.ts e2e/blog-seo.spec.ts --project="Desktop Chrome" -x` | pending |

*Status: pending / green / red / flaky*

---

## Verification Strategy

Plans 01 and 02 use `npm run build` as their primary verification. The Next.js build process validates that all pages render, all imports resolve, all static params generate, and all metadata exports are valid. This provides strong verification without requiring E2E test stubs upfront.

Plan 03 (Wave 3) adds comprehensive E2E tests retroactively in `e2e/blog.spec.ts` and `e2e/blog-seo.spec.ts`, covering all requirements (SEO-01 through SEO-06). These tests run against the fully built site and verify:

- **blog.spec.ts**: Blog index listing (SEO-01), blog post rendering (SEO-02), comparison page rendering and content (SEO-06), 404 handling
- **blog-seo.spec.ts**: Meta tags and JSON-LD (SEO-03), sitemap coverage for blog and comparison URLs (SEO-04), navigation Blog link (SEO-05)

This "build-then-test" approach is appropriate because:
1. MDX infrastructure has no meaningful behavior to test until content exists
2. `npm run build` catches 90%+ of issues (broken imports, missing exports, invalid metadata)
3. E2E tests added in Plan 03 provide full coverage before the phase is marked complete

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Google Search Console verification | SEO-GSC | Requires user's Google account | User adds verification meta tag, verifies in GSC, submits sitemap |
| Product Hunt submission | SEO-PH | External platform | Prepare listing, submit, verify live |
| Directory listings (AlternativeTo, awesome-lists) | SEO-DIR | External platforms | Submit PRs/listings, verify acceptance |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify commands
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Build verification covers Plans 01/02; E2E tests added retroactively in Plan 03
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved
