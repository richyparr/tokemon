# Phase 23: SEO & Content Marketing - Research

**Researched:** 2026-03-08
**Domain:** Next.js App Router SEO, MDX content system, content marketing for developer tools
**Confidence:** HIGH

## Summary

Tokemon (tokemon.ai) is a native macOS menu bar app + Raycast extension for monitoring Claude Code usage. The site is a Next.js 16 App Router single-page landing site deployed on Vercel. Phase 22 (ad-hoc site launch) already shipped foundational SEO: robots.ts, sitemap.ts, JSON-LD SoftwareApplication schema, keyword-optimized meta tags, and Open Graph images. A Reddit launch post has been submitted to r/ClaudeCode.

This phase needs to build on that foundation with three pillars: (1) complete technical SEO (Google Search Console, verification, sitemap submission), (2) a content/blog system using MDX for SEO-targeted articles (guides, comparison pages), and (3) distribution to developer directories and listing sites. The competitive landscape is crowded -- at least 8 competing Claude usage monitors exist (ClaudeBar, ClaudeMeter, Usage4Claude, SessionWatcher, CUStats, ccusage, Claude-Code-Usage-Monitor, ClaudeUsageBar) -- making content marketing and SEO differentiation critical.

**Primary recommendation:** Use `@next/mdx` with file-based routing for a lightweight blog/content section at `/blog/[slug]`, targeting high-intent search queries around Claude usage monitoring, rate limits, and token tracking. Pair with `@tailwindcss/typography` for prose styling and dynamic OG image generation per post.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
The 23-CONTEXT.md is a session state file (not a structured CONTEXT.md from /gsd:discuss-phase). Key locked decisions extracted:

- Landing page redesign shipped with interactive demo, split hero layout
- SEO foundations deployed: robots.ts, sitemap.ts, JSON-LD, keyword meta tags
- Reddit post submitted to r/ClaudeCode (Resource flair)
- v4.0.0 GitHub release published, Homebrew cask updated
- Deploy workflow: edit -> commit to main -> git subtree split -> push -> vercel deploy --prod
- Site runs on port 3001 for dev

### Claude's Discretion
- Blog/content structure and tooling choices
- Content topic prioritization
- SEO technical improvements beyond existing foundations
- Distribution channel ordering

### Deferred Ideas (OUT OF SCOPE)
- Google Search Console setup (blocked on user providing verification meta tag -- should be FIRST task in this phase)
- Uncommitted macOS app changes (traffic light icon, settings fix, etc.) -- separate from SEO phase
</user_constraints>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `@next/mdx` | latest | MDX compilation for blog posts | Official Next.js MDX solution, server component support, no client JS overhead |
| `@mdx-js/loader` | latest | Webpack loader for MDX files | Required by @next/mdx |
| `@mdx-js/react` | latest | MDX React provider | Required by @next/mdx for component mapping |
| `@types/mdx` | latest | TypeScript types for MDX | Type safety for MDX imports |
| `@tailwindcss/typography` | latest | Prose styling for rendered markdown | Beautiful typographic defaults with zero custom CSS, v4-compatible |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `remark-gfm` | latest | GitHub Flavored Markdown | Tables, strikethrough, task lists in blog posts |
| `rehype-pretty-code` | latest | Syntax highlighting (Shiki-based) | Code blocks in blog posts (build-time, no client JS) |
| `rehype-slug` | latest | Add IDs to headings | Anchor links for table of contents |
| `rehype-autolink-headings` | latest | Auto-link headings | Clickable heading anchors for shareability |
| `gray-matter` | latest | Parse frontmatter from MDX files | Extract metadata (title, date, description) for blog index |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `@next/mdx` | `next-mdx-remote` | next-mdx-remote is poorly maintained, RSC support marked "unstable", security risks from client-side eval. @next/mdx is official and recommended. |
| `@next/mdx` | Velite or Content Collections | More powerful (Zod schema validation, build-time data layer) but overkill for 3-5 blog posts. Add later if content volume grows. |
| `@next/mdx` | CMS (Sanity, Contentful) | Unnecessary complexity for a solo developer. MDX files in git are simpler and free. |
| `rehype-pretty-code` | `rehype-highlight` | rehype-pretty-code uses Shiki (VS Code themes, build-time), rehype-highlight uses highlight.js (runtime). Pretty-code is better for SSG. |

