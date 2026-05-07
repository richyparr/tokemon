---
name: Tokemon Keyword Research
description: Cumulative keyword research, SERP analysis, and content strategy for tokemon.ai
target_domain: tokemon.ai
target_country: us (primary, with global reach via English audience)
last_updated: 2026-05-07
---

# Tokemon Keyword Research

## 2026-05-07 — Round 1: Foundational research

### Inputs
- Domain: tokemon.ai
- Country: US (primary — Claude Code audience is heavily US-skewed; UK/AU/CA secondary via English)
- 21 seed keywords queried via `keywords-explorer-overview` (15 + 6 follow-up)
- 2 SERP analyses (`serp-overview`) on top candidates
- Total Ahrefs spend: ~1,472 units

### All keyword data gathered

| # | Keyword | Vol | KD | CPC | TP | Parent topic | Parent vol | Notes |
|---|---|---|---|---|---|---|---|---|
| 1 | **claude code cost** | **3,100** | — | — | — | — | — | 🔥 Highest volume; SERP returned empty (likely AI Overview-dominated, unstable) |
| 2 | **claude usage** | **1,500** | 41 | $0.20 | 1,300 | claude usage | 1,500 | Branded/informational; hard to rank on |
| 3 | **claude api cost** | **600** | 31 | $0.20 | **6,200** | anthropic claude api pricing 2026 | 2,400 | 🔥 Highest TP — money-keyword cluster head |
| 4 | claude statusline | 400 | — | — | — | — | — | Niche but Tokemon ships this feature |
| 5 | claude code usage monitor | 350 | 31 | — | — | claude usage | 1,200 | Parent topic 3.4× bigger |
| 6 | **claude usage tracker** | **350** | **12** | $3.00 | **1,400** | claude usage | 1,200 | 🎯 **TIER 1** — Low KD, high TP, high CPC, weak SERP |
| 7 | claude session limit | 250 | — | $9.00 | — | — | — | Highest CPC in set ($9) — strong commercial intent |
| 8 | anthropic api usage | 200 | — | — | — | — | — | — |
| 9 | claude rate limit | 150 | — | $3.00 | — | — | — | — |
| 10 | claude code rate limit | 100 | — | — | — | — | — | — |
| 11 | claude usage monitor | 70 | — | — | — | — | — | Sibling of #5 |
| 12 | claude code monitoring | 50 | 26 | — | — | otel_exporter_otlp_endpoint | 250 | Parent is dev-ops not relevant |
| 13 | how to track claude code usage | 10 | — | — | — | — | — | Existing blog post — validate it ranks |
| 14 | claude weekly rate limit | 10 | — | — | — | — | — | New term (Aug 2025 launch) — will grow |
| 15 | best claude code tools | 10 | — | — | — | — | — | Existing blog post |
| 16 | claude token tracker | 10 | — | — | — | — | — | Weak synonym |
| 17 | claude burn rate | 0 | — | — | — | — | — | Hero copy phrase has no demand |
| 18 | ccusage alternative | 0 | — | — | — | — | — | Brand-defensive only |
| 19 | claudebar alternative | 0 | — | — | — | — | — | Brand-defensive only |

### SERP analysis

#### "claude usage tracker" (350/mo, KD 12) — winnable target
| Pos | URL | DR | UR | Backlinks | Notes |
|---|---|---|---|---|---|
| 1 | claude.ai/settings/usage | 91 | 5 | 753 | Anthropic's own page — out of reach |
| 2 | chromewebstore.google.com (extension listing) | 99 | 0 | 1 | Listing — no real authority |
| 3-4 | Reddit threads | — | — | — | UGC, not landing pages |
| 5 | github.com/lugia19/Claude-Usage-Extension | 97 | 4 | 96 | GitHub repo |
| 6 | support.claude.com (docs) | 91 | 7 | 24 | Anthropic docs |
| 7 | Reddit/Facebook threads | — | — | — | UGC |
| 8 | ProductHunt | 91 | 0 | 55 | Listing |
| 9 | Mozilla addon listing | 96 | 0 | 2 | Listing |
| **10** | **ccusage.com** | **28** | **4** | **183** | 🎯 Only competing landing page on page 1 |

**Verdict:** The only real landing-page competitor on page 1 is **ccusage.com at DR 28**. Tokemon can match or exceed that. Reddit/extension listings have URL Ratings 0-7 — beatable with a strong page.

#### "claude code cost" (3,100/mo) — caution
SERP returned empty positions. Likely SERP is heavily AI-Overview / unstable. High volume is real but click-through could be cannibalized by AI summaries. Treat as opportunistic — build a strong calculator/landing page but don't bet the strategy on it.

---

## Strategic decisions

