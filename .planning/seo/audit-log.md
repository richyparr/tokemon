---
name: Tokemon SEO Audit Log
description: Findings, fixes, and dates from SEO audits of tokemon.ai
target_domain: tokemon.ai
---

# Tokemon SEO Audit Log

## 2026-05-07 — Round 1: Foundational audit

Cross-referenced inventory from `tokemon-site/` against `keyword-research.md` (round 1).

### Top-line: SEO hygiene is strong

- ✅ Sitemap complete + correct priorities (1.0 / 0.8 / 0.7 / 0.5)
- ✅ Permissive `robots.txt` with sitemap reference
- ✅ Canonical URLs on every page
- ✅ Article + BreadcrumbList schemas on all blog/compare posts
- ✅ FAQPage schema on homepage
- ✅ All content substantial (blog avg 1,435 words; min 685)
- ✅ MDX (no `dangerouslySetInnerHTML` plain-text-link risk)
- ✅ Breadcrumbs and clear H1 hierarchy
- ✅ Internal linking good; no broken routes detected

So this is a **keyword-targeting and packaging audit**, not a hygiene rescue.

---

### Keyword-vs-page gap matrix

| Keyword | Vol | KD | Current page | Gap | Action |
|---------|-----|----|----|--------------|-----|--------|
| **claude usage tracker** | **350** | **12** | None directly — homepage targets "Claude Usage Monitor" | 🔴 Missing the lowest-KD/highest-TP term in our research | **Add "tracker" to homepage title + H1** |
| **claude code cost** | **3,100** | — | `/blog/claude-code-cost-calculator` (1,447 wd) | 🟡 Buried at `/blog/`; not a landing | **Promote to `/claude-code-cost` landing OR add canonical landing + keep blog as supporting** |
| **claude api cost** | 600 | 31 | `/blog/reduce-claude-api-costs` (TP **6,200**) | 🟡 Targets "reduce…costs" angle, not the head term | **Add a `/claude-api-cost` pillar** or rewrite blog title to lead with "Claude API Cost" |
| **claude statusline** | 400 | — | None | 🔴 Tokemon ships this feature with no page | **Build `/claude-statusline` landing (Path 3)** |
| claude usage monitor | 70 | — | Homepage (already in title) | ✅ Covered | Keep |
| claude code usage monitor | 350 | 31 | Homepage (close — uses "Claude Usage Monitor") | 🟡 Missing exact phrase | **Add "Claude Code" variant in H1 or subtitle** |
| claude rate limit | 150 | — | `/blog/claude-rate-limits-explained` | ✅ Title leads with "Claude Rate Limits" | Validate ranking via GSC |
| claude code rate limit | 100 | — | `/blog/claude-rate-limits-explained` | 🟡 Could be a separate cluster page | Consider sibling; low priority |
| claude session limit | 250 | — ($9 CPC) | `/blog/claude-rate-limits-explained` | 🟡 Buried in body | Add "session limit" H2 + FAQ entry; refresh title to mention it |
| claude weekly rate limit | 10 (trending) | — | None explicit | 🔴 New term — not yet covered | **Refresh `/blog/avoid-claude-rate-limits` to add weekly-limit H2** |
| how to track claude code usage | 10 | — | `/blog/how-to-track-claude-code-usage` | ✅ Exact match | Keep |
| best claude code tools | 10 | — | `/blog/best-claude-code-tools` | ✅ Covered, low-priority | Keep |
| claude max vs pro vs team | — | — | `/blog/claude-max-vs-pro-vs-team` | ✅ Covered | Keep |
| ccusage / claudebar / console alternative | 0 | — | `/compare/*` | ✅ Brand-defensive only | Keep — don't optimize for SEO |

---

### Tier 1 fixes (quick wins, do first)

#### Fix 1.1 — Homepage title + H1 retitle

**Why:** "Claude Usage Tracker" (350/mo, KD 12, $3 CPC, TP 1,400) is our lowest-difficulty / highest-opportunity keyword. The current title only contains "Monitor". The dynamic H1 ("Never hit a [rotating] by surprise again") contains zero ranking keywords.