**Installation:**
```bash
npm install @next/mdx @mdx-js/loader @mdx-js/react @types/mdx @tailwindcss/typography remark-gfm rehype-pretty-code rehype-slug rehype-autolink-headings gray-matter
```

## Architecture Patterns

### Recommended Project Structure
```
tokemon-site/
├── src/
│   ├── app/
│   │   ├── layout.tsx              # Root layout (existing, add verification meta)
│   │   ├── page.tsx                # Landing page (existing)
│   │   ├── robots.ts               # Existing
│   │   ├── sitemap.ts              # Update to include blog posts
│   │   ├── blog/
│   │   │   ├── page.tsx            # Blog index page
│   │   │   └── [slug]/
│   │   │       ├── page.tsx        # Dynamic blog post page
│   │   │       └── opengraph-image.tsx  # Dynamic OG image per post
│   │   └── compare/
│   │       └── [slug]/
│   │           └── page.tsx        # Comparison pages (tokemon vs X)
│   ├── components/
│   │   ├── BlogLayout.tsx          # Shared blog post layout with prose styling
│   │   ├── BlogCard.tsx            # Blog index card component
│   │   └── TableOfContents.tsx     # Auto-generated TOC from headings
│   └── lib/
│       └── blog.ts                 # Blog utilities (get posts, parse frontmatter)
├── content/
│   └── blog/
│       ├── how-to-track-claude-code-usage.mdx
│       ├── avoid-claude-rate-limits.mdx
│       └── claude-token-monitoring-guide.mdx
├── mdx-components.tsx              # Global MDX component mapping (REQUIRED)
└── next.config.ts                  # Update to next.config.mjs for MDX
```

### Pattern 1: MDX with Dynamic Imports and Frontmatter
**What:** Store blog posts as MDX files in `/content/blog/`, use dynamic imports with `generateStaticParams` to create static pages at build time.
**When to use:** Always -- this is the core content delivery pattern.
**Example:**
```typescript
// Source: https://nextjs.org/docs/app/guides/mdx

// content/blog/how-to-track-claude-code-usage.mdx
export const metadata = {
  title: "How to Track Claude Code Usage in Real-Time",
  description: "Step-by-step guide to monitoring your Claude Code token usage, burn rate, and session limits using Tokemon.",
  date: "2026-03-10",
  author: "Richard Parr",
  tags: ["claude-code", "usage-tracking", "tokemon"],
};

# How to Track Claude Code Usage in Real-Time
...content...

// app/blog/[slug]/page.tsx
import { notFound } from "next/navigation";
import type { Metadata } from "next";

const posts = ["how-to-track-claude-code-usage", "avoid-claude-rate-limits", "claude-token-monitoring-guide"];

export function generateStaticParams() {
  return posts.map((slug) => ({ slug }));
}

export const dynamicParams = false;

export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
  const { slug } = await params;
  const { metadata } = await import(`@/content/blog/${slug}.mdx`);
  return {
    title: `${metadata.title} | Tokemon`,
    description: metadata.description,
    openGraph: {
      title: metadata.title,
      description: metadata.description,
      type: "article",
      publishedTime: metadata.date,
      authors: [metadata.author],
    },
  };
}

export default async function BlogPost({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  try {
    const { default: Post, metadata } = await import(`@/content/blog/${slug}.mdx`);
    return (
      <article className="prose prose-invert prose-orange max-w-3xl mx-auto px-6 py-24">
        <Post />
      </article>
    );
  } catch {
    notFound();
  }
}
```

