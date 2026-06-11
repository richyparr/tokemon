# Tokemon Site — Pre-Launch UI/UX Review
**Date:** 2026-06-10 · **Scope:** `tokemon-site/` (Next.js 16 App Router, Tailwind v4, deployed at tokemon.ai)
**Method:** Full source read of every route, component, lib, and content file; design-token calibration first; all critical/high findings verified against the code (parent layouts, shared wrappers, `mdx-components.tsx`) before inclusion.

---

## Executive Summary

The site is a static marketing/content platform: landing page, blog (8 MDX posts + tag pages), comparison pages (4), three SEO/tool pages, and a support page. There is no auth, admin, or email surface — **everything is externally facing and therefore launch-critical**.

The good news: the fundamentals are unusually solid for a solo project. SEO plumbing (canonicals, JSON-LD, OG images, static generation with `dynamicParams = false`), CLS discipline on the landing page, fair-minded compare copy, and an exemplary support page (`/keychain-access`) are all genuinely strong. Nothing here is broken-on-load.

The bad news clusters into four themes:

1. **Mobile is the weakest dimension on a site whose traffic is mobile-heavy SEO.** The brew install command — the single most important string on the site — is clipped and uncopyable on small phones. Comparison tables and the 6-column pricing table have no horizontal-scroll wrapper inside a body with `overflow-x-hidden`, so they squash or clip. The nav collapses to logo + Download with no menu.
2. **No safety net.** There is no `not-found.tsx` or `error.tsx`; bad slugs land on Next's default 404 inside the dark layout — near-invisible text, no nav, no recovery path.
3. **Internal navigation dead ends and broken links.** The blog index has no header/nav at all; compare-page tag chips link to blog tag routes that hard-404.
4. **Credibility risks in content.** Stale model pricing on a page titled "2026", a "calculator" promised in meta that doesn't exist, and at least one likely-wrong "No" in the ccusage comparison table — the exact audience that will publicly correct it.

There is also a design-system vacuum: `globals.css` defines only fonts, so the same role is expressed with three different border grays and two different button hover treatments across surfaces, and `#666`-on-near-black small text (~3.5:1) recurs everywhere.

**Verdict: launchable after ~1–2 days of focused fixes.** Nothing requires redesign; the top 10 below are mostly small, surgical changes.

---

## Per-Surface Scorecard

| Surface | Score | One-liner |
|---|---|---|
| Landing page (`/`) | **7/10** | Persuasive narrative, great CLS hygiene and InteractiveDemo; mobile install-command clipping, zero reduced-motion support, dead component tree |
| Blog (`/blog`, posts, tags) | **7/10** | Strong SEO scaffolding and content; index is a navigation dead end, tag taxonomy split, heading-link styling defect |
| Compare (`/compare`, 4 pages) | **7/10** | Fair, credible copy and correct routing; tag chips 404, tables unscrollable on mobile, ccusage accuracy risk |
| Tool pages (`/claude-code-cost`, `/claude-statusline`, `/keychain-access`) | **7/10** | Excellent metadata and the keychain page is exemplary; pricing table breaks on mobile, stale 2026 prices, phantom calculator |
| Site infrastructure (layout, 404, sitemap, headers) | **5/10** | Complete sitemap and good root metadata, but no custom 404/error page, no security headers, stale JSON-LD version, fake SearchAction |

---

## Top 10 Priorities Before Launch