**File:** `tokemon-site/src/app/layout.tsx`

```typescript
// BEFORE
title: "Tokemon — Claude Usage Monitor for macOS & Raycast",
description: "Free, open-source Claude usage monitor for macOS and Raycast. Track token limits, burn rate, per-project costs, and team budgets in real-time from your menu bar. Get alerts before you hit rate limits.",

// AFTER
title: "Tokemon — Claude Code Usage Tracker & Monitor for macOS",
description: "Free Claude usage tracker for macOS & Raycast. Real-time burn rate, per-project costs, team budgets, and rate-limit alerts — right in your menu bar.",
```

Title: 60 chars (down from 60 — same length, better keyword coverage of "tracker", "monitor", "claude code", "macOS"). Description: 161 chars — trim to 155.

**Homepage H1 (currently dynamic with HeroTyping):** Add a static H1 *above or below* the rotating element so crawlers and screen readers see a deterministic, keyword-rich H1.

**File:** `tokemon-site/src/components/...` (locate the homepage hero — likely `HeroTyping.tsx` or `Hero.tsx`)

```tsx
// Add a non-visual or visually-secondary <h1> with stable text:
<h1 className="sr-only">Claude Code Usage Tracker & Monitor for macOS</h1>
{/* keep the existing animated headline as a styled <h2> or <p role="heading"> */}
```

(Or replace the dynamic H1 entirely with a static keyword-led H1 and demote the rotating phrase to subhead.)

**Estimated impact:** Materially improves ranking signal for "claude usage tracker", "claude code usage tracker", and "claude code usage monitor".

---

#### Fix 1.2 — Promote `claude-code-cost-calculator` to a landing page

**Why:** "claude code cost" = 3,100/mo (largest in our research). Currently sits at `/blog/claude-code-cost-calculator` — buried under blog navigation, weaker internal linking, blog priority 0.7 vs landing 0.9.

**Recommendation (low-risk option):** Create `/claude-code-cost` as a NEW landing (calculator + cost breakdown + table). Keep the blog post as supporting content with a canonical pointing to the new landing **only if** the content overlaps significantly. Otherwise differentiate: landing = calculator + tables; blog = narrative guide.

**Action:** Open in **Path 3** (Create) — design + build the `/claude-code-cost` landing.

---

#### Fix 1.3 — Refresh rate-limits content with "session limit" + "weekly rate limit"