### Pattern 2: Dynamic OG Image Generation Per Blog Post
**What:** Use `next/og` ImageResponse to generate unique Open Graph images for each blog post at build time.
**When to use:** Every blog post and comparison page.
**Example:**
```typescript
// Source: https://nextjs.org/docs/app/getting-started/metadata-and-og-images

// app/blog/[slug]/opengraph-image.tsx
import { ImageResponse } from "next/og";

export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

export default async function Image({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const { metadata } = await import(`@/content/blog/${slug}.mdx`);

  return new ImageResponse(
    (
      <div style={{ display: "flex", flexDirection: "column", width: "100%", height: "100%", background: "#0a0a0a", padding: "60px", justifyContent: "center" }}>
        <div style={{ color: "#e8853b", fontSize: "24px", marginBottom: "16px" }}>tokemon.ai/blog</div>
        <div style={{ color: "#ededed", fontSize: "56px", fontWeight: "bold", lineHeight: 1.2 }}>{metadata.title}</div>
        <div style={{ color: "#777", fontSize: "24px", marginTop: "24px" }}>{metadata.description}</div>
      </div>
    ),
    { ...size }
  );
}
```

### Pattern 3: Google Search Console Verification via Metadata
**What:** Use Next.js metadata `verification` property to add Google site verification meta tag.
**When to use:** Once user provides verification code.
**Example:**
```typescript
// Source: https://nextjs.org/docs/app/api-reference/functions/generate-metadata

// In layout.tsx metadata export:
export const metadata: Metadata = {
  // ...existing metadata...
  verification: {
    google: "YOUR_VERIFICATION_CODE_HERE",
  },
};
```