1. **Fix the install command on mobile** — `src/app/TerminalInstall.tsx:16` uses `whitespace-nowrap overflow-x-hidden`; the 46-char brew command clips silently on ≤375px viewports. Change to `overflow-x-auto`, shrink font at `max-sm`, add a copy button. *(High, landing)*
2. **Add a table overflow wrapper in `mdx-components.tsx:3-5`** — currently returns `{}`. One `table: (p) => <div className="overflow-x-auto"><table {...p}/></div>` fixes every comparison and blog table on mobile at once. *(High, compare + blog)*
3. **Add `not-found.tsx` and `error.tsx`** — `src/app/` has neither (verified). `dynamicParams = false` on `[slug]`/`[tag]` routes means bad links land on the unstyled default 404 inside the dark body gradient. ~20 lines each, dark-styled, links to Home/Blog/Compare. *(High, infra)*
4. **Fix compare-page tag chips that 404** — `src/components/BlogLayout.tsx:62` links all tags to `/blog/tag/${tag}`, but tag params are built from blog content only (`src/lib/blog.ts:78`); compare tags like `ccusage`, `comparison` hard-404. De-link tags when `breadcrumbBase === "compare"` or merge compare tags into `getAllTags()`. *(High, compare)*
5. **Give the blog index a nav** — `src/app/blog/page.tsx:24-72` renders no header, logo, or footer; readers cannot reach the homepage without editing the URL. Extract the landing nav into a shared component used by all surfaces (also fixes per-page nav drift, see theme 4). *(High, blog)*
6. **Fix the pricing-table wrapper** — `src/app/claude-code-cost/page.tsx:140-167`: 6-column table inside `overflow-hidden`. Swap to `overflow-x-auto` or stack to cards below `md:`. *(High, tool pages)*
7. **Update 2026 pricing content** — `claude-code-cost/page.tsx:53,154-156` cites Opus 4 at $15/$75 and Sonnet 4 as current; both are stale, and the FAQ JSON-LD bakes the numbers into rich results. Wrong prices on a cost-tracker's site is the worst possible credibility hit. Add a visible "Last updated" date. *(High, tool pages)*
8. **Re-verify the ccusage comparison table** — `content/compare/tokemon-vs-ccusage.mdx`: "Real-time monitoring: No" and "Burn rate: No" are likely wrong (`ccusage blocks --live` exists). Soften to "Limited — terminal-only live view". *(High, compare)*
9. **Resolve the calculator promise** — `claude-code-cost/page.tsx:10,21` meta promises "a real-world calculator"; the page has none. Either build a small client calculator or remove "calculator" from meta/keywords. *(High, tool pages)*
10. **Add `prefers-reduced-motion` support** — none exists anywhere: looping h1 typing (`src/components/TextType.tsx`), infinite InteractiveDemo cycle (`src/app/InteractiveDemo.tsx:319-345`), FadeContent, PixelBlast. The endlessly retyping headline is a WCAG 2.2.2 failure on the most prominent element. One shared `useReducedMotion` hook. *(High, landing/a11y)*

---

## Cross-Cutting Themes

### 1. Mobile gets the worst of everything
The traffic profile (SEO landings, links shared from terminals/Reddit) skews mobile, yet: the install command clips (`TerminalInstall.tsx:16`), tables clip or squash (empty `mdx-components.tsx`, `overflow-hidden` pricing wrapper), the nav drops to logo + Download with no menu on every page (`hidden sm:inline`, e.g. `src/app/page.tsx:182-190`, `claude-code-cost/page.tsx:110-112`), and — strangest of all — the three.js/postprocessing WebGL background renders **only** on mobile (`src/app/HeroBackground.tsx:18` `if (!isMobile) return null`), putting the heaviest JS on the weakest devices as a 40%-opacity decoration, with no try/catch around renderer creation (`PixelBlast.tsx:442-446`) and no reduced-motion gate. The body's `overflow-x-hidden` (`layout.tsx:134`) turns every overflow bug into silent clipping rather than an ugly-but-usable scroll.

### 2. No failure states
No `not-found.tsx`, no `error.tsx`, no WebGL fallback, no OG-image text clamping (`blog/[slug]/opengraph-image.tsx:44-62`, `compare/[slug]/opengraph-image.tsx`). Because the site is fully static (correct `generateStaticParams` everywhere), `loading.tsx` is genuinely unnecessary — but the 404 path will be seen by real users and is currently embarrassing.

### 3. Design-token vacuum → value drift
`globals.css` defines only font variables. Consequences, same role / different values: card borders `#1a1a1a` (`page.tsx:410`) vs `#222` (`blog/page.tsx:51`, `BlogLayout.tsx:84`) vs `#252525` (`TerminalInstall.tsx:7`); secondary-button borders `#1a1a1a→#333` (`HeroCTA.tsx:21`) vs `#252525→#444` (`page.tsx:439`); primary-button hover `hover:opacity-85` vs `hover:bg-white`; accent both `#e8853b` and `#f0a060`; radii mix `rounded-lg/xl/2xl/[5px]`. Fix: define `--color-border`, `--color-border-strong`, `--color-card`, `--color-accent`, `--color-text-secondary/tertiary` in a Tailwind v4 `@theme` block and sweep.

