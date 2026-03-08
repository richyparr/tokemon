---
phase: 23
slug: seo-content-marketing
status: draft
nyquist_compliant: false
wave_0_complete: false
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

- **After every task commit:** Run `cd tokemon-site && npx playwright test --project="Desktop Chrome" -x`
- **After every plan wave:** Run `cd tokemon-site && npx playwright test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 23-01-01 | 01 | 1 | SEO-01 | E2E | `npx playwright test e2e/blog.spec.ts --project="Desktop Chrome" -x` | ❌ W0 | ⬜ pending |
| 23-01-02 | 01 | 1 | SEO-02 | E2E | `npx playwright test e2e/blog.spec.ts --project="Desktop Chrome" -x` | ❌ W0 | ⬜ pending |
| 23-01-03 | 01 | 1 | SEO-03 | E2E | `npx playwright test e2e/blog-seo.spec.ts --project="Desktop Chrome" -x` | ❌ W0 | ⬜ pending |
| 23-01-04 | 01 | 1 | SEO-04 | E2E | `npx playwright test e2e/sitemap.spec.ts --project="Desktop Chrome" -x` | ❌ W0 | ⬜ pending |
| 23-01-05 | 01 | 1 | SEO-05 | E2E | `npx playwright test e2e/landing-page.spec.ts --project="Desktop Chrome" -x` | ✅ partial | ⬜ pending |
| 23-02-01 | 02 | 2 | SEO-06 | E2E | `npx playwright test e2e/compare.spec.ts --project="Desktop Chrome" -x` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `e2e/blog.spec.ts` — stubs for SEO-01, SEO-02 (blog index loads, blog post renders MDX)
- [ ] `e2e/blog-seo.spec.ts` — stubs for SEO-03 (meta tags, OG image, JSON-LD)
- [ ] `e2e/sitemap.spec.ts` — stubs for SEO-04 (sitemap includes blog URLs)
- [ ] `e2e/compare.spec.ts` — stubs for SEO-06 (comparison pages render)
- [ ] Update `e2e/landing-page.spec.ts` — stubs for SEO-05 (nav includes Blog link)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Google Search Console verification | SEO-GSC | Requires user's Google account | User adds verification meta tag, verifies in GSC, submits sitemap |
| Product Hunt submission | SEO-PH | External platform | Prepare listing, submit, verify live |
| Directory listings (AlternativeTo, awesome-lists) | SEO-DIR | External platforms | Submit PRs/listings, verify acceptance |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