### Pattern 4: Article JSON-LD for Blog Posts
**What:** Add Article structured data to each blog post for enhanced search results.
**When to use:** Every blog post.
**Example:**
```typescript
// In blog/[slug]/page.tsx
const articleJsonLd = {
  "@context": "https://schema.org",
  "@type": "Article",
  headline: metadata.title,
  description: metadata.description,
  datePublished: metadata.date,
  dateModified: metadata.date,
  author: {
    "@type": "Person",
    name: "Richard Parr",
    url: "https://github.com/richyparr",
  },
  publisher: {
    "@type": "Organization",
    name: "Tokemon",
    url: "https://tokemon.ai",
  },
  mainEntityOfPage: `https://tokemon.ai/blog/${slug}`,
};
```

### Anti-Patterns to Avoid
- **Using next-mdx-remote for local content:** It is poorly maintained, has unstable RSC support, and evaluates MDX on the client (security risk). Use `@next/mdx` for local files.
- **CMS for 3-5 posts:** Massive over-engineering. MDX in git gives version control, PR reviews, and zero hosting costs.
- **Forgetting `mdx-components.tsx`:** @next/mdx will NOT work without this file at the project root. It is mandatory.
- **Client-side syntax highlighting:** Use build-time highlighting (rehype-pretty-code/Shiki) to avoid shipping large JS bundles.
- **Duplicate meta tags:** The existing layout.tsx has `other: { "theme-color": "#000000" }` -- ensure blog post metadata merges, not duplicates.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Markdown rendering | Custom parser | `@next/mdx` | Handles JSX in markdown, server components, tree-shaking |
| Prose typography | Custom CSS for h1-h6, p, ul, ol, blockquote | `@tailwindcss/typography` | 50+ element styles, dark mode (`prose-invert`), theme customization |
| Syntax highlighting | Custom highlighter or client-side lib | `rehype-pretty-code` (Shiki) | VS Code themes, build-time rendering, zero client JS, line highlighting |
| OG image generation | Canvas/image manipulation | `next/og` ImageResponse | Edge-optimized, automatic caching, JSX template syntax |
| Frontmatter parsing | Regex/custom YAML parser | `gray-matter` or MDX exports | Battle-tested, handles edge cases (multiline values, special chars) |
| Sitemap generation | Manual XML | Next.js `sitemap.ts` (already exists) | Type-safe, auto-generates, integrated with build |

**Key insight:** The Next.js MDX ecosystem has matured significantly. Every piece of blog infrastructure (rendering, styling, highlighting, metadata, OG images, sitemaps) has a zero-config or near-zero-config solution. Custom implementations waste time and introduce bugs.

## Common Pitfalls

### Pitfall 1: next.config.ts vs next.config.mjs for MDX
**What goes wrong:** `@next/mdx`'s `createMDX` wrapper uses ESM syntax. If your config is `.ts`, you need to handle the import differently.
**Why it happens:** The project currently uses `next.config.ts`. The `createMDX` function is ESM.
**How to avoid:** Rename to `next.config.mjs` or use the TypeScript-compatible import pattern. With Next.js 16, `.ts` config files work but may need careful ESM handling for remark/rehype plugins.
**Warning signs:** Build errors mentioning "Cannot use import statement outside a module."

### Pitfall 2: Missing mdx-components.tsx
**What goes wrong:** @next/mdx silently fails or throws cryptic errors without the `mdx-components.tsx` file at the project root (same level as `src/`).
**Why it happens:** It is a mandatory convention file for App Router MDX.
**How to avoid:** Create `mdx-components.tsx` at the project root BEFORE configuring next.config. Can start with an empty component map.
**Warning signs:** MDX pages render as blank or throw "useMDXComponents is not defined."

### Pitfall 3: Sitemap Not Including Blog Posts
**What goes wrong:** New blog pages are not in the sitemap, so Google does not discover them.
**Why it happens:** Current `sitemap.ts` returns only the homepage. Blog posts need to be added dynamically.
**How to avoid:** Update `sitemap.ts` to enumerate blog post slugs and generate entries for each.
**Warning signs:** Google Search Console shows only 1 indexed URL after content is published.

### Pitfall 4: Subtree Split Deploy Complexity
**What goes wrong:** The deploy workflow uses `git subtree split --prefix=tokemon-site` which means the deployed repo only contains the `tokemon-site/` directory. Paths must be relative to that subtree.
**Why it happens:** Monorepo with macOS app code and site code together.
**How to avoid:** Keep all blog content within the `tokemon-site/` directory. The `content/` directory should be at `tokemon-site/content/`, not at the repo root.
**Warning signs:** Build failures on Vercel about missing content files.

### Pitfall 5: Tailwind v4 Typography Plugin Syntax
**What goes wrong:** Using `require('@tailwindcss/typography')` in a JS config file -- Tailwind v4 uses CSS-based plugin loading.
**Why it happens:** Old documentation references v3 syntax.
**How to avoid:** In Tailwind v4, add `@plugin "@tailwindcss/typography";` to your CSS file (globals.css), NOT in a config file.
**Warning signs:** `prose` classes have no effect.

### Pitfall 6: rehype/remark Plugin Turbopack Compatibility
**What goes wrong:** Plugins with function options fail when using Turbopack (`next dev --turbopack`).
**Why it happens:** Turbopack requires serializable plugin options (no JS functions).
**How to avoid:** Use string-based plugin references in next.config when targeting Turbopack: `remarkPlugins: ['remark-gfm']` instead of `remarkPlugins: [remarkGfm]`.
**Warning signs:** "Cannot serialize plugin" errors during dev.

## Code Examples

### next.config.mjs with MDX and Plugins
```javascript
// Source: https://nextjs.org/docs/app/guides/mdx
import createMDX from '@next/mdx'

/** @type {import('next').NextConfig} */
const nextConfig = {
  pageExtensions: ['js', 'jsx', 'md', 'mdx', 'ts', 'tsx'],
}

const withMDX = createMDX({
  options: {
    remarkPlugins: [
      'remark-gfm',
    ],
    rehypePlugins: [
      'rehype-slug',
      ['rehype-pretty-code', { theme: 'one-dark-pro' }],
      ['rehype-autolink-headings', { behavior: 'wrap' }],
    ],
  },
})

export default withMDX(nextConfig)
```

### mdx-components.tsx (Required)
```typescript
// Source: https://nextjs.org/docs/app/guides/mdx
import type { MDXComponents } from 'mdx/types'