### 4. Copy-pasted chrome with drift
Every page re-implements nav and footer inline. Drift already shipped: keychain nav drops Compare and Download (`keychain-access/page.tsx:30-31` vs `claude-code-cost/page.tsx:110-116`); a fully dead parallel component tree (`src/components/Hero.tsx`, `Nav.tsx`, `Footer.tsx`, `FeaturesGrid.tsx`, `FeatureSection.tsx`, `InAction.tsx` — imported by nothing, referencing tokens that don't exist, and stating "5 menu bar styles" vs the live page's "6") is one accidental import away from rendering broken. Extract `<SiteNav/>`/`<SiteFooter/>`, delete the six dead files.

### 5. Low-contrast tertiary text everywhere
`text-[#666]` on `#000`/`#0a0a0a`/`#111` (~3.4–3.6:1, below WCAG AA 4.5:1 for small text) appears on dates (`blog/page.tsx:34`), the load-bearing pricing disclaimer (`claude-code-cost/page.tsx:169`), related-post descriptions (`BlogLayout.tsx:89`), footers, and the InteractiveDemo's only affordance hint at 9px `text-white/25` (`InteractiveDemo.tsx:414`). Global fix: tertiary text ≥ `#8a8a8a`.

### 6. Structured-data debt
Fake SearchAction targeting a `q` param no page reads (`layout.tsx:112-114`); step-less `HowTo` schema that fails validation (`blog/[slug]/page.tsx:208-223`); `softwareVersion: "4.0.0"` vs shipped 4.1.10 (`layout.tsx:83`); two competing OG-image systems per dynamic route (file-convention `opengraph-image.tsx` wins for OG, the explicit `/api/og?...` URL still feeds Twitter cards — two different designs ship simultaneously, `blog/[slug]/page.tsx:25,38,44` and `compare/[slug]/page.tsx:25-26`).

---

## Full Findings by Surface

### Landing page (`/`) — 7/10

**High**
- **Three.js background ships only to mobile, with no failure guard** — `src/app/HeroBackground.tsx:18` + `src/components/PixelBlast.tsx:442-446`. Heavy WebGL (three + postprocessing, `powerPreference: 'high-performance'`) renders exclusively below 768px; `new THREE.WebGLRenderer` is never try/caught and there's no `prefers-reduced-motion` check. → Replace with static CSS texture on mobile, or gate on reduced-motion, wrap renderer creation in try/catch, dynamic-import.
- **Install command clipped and uncopyable on small phones** — `src/app/TerminalInstall.tsx:16` (`whitespace-nowrap overflow-x-hidden`; ~360px of 13px mono in a ≤375px viewport, body clips the tail). → `overflow-x-auto`, smaller font at `max-sm`, copy-to-clipboard button; render command statically with animation as enhancement.
- **No `prefers-reduced-motion` anywhere** — `TextType.tsx` (h1 retypes forever — WCAG 2.2.2), `InteractiveDemo.tsx:319-345` (infinite auto-cycle, no pause), `FadeContent.tsx`, `PixelBlast.tsx`. → Shared `useReducedMotion` hook; static first phrase, frozen demo final frame.

**Medium**
- **Dead parallel component tree with drifted content** — `src/components/{Hero,Nav,Footer,FeaturesGrid,FeatureSection,InAction}.tsx` imported by nothing; reference nonexistent tokens (`text-secondary-text`, `bg-card` — `Hero.tsx:13`, `Nav.tsx:12`, `FeaturesGrid.tsx:21`); FeaturesGrid says "5 menu bar styles" vs live "6" (`page.tsx:104`). → Delete all six.
- **Raycast install instructions are broken commands** — `page.tsx:357` renders `git clone && cd tokemon-raycast && …` (no URL — errors verbatim); closing CTA `page.tsx:432` shows a meaningless standalone `$ npm run dev`. → Real clone URL or Raycast Store link in both places.
- **Mobile nav offers only Download** — `page.tsx:182-190`, Blog/Compare/GitHub all `hidden sm:inline`, no hamburger. → Keep Blog visible or add a disclosure menu.
- **InteractiveDemo a11y self-contradiction** — `InteractiveDemo.tsx:381-382` `role="img"` on a container holding a real `<button>` (:113); affordance hint at 9px `text-white/25` (:414) is effectively invisible. → Drop `role="img"`, raise hint to ≥12px `text-white/60`.
- **Hardcoded value drift** — `HeroCTA.tsx:13,21` vs `page.tsx:433,439` (see theme 3). → Tokenize.
- **Fixed-pixel hero h1 heights are brittle** — `page.tsx:206` `h-[130px] sm:h-[155px] md:h-[140px] lg:h-[160px]`; wrap changes at ~640–700px or user font overrides clip/overlap. → em-based `min-h` tied to line count.