### The hero-copy problem
The site's homepage hero phrase **"burn rate"** has **zero search demand**. Great brand language, but the H1, `<title>`, and meta description should lead with something users actually search:
- **Recommended H1/title primary:** "Claude Usage Tracker" or "Claude Code Usage Monitor"
- **Recommended secondary in title:** "burn rate" can stay as descriptor, but not as the ranking term

### Cluster architecture

```
                        [Pillar: claude api cost / claude usage]
                       /             |              |              \
        [/claude-usage-tracker]   [/claude-code-cost]   [/claude-rate-limits]   [/claude-statusline]
        primary: claude usage     primary: claude       primary: claude         primary: claude
        tracker (350/12)          code cost (3.1K)      rate limit (150)        statusline (400)
                       \             |              |              /
                        [Blog cluster: existing 8 posts cross-link to pillars]
```

### Tier 1 — Build immediately (highest ROI)

| Page | Primary KW | Vol | KD | TP | Why | Status |
|------|-----------|-----|----|----|-----|--------|
| **/ (homepage retitled)** | claude usage tracker | 350 | 12 | 1,400 | Lowest KD, weak SERP, $3 CPC, only ccusage(DR28) competing | Exists — needs retitle/meta rewrite |
| **/claude-code-cost** (new landing — not blog) | claude code cost | 3,100 | — | — | Largest volume; needs landing not blog post | Move/duplicate from blog post |
| **/claude-api-cost** (or merge with above) | claude api cost | 600 | 31 | **6,200** | Highest TP in research — money keyword | New page or extend cost calculator |

### Tier 2 — Strong opportunities

| Page | Primary KW | Vol | KD | Why | Status |
|------|-----------|-----|----|-----|--------|
| /claude-statusline | claude statusline | 400 | — | Tokemon ships this feature; niche but qualified | New landing |
| /claude-rate-limits | claude rate limit (150) + claude session limit (250, $9 CPC) | 400 combined | — | Existing blog covers this — promote to landing | Existing blog → landing |
| /claude-code-rate-limit | claude code rate limit | 100 | — | Existing blog | Validate ranking |
| /anthropic-api-usage | anthropic api usage | 200 | — | Underserved variant | New page or redirect |

### Tier 3 — Validate (existing blog posts)

These pages already exist; pull GSC/Ahrefs ranking data before deciding on changes:
- /blog/how-to-track-claude-code-usage
- /blog/avoid-claude-rate-limits
- /blog/claude-token-monitoring-guide
- /blog/reduce-claude-api-costs
- /blog/claude-rate-limits-explained
- /blog/claude-code-cost-calculator ← consider promoting to /claude-code-cost landing
- /blog/best-claude-code-tools
- /blog/claude-max-vs-pro-vs-team

### Tier 4 — Reconsider / deprioritize

| Keyword | Why deprioritized |
|---------|-------------------|
| claude burn rate (0) | No demand — keep as hero descriptor only |
| ccusage alternative (0) | Keep page for brand search but don't optimize for SEO traffic |
| claudebar alternative (0) | Same |
| best claude code tools (10) | Low vol — keep blog but don't invest more |

### Trending watch
- **"claude weekly rate limit"** (10/mo now) — Anthropic introduced weekly limits; this term will grow as more users hit it. Refresh /blog/avoid-claude-rate-limits to include this term in H2/FAQ.

---

## Immediate action items (in priority order)

1. **Homepage retitle (Path 2 / Audit work)** — Change `<title>` and `<h1>` from burn-rate-led to "Claude Usage Tracker" or "Claude Code Usage Monitor — Real-time Burn Rate & Cost Tracking". Keep "burn rate" in subhead/body. Estimated impact: rank for the primary cluster head.

2. **Promote /blog/claude-code-cost-calculator → /claude-code-cost landing page** — Higher up in IA, stronger schema, internal links from homepage. 3,100/mo opportunity even with AI Overview risk.

3. **Build /claude-statusline landing** — 400/mo, no real competition. Tokemon literally ships this feature. Fast win.

4. **Add /claude-rate-limits as a landing** (consolidate from blog). Combined 400+/mo across rate-limit / session-limit cluster, $9 CPC on session-limit.

5. **Refresh /blog/avoid-claude-rate-limits** — Add "weekly rate limit" coverage in H2 + FAQ for the trending term.

---

## Not yet researched (queue for round 2)

- `keywords-explorer-matching-terms` on "claude usage" parent — find more long-tails
- `site-explorer-organic-keywords` on tokemon.ai — what's already ranking?
- `site-explorer-organic-keywords` on ccusage.com — direct competitor gap analysis
- `gsc-keywords` for tokemon.ai — real impression/CTR data (Path 4)
- Multi-country `volume-by-country` for top 3 keywords — confirm UK/AU/CA volume

These are the natural next investigations. Estimate ~500-800 units to complete round 2.