export function useMDXComponents(): MDXComponents {
  return {
    // Custom component overrides can go here
    // e.g., img: (props) => <Image {...props} />
  }
}
```

### Blog Index Page
```typescript
// app/blog/page.tsx
import fs from 'fs';
import path from 'path';
import Link from 'next/link';
import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Blog | Tokemon',
  description: 'Guides and tips for monitoring Claude Code usage, avoiding rate limits, and optimizing your AI development workflow.',
};

async function getPosts() {
  const contentDir = path.join(process.cwd(), 'content', 'blog');
  const files = fs.readdirSync(contentDir).filter(f => f.endsWith('.mdx'));

  const posts = await Promise.all(
    files.map(async (file) => {
      const slug = file.replace('.mdx', '');
      const { metadata } = await import(`@/content/blog/${slug}.mdx`);
      return { slug, ...metadata };
    })
  );

  return posts.sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());
}

export default async function BlogIndex() {
  const posts = await getPosts();
  return (
    <main className="max-w-3xl mx-auto px-6 py-24">
      <h1 className="text-4xl font-bold mb-12">Blog</h1>
      {posts.map((post) => (
        <Link key={post.slug} href={`/blog/${post.slug}`} className="block mb-8 group">
          <h2 className="text-xl font-semibold group-hover:text-[#e8853b] transition-colors">{post.title}</h2>
          <p className="text-[#777] mt-1">{post.description}</p>
          <time className="text-sm text-[#555] mt-2 block">{post.date}</time>
        </Link>
      ))}
    </main>
  );
}
```

### Updated sitemap.ts with Blog Posts
```typescript
// app/sitemap.ts
import type { MetadataRoute } from "next";
import fs from "fs";
import path from "path";

