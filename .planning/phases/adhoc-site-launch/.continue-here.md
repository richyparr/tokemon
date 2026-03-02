---
phase: adhoc-site-launch
task: SEO & launch
total_tasks: ~8
status: in_progress
last_updated: 2026-03-02T05:57:50Z
---

<current_state>
Landing page redesign, interactive demo, and initial SEO are shipped. Currently mid-launch — Reddit post submitted to r/ClaudeCode, SEO foundations deployed. Waiting on user to set up Google Search Console verification (needs their Google account).
</current_state>

<completed_work>

**Landing page redesign (all committed & deployed to tokemon.ai):**
- Full design polish pass on landing page (colors, spacing, typography)
- Interactive hero demo: macOS desktop simulation with streaming Claude Code terminal, floating window, clickable popover
- Hero layout: split two-column (text left, demo right), terminal install below grid
- E2E test suite: 210 tests across 7 devices, all passing

**App fixes (committed):**
- Fixed macOS notifications (removed unsupported interruptionLevel entitlements)
- Unified app icon across macOS, Raycast, and site (branding/tokemon_social_icon.png)
- Added test notification button to settings

**Release & distribution:**
- v4.0.0 GitHub release created with build artifacts
- Homebrew cask updated to v4.0.0
- Reddit post submitted to r/ClaudeCode (Resource flair)

**SEO (committed & deployed):**
- robots.ts — allows all crawlers, points to sitemap
- sitemap.ts — single-page sitemap, weekly changefreq
- JSON-LD SoftwareApplication schema (price: Free, OS: macOS, MIT)
- Keyword-optimized meta description targeting Claude usage search queries
- GitHub repo: updated description + 10 discovery topics (claude, claude-code, anthropic, macos, raycast, etc.)

</completed_work>

<remaining_work>

**SEO (immediate):**
- Google Search Console setup — user needs to provide verification meta tag, then I add it to layout.tsx and deploy
- Submit sitemap.xml via Search Console after verification
- Request indexing of tokemon.ai

**Launch distribution (next):**
- Raycast community launch (user asked about this but was interrupted)
- Product Hunt submission
- AlternativeTo listing
- awesome-lists on GitHub (awesome-claude, awesome-macos, etc.)

**Content SEO (medium-term):**
- Blog/guides section with 2-3 articles targeting search queries:
  - "How to track Claude Code usage"
  - "How to avoid Claude rate limits"
  - "Claude token usage monitoring guide"

**Uncommitted app changes (from before this session, noted in STATE.md):**
- Traffic Light menu bar icon style
- Settings tab truncation fix
- Popover flash fix
- TokenManager Keychain JSON prefix tolerance
- UsageMonitor minor formatting

</remaining_work>

<decisions_made>

- Hero layout: tried centered single-column, then two-column split. User preferred split (text left, demo right) but wanted terminal install below both columns, not hanging on left
- Interactive demo: full interactive (terminal + floating window + clickable popover) over simpler animated or static options
- App icon: user chose branding/tokemon_social_icon.png (orange robot on white bg) for all three targets
- v4.0.0 release: created fresh GitHub release rather than just pushing tag, with full changelog
- Reddit post: Resource flair on r/ClaudeCode, led with personal billing pain story, not feature dump

</decisions_made>

<blockers>

- Google Search Console: needs user's Google account to complete verification. I'll add the meta tag once they provide it.

</blockers>

<context>
The user is in launch mode — shipping fast, iterating on the landing page, and pushing to get users. They're hands-on with design decisions and want things deployed immediately. The site is on Vercel (tokemon.ai), deployed via git subtree split from the monorepo. Dev server runs on port 3001.

Deploy workflow: edit → commit to main → `git subtree split --prefix=tokemon-site -b tokemon-site-split` → `git push tokemon-site tokemon-site-split:main --force` → `git branch -D tokemon-site-split` → `vercel deploy --prod --scope richyparr-9212s-projects --yes`
</context>

<next_action>
Start with: Ask user for the Google Search Console verification meta tag content. Add it to layout.tsx, deploy, then submit sitemap. After that, help with Raycast community launch strategy (user asked about this before pausing).
</next_action>
