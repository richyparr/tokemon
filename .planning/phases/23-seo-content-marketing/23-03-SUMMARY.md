---
phase: 23-seo-content-marketing
plan: 03
subsystem: ui
tags: [seo, comparison-pages, mdx, e2e-testing, playwright, json-ld, opengraph, sitemap, content-marketing]

# Dependency graph
requires:
  - phase: 23-01
    provides: "MDX blog infrastructure, BlogLayout, blog.ts utilities, seed blog post"
  - phase: 23-02
    provides: "Additional blog posts, Article JSON-LD, OG images, sitemap with blog URLs, Blog nav link"
provides:
  - "Two comparison pages at /compare/[slug] targeting commercial search intent"
  - "Comparison page infrastructure (compare.ts utility, dynamic route, OG images)"
  - "Sitemap expanded with comparison page URLs"
  - "Comprehensive E2E test suite for blog and comparison pages (23 tests)"
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns: ["Comparison pages mirror blog post pattern with CompareMetadata type", "E2E tests use Playwright with domcontentloaded wait strategy", "Comparison content in content/compare/*.mdx with competitor field"]

key-files:
  created:
    - "tokemon-site/src/lib/compare.ts"
    - "tokemon-site/src/app/compare/[slug]/page.tsx"
    - "tokemon-site/src/app/compare/[slug]/opengraph-image.tsx"
    - "tokemon-site/content/compare/tokemon-vs-ccusage.mdx"
    - "tokemon-site/content/compare/tokemon-vs-claudebar.mdx"
    - "tokemon-site/e2e/blog.spec.ts"
    - "tokemon-site/e2e/blog-seo.spec.ts"
  modified:
    - "tokemon-site/src/app/sitemap.ts"

key-decisions:
  - "Reused BlogLayout component for comparison pages to maintain consistent styling and CTA"
  - "Mirrored blog.ts pattern for compare.ts with fs-based metadata extraction"
  - "Used 3 Playwright workers for test parallelism without overwhelming dev server"

patterns-established:
  - "Comparison content lives in content/compare/*.mdx with CompareMetadata type including competitor field"
  - "E2E blog tests use domcontentloaded wait strategy for faster test execution"
  - "Sitemap aggregates slugs from both blog.ts and compare.ts utility modules"

requirements-completed: [SEO-06]

# Metrics
duration: 8min
completed: 2026-03-08
---

# Phase 23 Plan 03: Comparison Pages & E2E Tests Summary

**Two competitor comparison pages (vs ccusage, vs ClaudeBar) targeting commercial search intent, plus 23 E2E tests covering the entire blog and comparison content system**

## Performance

- **Duration:** 8 min
- **Started:** 2026-03-08T14:45:35Z
- **Completed:** 2026-03-08T14:53:39Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments
- Two comparison pages with feature tables, SEO metadata, Article JSON-LD, and dynamic OG images targeting "ccusage alternative" and "claudebar alternative" searches
- Comparison page infrastructure mirroring blog pattern: compare.ts utility with getCompareSlugs, dynamic /compare/[slug] route with SSG, OG image generation
- Sitemap expanded from 5 entries to 7 entries (added 2 comparison page URLs)
- 23 E2E tests covering blog index, blog post rendering, code blocks, comparison pages, comparison tables, SEO metadata, JSON-LD structured data, sitemap coverage, and navigation
- All 22 existing landing-page tests continue to pass (no regression)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create comparison page infrastructure and content** - `6417660` (feat)
2. **Task 2: Add E2E tests for blog and comparison pages** - `f1f77f4` (test)

## Files Created/Modified
- `tokemon-site/src/lib/compare.ts` - Comparison page utilities: getCompareSlugs, CompareMetadata type, fs-based metadata extraction
- `tokemon-site/src/app/compare/[slug]/page.tsx` - Dynamic comparison page with SSG, metadata generation, and Article JSON-LD
- `tokemon-site/src/app/compare/[slug]/opengraph-image.tsx` - Dynamic OG image generation with "tokemon.ai/compare" branding
- `tokemon-site/content/compare/tokemon-vs-ccusage.mdx` - Comparison page: Tokemon vs ccusage (GUI vs CLI, real-time vs post-session)
- `tokemon-site/content/compare/tokemon-vs-claudebar.mdx` - Comparison page: Tokemon vs ClaudeBar (Claude-deep vs multi-provider)
- `tokemon-site/src/app/sitemap.ts` - Added comparison page URLs via getCompareSlugs
- `tokemon-site/e2e/blog.spec.ts` - 14 E2E tests for blog index, blog posts, and comparison pages
- `tokemon-site/e2e/blog-seo.spec.ts` - 9 E2E tests for SEO metadata, JSON-LD, sitemap, and navigation

## Decisions Made
- **Reused BlogLayout for comparison pages:** Rather than creating a separate CompareLayout, reused BlogLayout since comparison pages have the same structure (title, author, date, prose content, CTA footer). The CompareMetadata type extends the same shape with an additional `competitor` field.
- **Mirrored blog.ts for compare.ts:** Used the same fs-based metadata extraction pattern established in Plan 01 to avoid Turbopack dynamic import warnings in the utility module.
- **3 Playwright workers:** Balanced parallelism with dev server capacity. All 23 tests complete in ~7.6 seconds.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 23 SEO & Content Marketing is now complete
- All content pages (3 blog posts + 2 comparison pages) have full SEO: metadata, JSON-LD, OG images, sitemap
- 45 total E2E tests (22 landing-page + 23 blog/compare) provide comprehensive regression coverage
- Content system is extensible: add new .mdx files to content/blog/ or content/compare/ and they auto-appear

## Self-Check: PASSED

All 8 created/modified files verified on disk. Both task commits (6417660, f1f77f4) verified in git log.

---
*Phase: 23-seo-content-marketing*
*Completed: 2026-03-08*
