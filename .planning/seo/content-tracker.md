---
name: Tokemon SEO Content Tracker
description: Source of truth for what's been built, what it targets, and when it shipped
target_domain: tokemon.ai
---

# Tokemon Content Tracker

## Landing pages

| URL | Primary keyword | Vol/mo | KD | Type | Shipped | Notes |
|---|---|---|---|---|---|---|
| `/` | claude code usage tracker | 350 | 12 | Homepage | retitled 2026-05-07 | sr-only h1, broader keyword coverage; OG already set |
| `/claude-statusline` | claude statusline | 400 | — | Landing | 2026-05-07 | New. Hero + 3-step setup + feature breakdown + framework compatibility + FAQ + breadcrumb/FAQ schema |
| `/claude-code-cost` | claude code cost | 3,100 | — | Landing | 2026-05-07 | New. API price table + Pro/Max/Team comparison + 4 real-world cost scenarios + caching savings + live tracking CTA + FAQ |

## Blog posts

| URL | Primary keyword | Vol/mo | Status | Last refresh |
|---|---|---|---|---|
| `/blog/avoid-claude-rate-limits` | how to avoid claude rate limits | 10 | Refreshed 2026-05-07 | Added "Weekly Rate Limit (2026)" + "Session Limit vs Rate Limit" H2s, FAQPage schema (4 entries) |
| `/blog/claude-rate-limits-explained` | claude rate limit | 150 | Refreshed 2026-05-07 | Added "Session Limit vs Rate Limit" + "Weekly Rate Limit" H2s, FAQPage schema (4 entries) |
| `/blog/claude-code-cost-calculator` | claude code cost | 3,100 | Refreshed 2026-05-07 | Title shortened, FAQPage schema (3 entries), visible FAQ section appended |
| `/blog/claude-token-monitoring-guide` | claude token monitoring | — | Refreshed 2026-05-07 | Title shortened, FAQPage schema (3 entries), visible FAQ section appended |
| `/blog/best-claude-code-tools` | best claude code tools | 10 | Refreshed 2026-05-07 | Title shortened |
| `/blog/how-to-track-claude-code-usage` | how to track claude code usage | 10 | — | (no changes) |
| `/blog/claude-max-vs-pro-vs-team` | claude max vs pro vs team | — | — | (no changes) |
| `/blog/reduce-claude-api-costs` | how to reduce claude api costs | — | — | (no changes) |

## Comparison pages

| URL | Primary keyword | Status | Notes |
|---|---|---|---|
| `/compare/tokemon-vs-ccusage` | ccusage alternative | (defensive) | 0/mo demand — kept for brand search |
| `/compare/tokemon-vs-claudebar` | claudebar alternative | (defensive) | 0/mo demand — kept for brand search |
| `/compare/tokemon-vs-claude-console` | claude console alternative | Refreshed 2026-05-07 | Title shortened |
| `/compare/tokemon-vs-manual-tracking` | claude usage spreadsheet | Refreshed 2026-05-07 | Title shortened |

## Infrastructure

- **OG image route** `/api/og` — Edge runtime, branded gradient + Tokemon mark + dynamic title. Wired into blog/[slug] and compare/[slug] generateMetadata. Shipped 2026-05-07.
- **Sitemap** updated to include `/claude-code-cost` and `/claude-statusline` at priority 0.9.

## Pending

- Publish v4.1.7 GitHub release ✅ (https://github.com/richyparr/tokemon/releases/tag/v4.1.7)
- Push tokemon-site/main → Vercel deploys site → appcast.xml live → /claude-statusline + /claude-code-cost live
- After deploy: submit updated sitemap to Google Search Console
- Round-2 Ahrefs queries (Path 4 — Monitor): GSC pages/keywords for tokemon.ai to see impression baseline before changes