**Why:**
- "claude session limit" = 250/mo at $9 CPC (highest commercial intent in research)
- "claude weekly rate limit" = 10/mo and trending (Anthropic's new weekly cap)

Both currently buried in body of `/blog/claude-rate-limits-explained` and `/blog/avoid-claude-rate-limits`.

**Files:**
- `tokemon-site/src/content/blog/claude-rate-limits-explained.mdx`
- `tokemon-site/src/content/blog/avoid-claude-rate-limits.mdx`

**Edits:**

1. In `claude-rate-limits-explained.mdx`:
   - Add an H2: `## Claude session limit vs rate limit — what's the difference?`
   - Add FAQ block answering: "What is a Claude session limit?", "How long is a Claude session?", "When does my Claude session reset?"
   - Add `FAQPage` JSON-LD schema (currently only on homepage)

2. In `avoid-claude-rate-limits.mdx`:
   - Add an H2: `## Claude's new weekly rate limit (2026)` covering the weekly cap rollout
   - Update meta description to mention "weekly rate limit"
   - Add FAQ: "What is Claude's weekly rate limit?", "How is the weekly limit different from the 5-hour rolling window?"

**Estimated impact:** Captures session-limit ($9 CPC) traffic and front-runs the trending weekly-limit term.

---

#### Fix 1.4 — Add OG images for blog/compare/index pages

**Why:** All non-homepage pages are missing `openGraph.images`. Social shares (Twitter/LinkedIn/Reddit) show no preview, killing CTR from social/community traffic — which matters for a Claude-Code-audience product where Reddit and dev social drive a lot of awareness.

**Recommendation:** Vercel's `@vercel/og` for dynamic OG images. Generate at build/edge time using post title + Tokemon branding.

**File:** `tokemon-site/src/app/api/og/route.tsx` (new)

```tsx
import { ImageResponse } from "next/og";

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const title = searchParams.get("title") ?? "Tokemon";
  return new ImageResponse(
    (
      <div style={{ /* branded layout: dark bg, orange accent, Tokemon logo, title */ }}>
        {title}
      </div>
    ),
    { width: 1200, height: 630 }
  );
}
```

Then in each blog/compare page's `generateMetadata`:

```typescript
openGraph: {
  images: [`/api/og?title=${encodeURIComponent(metadata.title)}`],
},
```

**Estimated impact:** Higher social share CTR. Quantifiable via Vercel Analytics referrer breakdown.

---

### Tier 2 fixes (medium priority)

#### Fix 2.1 — Build `/claude-statusline` landing (Path 3)

**Why:** 400/mo, no significant competition, Tokemon ships exactly this feature. Tier 1 keyword we have no page for.

**Action:** Open in **Path 3**.

---

#### Fix 2.2 — Tighten blog post titles to ≤60 chars

**Why:** Several blog titles run 69–72 chars with `| Tokemon` suffix; Google truncates around 60. Risk: keyword-rich tail of the title gets cut off on mobile SERP.

**Examples:**

| Current (too long) | Suggested (≤60 chars) |
|---|---|
| Understanding Claude Rate Limits: The Complete 2026 Guide \| Tokemon (72) | Claude Rate Limits Explained: The Complete 2026 Guide (52) |
| The Complete Guide to Claude Token Usage Monitoring \| Tokemon (71) | Claude Token Usage Monitoring: Complete Guide (45) |
| How to Avoid Claude Rate Limits: A Developer's Guide \| Tokemon (69) | How to Avoid Claude Rate Limits in 2026 (40) |
| Best Claude Code Extensions and Tools for Developers in 2026 \| Tokemon (78) | Best Claude Code Tools & Extensions (2026) (44) |

Strip "| Tokemon" from blog post titles globally — Google appends the site name automatically when relevant. Add "2026" where natural for freshness signal.

**Where to change:** Each `.mdx` file's exported `metadata.title`, plus update `BlogLayout.tsx` if it explicitly appends "| Tokemon" anywhere.

---

#### Fix 2.3 — Add `FAQPage` schema to high-volume blog posts

**Why:** Featured-snippet capture. Currently only homepage has FAQPage schema.

**Targets:** `claude-rate-limits-explained`, `claude-code-cost-calculator`, `avoid-claude-rate-limits`, `claude-token-monitoring-guide`. Each already has Q&A-style sections — adding the schema is mechanical.

**How:** Inject a `<Script type="application/ld+json">` block in each post's MDX template (or BlogLayout when the post has FAQ entries in front-matter).

---

### Tier 3 — Strategic (queue for later)

- **GSC integration via Ahrefs** (`gsc-keywords`, `gsc-pages`) — Path 4 — pull real impression/CTR data to validate which existing pages need rewriting vs which are fine.
- **Comparison schema** — investigate if Schema.org's `Table` or `ComparisonChart` (no native equivalent yet) helps; low priority.
- **Dynamic OG images for tag pages** — only after blog/compare OG is shipped.
- **Pagination for tag pages** — only matters if a tag exceeds ~10 posts.

---

### Recommended fix order

1. **Fix 1.1** (homepage retitle) — single-file edit, biggest ranking impact
2. **Fix 1.3** (rate-limits refresh) — captures $9 CPC keyword, mechanical edits
3. **Fix 2.2** (blog title shortening) — global mechanical edit
4. **Fix 1.4** (OG images) — small infra build, broad CTR lift
5. **Fix 2.3** (FAQPage schema) — low-effort, snippet upside
6. **Fix 1.2** + **Fix 2.1** (new landings) — handled in Path 3 with design-system extraction

### Tier 1 fixes — code-level changes are 1-shot edits

Fixes 1.1, 1.3, 2.2, 2.3 are all small targeted edits to existing files. I can implement them now. Fixes 1.2, 1.4, 2.1 require larger changes (new pages, new infra) and are better as their own sessions.