**Low**
- Raw emoji feature icons (🔔 📊 👥 🎨 🌗) render off-brand cross-platform — `page.tsx:103-110`. → Inline SVGs.
- Single-star "loved by developers" badge reads as a fake rating — `page.tsx:225-230`. → Real GitHub star count or cut.
- JSON-LD `softwareVersion: "4.0.0"` stale — `layout.tsx:83`. → Derive from a constant.
- No skip-to-content link under the fixed nav — `page.tsx:177`.

### Blog — 7/10

**High**
- **Index is a navigation dead end** — `blog/page.tsx:24-72` + `layout.tsx:120-142`: no nav, logo, breadcrumb, or footer; zero links off the page except into posts. → Shared header in root layout (also see theme 4).
- **Fake SearchAction structured data** — `layout.tsx:112-114` targets `/blog?q=…` but `BlogIndex` reads no `searchParams` (verified). → Remove the `potentialAction` block.
- **Split tag taxonomy → near-empty tag pages and ugly URLs** — kebab-case tags (`how-to-track-claude-code-usage.mdx:7`) vs keyphrase tags (`claude-rate-limits-explained.mdx:7`) yield ~20 mostly-1-post tags and percent-encoded canonical URLs (`/blog/tag/claude%20rate%20limits`, `tag/[tag]/page.tsx:24`). → Normalize to 5–8 kebab-case tags, slugify URLs, human-readable labels.
- **Headings render as underlined orange links** — `next.config.mjs:14` (`rehype-autolink-headings`, `behavior: "wrap"`) + `BlogLayout.tsx:70` (`prose prose-invert prose-orange` styles all `a` in prose). Every h2/h3 in every post becomes a styled link. CSS chain verified; confirm visually. → `behavior: "append"` with styled `#` anchor, or scoped `prose` overrides for heading anchors.

**Medium**
- **Two competing OG image systems** — `blog/[slug]/opengraph-image.tsx` (wins for `og:image`) vs `/api/og?…` in `blog/[slug]/page.tsx:25,38,44` (still feeds Twitter card). Different designs ship to different platforms. → Pick one (suggest `/api/og`), delete the other.
- **Invalid step-less HowTo JSON-LD** — `blog/[slug]/page.tsx:208-223`; HowTo requires `step`, and Google deprecated HowTo rich results anyway. → Remove.
- **`text-[#666]` small text below AA** — `blog/page.tsx:34,61`, `BlogLayout.tsx:89`. → ≥ `#8a8a8a`.
- **No custom 404** — bad slugs (correctly `dynamicParams = false`, `[slug]/page.tsx:7`, `[tag]/page.tsx:5`) land on the unstyled default. → `not-found.tsx`.
- **Border drift + flattened background** — `border-[#222]` vs landing `#1a1a1a`; index uses solid `bg-[#0a0a0a]` (`blog/page.tsx:24`) killing the body gradient. → Tokenize; drop the solid bg.
- **No reading time** — `src/lib/blog.ts` already reads each file; word-count is free. → Render "X min read" beside the date.

**Low**
- BMC link lacks `target="_blank" rel="noopener"` — `BlogLayout.tsx:114-119`.
- `dateModified` always equals `datePublished` — `blog/[slug]/page.tsx:164`. Add optional `updated` frontmatter.
- UTC date off-by-one risk in `toLocaleDateString` — `blog/page.tsx:38`, `BlogLayout.tsx:18`. Pass `timeZone: "UTC"`.
- "Related Posts" is an `h3` sibling to the article `h1` — `BlogLayout.tsx:78`. Use `h2`.
- OG title/description unclamped — `blog/[slug]/opengraph-image.tsx:44-62`.

