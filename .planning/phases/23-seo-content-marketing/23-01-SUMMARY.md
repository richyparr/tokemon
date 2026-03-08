---
phase: 23-seo-content-marketing
plan: 01
subsystem: ui
tags: [mdx, next-mdx, blog, tailwind-typography, rehype-pretty-code, remark-gfm, seo]

# Dependency graph
requires: []
provides:
  - "MDX blog infrastructure with @next/mdx, remark/rehype plugins"
  - "Blog index page at /blog listing posts sorted by date"
  - "Dynamic blog post page at /blog/[slug] with SSG"
  - "BlogLayout component with prose styling and CTA footer"
  - "Blog utility functions (getPosts, getPostSlugs) with fs-based metadata extraction"
  - "Seed blog post: How to Track Claude Code Usage in Real-Time"
affects: [23-02-PLAN, 23-03-PLAN]

# Tech tracking
tech-stack:
  added: ["@next/mdx", "@mdx-js/loader", "@mdx-js/react", "@tailwindcss/typography", "remark-gfm", "rehype-pretty-code", "rehype-slug", "rehype-autolink-headings", "gray-matter"]
  patterns: ["MDX content in content/blog/*.mdx with exported metadata objects", "fs-based metadata extraction to avoid dynamic import warnings", "Tailwind Typography @plugin directive for v4"]

key-files:
  created:
    - "tokemon-site/next.config.mjs"
    - "tokemon-site/mdx-components.tsx"
    - "tokemon-site/src/lib/blog.ts"
    - "tokemon-site/src/components/BlogLayout.tsx"
    - "tokemon-site/src/app/blog/page.tsx"
    - "tokemon-site/src/app/blog/[slug]/page.tsx"
    - "tokemon-site/content/blog/how-to-track-claude-code-usage.mdx"
  modified:
    - "tokemon-site/package.json"
    - "tokemon-site/src/app/globals.css"
    - "tokemon-site/tsconfig.json"

key-decisions:
  - "Used fs-based metadata extraction instead of dynamic imports to avoid Turbopack warnings"
  - "Used @plugin directive for Tailwind Typography (v4 CSS syntax, not JS config)"
  - "String-based rehype/remark plugin references for Turbopack compatibility"

patterns-established:
  - "MDX blog posts live in content/blog/*.mdx with `export const metadata` for frontmatter"
  - "Blog utility in src/lib/blog.ts extracts metadata from MDX source files via regex"
  - "BlogLayout component wraps all blog posts with header, prose styling, and CTA footer"

requirements-completed: [SEO-01, SEO-02]

# Metrics
duration: 3min
completed: 2026-03-08
---

# Phase 23 Plan 01: MDX Blog Infrastructure Summary

**MDX blog system with @next/mdx, Tailwind Typography prose styling, rehype-pretty-code syntax highlighting, and one seed blog post at /blog**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-08T14:30:07Z
- **Completed:** 2026-03-08T14:33:44Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments
- Full MDX blog infrastructure with @next/mdx, remark-gfm, rehype-pretty-code (one-dark-pro), rehype-slug, and rehype-autolink-headings
- Blog index at /blog listing posts as styled cards with hover effects matching site dark theme
- Dynamic blog post pages at /blog/[slug] with SSG via generateStaticParams, proper OG metadata, and 404 for unknown slugs
- Seed blog post "How to Track Claude Code Usage in Real-Time" (~900 words) targeting key SEO terms

## Task Commits

Each task was committed atomically:

1. **Task 1: Install MDX dependencies and configure Next.js for MDX** - `e376193` (chore)
2. **Task 2: Create blog pages, utilities, and seed content** - `7da62d6` (feat)

## Files Created/Modified
- `tokemon-site/next.config.mjs` - MDX configuration with createMDX wrapper and remark/rehype plugins
- `tokemon-site/mdx-components.tsx` - Required MDX component mapping for @next/mdx
- `tokemon-site/src/lib/blog.ts` - Blog utilities: getPostSlugs(), getPosts() with fs-based metadata extraction
- `tokemon-site/src/components/BlogLayout.tsx` - Blog post wrapper with prose styling, back link, and download CTA
- `tokemon-site/src/app/blog/page.tsx` - Blog index page listing all posts as clickable cards
- `tokemon-site/src/app/blog/[slug]/page.tsx` - Dynamic blog post page with SSG, metadata generation, and MDX rendering
- `tokemon-site/content/blog/how-to-track-claude-code-usage.mdx` - Seed blog post targeting Claude usage tracking keywords
- `tokemon-site/package.json` - Added MDX and typography dependencies
- `tokemon-site/src/app/globals.css` - Added @tailwindcss/typography via @plugin directive
- `tokemon-site/tsconfig.json` - Added MDX file extensions to include array

## Decisions Made
- **fs-based metadata extraction over dynamic imports:** Dynamic imports with template literals in blog.ts caused Turbopack module-not-found warnings. Switched to reading MDX source files with fs.readFileSync and extracting the exported metadata object via regex + Function constructor. The [slug]/page.tsx still uses dynamic imports since slugs come from generateStaticParams (known at build time).
- **@plugin directive for Tailwind Typography:** Used Tailwind v4 CSS syntax (`@plugin "@tailwindcss/typography"`) rather than JS config, consistent with the existing project setup.
- **String-based plugin references in next.config.mjs:** Used string names (e.g., `"remark-gfm"`) instead of imported functions for rehype/remark plugins to maintain Turbopack compatibility per research findings.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed Turbopack dynamic import warning in blog.ts**
- **Found during:** Task 2 (Blog utilities implementation)
- **Issue:** Dynamic import with template literal `import(\`../../../content/blog/${slug}.mdx\`)` in blog.ts caused a "Module not found" warning from Turbopack, even though build succeeded
- **Fix:** Replaced dynamic import with fs.readFileSync-based metadata extraction using regex and Function constructor
- **Files modified:** tokemon-site/src/lib/blog.ts
- **Verification:** Build completes with no warnings
- **Committed in:** 7da62d6 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Minor implementation change for cleaner builds. No scope creep.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Blog infrastructure is fully operational and ready for additional content
- Plans 23-02 and 23-03 can build on this foundation to add more blog posts, comparison pages, and SEO optimizations
- Content directory structure established at content/blog/ for future posts

## Self-Check: PASSED

All 8 created files verified on disk. Both task commits (e376193, 7da62d6) verified in git log.

---
*Phase: 23-seo-content-marketing*
*Completed: 2026-03-08*