export default function sitemap(): MetadataRoute.Sitemap {
  const contentDir = path.join(process.cwd(), "content", "blog");
  const blogSlugs = fs.existsSync(contentDir)
    ? fs.readdirSync(contentDir).filter(f => f.endsWith(".mdx")).map(f => f.replace(".mdx", ""))
    : [];

  return [
    {
      url: "https://tokemon.ai",
      lastModified: new Date(),
      changeFrequency: "weekly",
      priority: 1,
    },
    {
      url: "https://tokemon.ai/blog",
      lastModified: new Date(),
      changeFrequency: "weekly",
      priority: 0.8,
    },
    ...blogSlugs.map((slug) => ({
      url: `https://tokemon.ai/blog/${slug}`,
      lastModified: new Date(),
      changeFrequency: "monthly" as const,
      priority: 0.7,
    })),
  ];
}
```

## Content Strategy

### Priority Content Topics (by search intent & competition)

| Priority | Topic | Target Keywords | Search Intent | Type |
|----------|-------|----------------|---------------|------|
| 1 | How to track Claude Code usage | "track claude code usage", "claude code usage monitor", "claude token tracker" | Informational -> Commercial | Guide |
| 2 | How to avoid Claude rate limits | "claude rate limit", "avoid claude rate limits", "claude code rate limit workaround" | Problem-solving | Guide |
| 3 | Claude token monitoring guide | "claude token usage", "monitor claude tokens", "claude usage analytics" | Informational | Guide |
| 4 | Tokemon vs ccusage | "ccusage alternative", "claude usage tracker comparison" | Commercial | Comparison |
| 5 | Tokemon vs ClaudeBar | "claudebar alternative", "claude menu bar app" | Commercial | Comparison |

### Competitor Landscape (as of 2026-03)
| Competitor | Type | Key Differentiator | Tokemon Advantage |
|-----------|------|-------------------|-------------------|
| ccusage | CLI tool | JSONL analysis, 4.8k stars | GUI, real-time, menu bar, not CLI-only |
| ClaudeBar | macOS menu bar | Multi-provider (Claude, Codex, Gemini) | More features (forecasting, budget, export, team) |
| ClaudeMeter | macOS menu bar | Lightweight | More comprehensive analytics |
| Usage4Claude | macOS menu bar | Simple usage display | Multi-profile, project breakdown, team features |
| SessionWatcher | macOS menu bar | Zero-click visibility | Raycast integration, terminal statusline |
| CUStats | macOS + iOS + Android | Cross-platform | Native Swift perf, more analytics depth |
| Claude-Code-Usage-Monitor | CLI terminal | ML predictions, Rich UI | GUI + Raycast + terminal, no terminal dependency |
| ClaudeUsageBar | macOS menu bar (free) | Free, open source | Both free AND feature-rich |

### Distribution Channels
| Channel | Priority | Status | Action |
|---------|----------|--------|--------|
| Google Search Console | P0 | Blocked (needs user verification) | Add verification meta tag, submit sitemap |
| Product Hunt | P1 | Not submitted | Prepare launch page, schedule submission |
| Raycast Community | P1 | Not submitted | Submit extension to Raycast Store |
| AlternativeTo | P2 | Not listed | Create listing under Claude alternatives |
| GitHub awesome-lists | P2 | Not submitted | PR to awesome-claude, awesome-macos, awesome-claude-code |
| Hacker News | P3 | Not submitted | Show HN post (timing matters) |
| Dev.to / Hashnode | P3 | Not posted | Cross-post blog articles |

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Contentlayer for content | Content Collections or Velite or @next/mdx | 2024 (Contentlayer abandoned) | Use @next/mdx for small sites, Velite for larger ones |
| next-mdx-remote | @next/mdx with dynamic imports | 2024 (RSC matured) | No client JS, proper server component support |
| next-seo package | Built-in Next.js Metadata API | Next.js 13+ (2023) | No external package needed, type-safe |
| @vercel/og standalone | next/og built-in | Next.js 14+ | ImageResponse built into next/og, simpler imports |
| Tailwind v3 plugin config | Tailwind v4 CSS `@plugin` directive | 2024 | Typography plugin loaded via CSS, not JS config |
| FAQPage schema for all | FAQPage restricted to health/gov | 2024 | Don't use FAQ schema on developer tool pages |

**Deprecated/outdated:**
- **Contentlayer:** Unmaintained since mid-2024, do not use
- **next-mdx-remote:** Poorly maintained, unstable RSC, security concerns
- **next-seo package:** Unnecessary with Next.js built-in Metadata API
- **FAQPage schema:** Restricted by Google to government and health sites only

## Open Questions

1. **Google Search Console verification code**
   - What we know: User needs to provide the verification meta tag content
   - What's unclear: When user will provide it
   - Recommendation: Make it the first task -- add `verification.google` to layout.tsx metadata once received, then submit sitemap

2. **Ahrefs MCP availability**
   - What we know: User's CLAUDE.md mentions using "Ahrefs MCP for competitor keyword research." The phase goal mentions "keyword research via Ahrefs."
   - What's unclear: Ahrefs MCP is NOT configured in the project. No MCP config files found.
   - Recommendation: Flag to user that Ahrefs MCP setup is needed for keyword research. Content topics can be planned without it based on web search competitor analysis, but Ahrefs would provide search volume data.

3. **Blog content volume**
   - What we know: CONTEXT.md suggests 2-3 articles. The competitive landscape suggests comparison pages too.
   - What's unclear: How many articles the user wants to write in this phase
   - Recommendation: Start with 3 guides + 2 comparison pages (5 total). Keep the system extensible.

4. **Navigation updates**
   - What we know: Current nav only has "GitHub" and "Download" links. Blog needs a nav link.
   - What's unclear: Whether to add "Blog" to top nav or create a more structured nav
   - Recommendation: Add a "Blog" link to the existing nav bar -- keep it minimal

5. **Landing page copy improvements**
   - What we know: Phase goal mentions "landing page copy improvements"
   - What's unclear: What specifically needs improving -- the existing copy is comprehensive
   - Recommendation: Focus on adding internal links from blog back to landing page, and ensuring landing page h1/h2 tags target primary keywords

## Validation Architecture

> config.json does not have `workflow.nyquist_validation` set. Treating as enabled.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Playwright 1.58.2 |
| Config file | `tokemon-site/playwright.config.ts` |
| Quick run command | `cd tokemon-site && npx playwright test --project="Desktop Chrome"` |
| Full suite command | `cd tokemon-site && npx playwright test` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SEO-01 | Blog index page loads and lists posts | E2E | `npx playwright test e2e/blog.spec.ts --project="Desktop Chrome" -x` | No -- Wave 0 |
| SEO-02 | Blog post page renders MDX content | E2E | `npx playwright test e2e/blog.spec.ts --project="Desktop Chrome" -x` | No -- Wave 0 |
| SEO-03 | Blog post has correct meta tags and OG image | E2E | `npx playwright test e2e/blog-seo.spec.ts --project="Desktop Chrome" -x` | No -- Wave 0 |
| SEO-04 | Sitemap includes blog post URLs | E2E | `npx playwright test e2e/sitemap.spec.ts --project="Desktop Chrome" -x` | No -- Wave 0 |
| SEO-05 | Navigation includes Blog link | E2E | `npx playwright test e2e/landing-page.spec.ts --project="Desktop Chrome" -x` | Partial -- existing tests may break |
| SEO-06 | Comparison pages render correctly | E2E | `npx playwright test e2e/compare.spec.ts --project="Desktop Chrome" -x` | No -- Wave 0 |

### Sampling Rate
- **Per task commit:** `cd tokemon-site && npx playwright test --project="Desktop Chrome" -x`
- **Per wave merge:** `cd tokemon-site && npx playwright test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `e2e/blog.spec.ts` -- covers SEO-01, SEO-02
- [ ] `e2e/blog-seo.spec.ts` -- covers SEO-03 (meta tags, OG, JSON-LD)
- [ ] `e2e/sitemap.spec.ts` -- covers SEO-04
- [ ] `e2e/compare.spec.ts` -- covers SEO-06
- [ ] Update existing `e2e/landing-page.spec.ts` for nav changes -- covers SEO-05