### Compare — 7/10

**High**
- **Tag chips 404** — `BlogLayout.tsx:62` → `/blog/tag/${tag}`, but tag routes are built from blog content only (`blog.ts:78`, `tag/[tag]/page.tsx:5-10` with `dynamicParams = false`). Compare-only tags (`comparison`, `ccusage`, `claudebar`, `claude console`, `usage monitoring`, …) hard-404 from every compare page header. Verified: only `claude-code`, `usage-tracking`, `tokemon` overlap. → De-link on compare, or merge compare tags into `getAllTags()`.
- **No table overflow wrapper** — `mdx-components.tsx:3-5` returns `{}` (verified); 15-row × 3-col tables inside `max-w-3xl px-6` with body `overflow-x-hidden`. The tables are the centerpiece. → `table` override with `overflow-x-auto` wrapper.
- **ccusage table accuracy risk** — `content/compare/tokemon-vs-ccusage.mdx`: "Real-time monitoring: No", "Burn rate & time remaining: No" — ccusage ships `blocks --live` with both. The ccusage community will read this page. → Re-verify every row; soften to "Limited — terminal live view".

**Medium**
- **"Download Tokemon" CTAs go to the homepage hero** — absolute `https://tokemon.ai` links in MDX footers (`tokemon-vs-ccusage.mdx:73` etc.) and `href="/"` in `BlogLayout.tsx:113`. Converting visitors must re-find the download. → Link a download anchor or GitHub release.
- **Two competing OG image systems** — same as blog: `compare/[slug]/opengraph-image.tsx` vs `/api/og` in `compare/[slug]/page.tsx:25-26`. → Pick one.
- **"15–30 minutes per day" manual-tracking claim strains credibility** — `tokemon-vs-manual-tracking.mdx`. → "A few minutes a day, plus the cost spike you don't catch."
- **API vs subscription framing inconsistency** — manual-tracking page talks "API spend / credentials"; rest of site talks Claude Code plan limits. → Align terminology.
- **ClaudeBar description vague and unlinked** — `tokemon-vs-claudebar.mdx`; ccusage gets a link, ClaudeBar doesn't; seven "No" rows risk looking like a strawman. → Link the actual product, verify rows.

**Low**
- `/compare` index has no download CTA — `compare/page.tsx`.
- BMC button competes with the primary CTA on conversion pages — `BlogLayout.tsx:119`.
- `competitor` metadata field defined but never rendered — `compare.ts:11`.
- OG description unclamped — `compare/[slug]/opengraph-image.tsx`.

### Tool pages — 7/10

**High**
- **Pricing table breaks on mobile** — `claude-code-cost/page.tsx:140-167`: 6 columns incl. prose cells inside `overflow-hidden`. → `overflow-x-auto` or stacked cards below `md:`.
- **Phantom calculator** — `claude-code-cost/page.tsx:10,21` meta promises one; page has only static examples (:196-223) and a blog link (:267). → Build a small client calculator or strip the claim.
- **Stale prices on a "2026" page** — `claude-code-cost/page.tsx:53,154-156`: Opus 4 $15/$75, Sonnet 4 as current; FAQ JSON-LD (:73-81) bakes it into rich results. → Update; add visible "Last updated".

**Medium**
- **Mobile nav logo + Download only** — `claude-code-cost/page.tsx:110-112`, `claude-statusline/page.tsx:104-106`, `keychain-access/page.tsx:30-31`. → Shared nav (theme 4).
- **`#666` 12px text incl. the load-bearing price disclaimer** — `claude-code-cost/page.tsx:169,189,212,313`, `claude-statusline/page.tsx:137,141`, `keychain-access/page.tsx:132`. → ≥ `#8a8a8a`.
- **Per-page nav/footer drift** — keychain drops Compare/Download (`keychain-access/page.tsx:20-34,131-140` vs `claude-code-cost/page.tsx:100-116,312-322`). → Extract `<SiteNav/>`/`<SiteFooter/>`.

