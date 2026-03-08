---
phase: 23-seo-content-marketing
plan: 02
subsystem: ui
tags: [seo, blog, mdx, json-ld, opengraph, sitemap, content-marketing, structured-data]

# Dependency graph
requires:
  - phase: 23-01
    provides: "MDX blog infrastructure, BlogLayout, blog.ts utilities, seed blog post"
provides:
  - "Two additional SEO-targeted blog posts (rate limits guide, token monitoring guide)"
  - "Article JSON-LD structured data on all blog post pages"
  - "Dynamic OG image generation per blog post at /blog/[slug]/opengraph-image"
  - "Sitemap updated with /blog index and all blog post URLs"
  - "Blog link added to site navigation (Nav component and landing page)"
  - "Landing page SEO copy optimization with keyword-rich headings"
  - "Internal links from landing page to blog posts (From the Blog section)"
affects: [23-03-PLAN]

# Tech tracking
tech-stack:
  added: []
  patterns: ["Article JSON-LD structured data on blog post pages", "Dynamic OG image generation with next/og ImageResponse", "Internal linking between landing page and blog content"]

key-files:
  created:
    - "tokemon-site/content/blog/avoid-claude-rate-limits.mdx"
    - "tokemon-site/content/blog/claude-token-monitoring-guide.mdx"
    - "tokemon-site/src/app/blog/[slug]/opengraph-image.tsx"
  modified:
    - "tokemon-site/src/components/Nav.tsx"
    - "tokemon-site/src/app/blog/[slug]/page.tsx"
    - "tokemon-site/src/app/sitemap.ts"
    - "tokemon-site/src/app/page.tsx"
    - "tokemon-site/e2e/landing-page.spec.ts"

key-decisions:
  - "Added keyword subtitle 'Claude Code Usage Monitor for macOS & Raycast' below h1 rather than modifying the animated headline"
  - "Used system fonts for OG images instead of loading custom Geist fonts for simplicity"
  - "Added Blog link to both Nav component and landing page inline nav for full coverage"

patterns-established:
  - "Blog post pages include Article JSON-LD script tag with schema.org structured data"
  - "Each blog post route generates a dynamic OG image via opengraph-image.tsx convention"
  - "Landing page links to blog content via a 'Learn More' section for internal linking"

requirements-completed: [SEO-03, SEO-04, SEO-05, SEO-07]

# Metrics
duration: 6min
completed: 2026-03-08
---

# Phase 23 Plan 02: SEO Content & Structured Data Summary

**Two SEO blog posts, Article JSON-LD structured data, dynamic OG images, sitemap expansion, and landing page keyword optimization with internal blog linking**

## Performance

- **Duration:** 6 min
- **Started:** 2026-03-08T14:36:15Z
- **Completed:** 2026-03-08T14:42:41Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments
- Two new SEO-targeted blog posts: "How to Avoid Claude Rate Limits" (~1100 words) and "The Complete Guide to Claude Token Usage Monitoring" (~1100 words), bringing total to 3 blog posts
- Article JSON-LD structured data on every blog post page for Google rich results
- Dynamic 1200x630 OG images generated per blog post via next/og ImageResponse for social sharing
- Sitemap expanded from 1 entry (homepage) to 5 entries (homepage + /blog + 3 blog posts)
- Blog link added to Nav component and landing page navigation
- Landing page headings optimized for SEO keywords ("Real-Time Claude Usage Tracking", "Monitor Claude Rate Limits & More", "Start Tracking Claude Usage in 30 Seconds")
- "Learn More" section on landing page with internal links to all 3 blog posts
- E2E tests updated to match new heading text

## Task Commits

Each task was committed atomically:

1. **Task 1: Write two additional blog posts and add Blog nav link** - `f8b8bd3` (feat)
2. **Task 2: Add Article JSON-LD, dynamic OG images, and update sitemap** - `cb1d9d0` (feat)
3. **Task 3: Landing page SEO copy review and internal linking** - `7731e08` (feat)

## Files Created/Modified
- `tokemon-site/content/blog/avoid-claude-rate-limits.mdx` - Blog post targeting "avoid claude rate limits" keywords with practical strategies
- `tokemon-site/content/blog/claude-token-monitoring-guide.mdx` - Blog post targeting "claude token usage monitoring" keywords with tool comparison
- `tokemon-site/src/app/blog/[slug]/opengraph-image.tsx` - Dynamic OG image generation per blog post with dark theme
- `tokemon-site/src/components/Nav.tsx` - Added Blog link with Next.js Link component
- `tokemon-site/src/app/blog/[slug]/page.tsx` - Added Article JSON-LD structured data script tag
- `tokemon-site/src/app/sitemap.ts` - Added /blog and all blog post URLs via getPostSlugs
- `tokemon-site/src/app/page.tsx` - SEO keyword headings, Blog nav link, "Learn More" blog section, footer Blog link
- `tokemon-site/e2e/landing-page.spec.ts` - Updated heading text assertions to match new SEO copy

## Decisions Made
- **Keyword subtitle approach:** Added "Claude Code Usage Monitor for macOS & Raycast" as a small subtitle text below the animated h1 rather than modifying the existing headline. This preserves the compelling "Never hit a rate limit by surprise again" message while adding the primary keyword for search engines.
- **System fonts for OG images:** Used system default fonts in OG image generation rather than loading custom Geist fonts. Loading custom fonts requires fetching font files and adds complexity that is unnecessary for the MVP.
- **Dual nav link coverage:** Added Blog link to both the reusable Nav component (used on /blog pages) and the landing page's inline nav (used on /). This ensures the Blog link appears consistently across all pages.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated E2E tests for new heading text**
- **Found during:** Task 3 (Landing page SEO copy)
- **Issue:** Existing E2E tests referenced old heading text ("Built for power users", "Your usage, always visible", "Start monitoring in 30 seconds") that was updated for SEO
- **Fix:** Updated all heading text assertions in landing-page.spec.ts to match new SEO-optimized headings, added "Learn More" section to expected order
- **Files modified:** tokemon-site/e2e/landing-page.spec.ts
- **Verification:** Build succeeds, test assertions match rendered content
- **Committed in:** 7731e08 (Task 3 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** E2E test update was necessary to keep tests passing with new heading text. No scope creep.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All three blog posts are published and accessible with full SEO metadata
- Blog infrastructure is complete with structured data, OG images, and sitemap coverage
- Plan 23-03 can proceed with Google Search Console setup and external distribution

## Self-Check: PASSED

All 8 created/modified files verified on disk. All 3 task commits (f8b8bd3, cb1d9d0, 7731e08) verified in git log.

---
*Phase: 23-seo-content-marketing*
*Completed: 2026-03-08*