## Sources

### Primary (HIGH confidence)
- [Next.js MDX Guide](https://nextjs.org/docs/app/guides/mdx) - Complete MDX setup, @next/mdx configuration, dynamic imports, frontmatter, plugins
- [Next.js generateMetadata](https://nextjs.org/docs/app/api-reference/functions/generate-metadata) - Dynamic metadata, verification property, OG images
- [Next.js Metadata and OG images](https://nextjs.org/docs/app/getting-started/metadata-and-og-images) - ImageResponse, opengraph-image.tsx convention

### Secondary (MEDIUM confidence)
- [Tailwind Typography Plugin](https://github.com/tailwindlabs/tailwindcss-typography) - v4 CSS plugin syntax verified
- [rehype-pretty-code docs](https://rehype-pretty.pages.dev/) - Shiki-based syntax highlighting, build-time
- [Ahrefs MCP Server](https://github.com/ahrefs/ahrefs-mcp-server) - Official Ahrefs MCP integration
- [Competitor comparison page strategy](https://www.rocktherankings.com/competitor-comparison-landing-pages/) - SaaS comparison page patterns

### Tertiary (LOW confidence)
- Competitor tool landscape (gathered from GitHub and web search -- exact feature parity claims need validation)
- Search volume estimates for target keywords (no Ahrefs data available; inferred from number of competing articles)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Official Next.js docs verified, @next/mdx is the recommended approach
- Architecture: HIGH - Dynamic imports + generateStaticParams is documented pattern from Next.js official guides
- Content strategy: MEDIUM - Based on competitor analysis and common SEO patterns, but lacks Ahrefs keyword volume data
- Pitfalls: HIGH - Each pitfall verified against official docs or confirmed by multiple sources
- Competitor landscape: MEDIUM - GitHub repos and landing pages verified, but feature claims not hands-on tested

**Research date:** 2026-03-08
**Valid until:** 2026-04-08 (30 days - ecosystem is stable)