**Low**
- Statusline claims fish support but only shows zsh/bash setup — `claude-statusline/page.tsx:123,213` vs `:179-181,:51`. → fish snippet or soften.
- Keychain troubleshooting says "redo step 6"; Save is step 8 — `keychain-access/page.tsx:106`. → "steps 6–8".
- FAQ `+` toggles announced as "plus" by screen readers — `claude-code-cost/page.tsx:284`, `keychain-access/page.tsx:85`. → `aria-hidden="true"`.
- `runtime = "edge"` on the OG route is deprecated territory in Next 16 — `api/og/route.tsx:3`. → Node runtime.
- `<th>` missing `scope="col"` — `claude-code-cost/page.tsx:144-149`.

### Infrastructure — 5/10

**High**
- **No `not-found.tsx`, no `error.tsx`** — `src/app/` verified. Default 404's light-scheme text inside the dark body gradient (`layout.tsx:135`) → near-black on black, no nav, no recovery. → Add both, dark-styled.

**Medium**
- **No security headers** — `vercel.json` is `{"framework":"nextjs"}` only; `next.config.mjs` has no `headers()`. → Standard block: `X-Content-Type-Options`, `Referrer-Policy`, HSTS, frame protections.
- **Stale `softwareVersion: "4.0.0"`** — `layout.tsx:83` (app ships 4.1.10). → Single source of truth.
- **Fake SearchAction** — `layout.tsx:112-114` (see blog). → Remove.

---

## Quick Wins (<1h each)

1. `table` override with `overflow-x-auto` wrapper in `mdx-components.tsx` — fixes all blog + compare tables in one component.
2. `overflow-x-auto` on the pricing-table wrapper (`claude-code-cost/page.tsx:140`).
3. Dark `not-found.tsx` (+ minimal `error.tsx`), ~20 lines each.
4. Delete the six dead `src/components/` files (Hero, Nav, Footer, FeaturesGrid, FeatureSection, InAction).
5. Fix `git clone` URL + replace the closing-CTA `$ npm run dev` with a Raycast Store link (`page.tsx:357,432`).
6. Copy button + `overflow-x-auto` on `TerminalInstall.tsx`.
7. Delete the `potentialAction` SearchAction and the step-less HowTo JSON-LD; bump `softwareVersion`.
8. De-link tags on compare pages (conditional in `BlogLayout.tsx:62`).
9. Global sweep `text-[#666]` → `text-[#8a8a8a]` for small text.
10. Drop "calculator" from `claude-code-cost` meta; fix ccusage "No" rows; "step 6" → "steps 6–8" on keychain.
11. `target="_blank" rel="noopener"` on Buy-me-a-coffee links; `aria-hidden` on FAQ `+` spans; `scope="col"` on pricing `<th>`s.
12. Pick one OG-image system per route (suggest `/api/og`) and delete the file-convention duplicates.

---

## What's Already Strong

- **The InteractiveDemo is a standout** — a working, clickable simulation of the menu-bar product with live ticking usage, IntersectionObserver gating, timeout cleanup, and a static-image fallback on mobile (`page.tsx:262-271`). Communicates the value prop better than any screenshot.
- **CLS discipline is real**: reserved h1 heights, `aspect-ratio` on the demo, width/height on every `next/image`.
- **SEO plumbing is near-exemplary across all surfaces**: canonicals everywhere, Article/Breadcrumb/FAQ/SoftwareApplication JSON-LD, per-page OG/Twitter cards, complete dynamic sitemap (verified against all 8 posts + 4 compare slugs + tag pages), correct `generateStaticParams` + `dynamicParams = false` (which also makes missing `loading.tsx` a genuine non-issue — everything is static).
- **`/keychain-access` is an exemplary support page**: correctly `noindex,follow`, excluded from the sitemap, numbered steps mirroring the in-app flow, troubleshooting accordions for real failure modes, a "Still stuck?" escape hatch.
- **Compare copy is unusually fair** — every page has a genuine "when the competitor is better" section and complementary framing; exactly the right strategy for a dev-tool audience.
- **Native `<details>` FAQs** — keyboard- and SEO-friendly with zero JS.
- **Conversion path discipline on the landing page** — the install command appears at hero, Raycast section, and closing CTA; never more than one viewport away on desktop.
- **Blog content is genuinely useful** (clear h2/h3 hierarchy, GFM tables, `one-dark-pro` code highlighting) rather than SEO filler, with related-posts scored by shared tags.
