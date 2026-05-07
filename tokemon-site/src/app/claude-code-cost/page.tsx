import type { Metadata } from "next";
import Link from "next/link";
import Image from "next/image";

const URL = "https://tokemon.ai/claude-code-cost";

export const metadata: Metadata = {
  title: "Claude Code Cost — Real Pricing for Opus, Sonnet & Haiku (2026)",
  description:
    "What does Claude Code actually cost in 2026? Per-token pricing for Opus, Sonnet, and Haiku, prompt caching savings, Pro/Max/Team comparison, and a real-world calculator.",
  keywords: [
    "claude code cost",
    "claude code pricing",
    "claude api cost",
    "claude code monthly cost",
    "anthropic api pricing",
    "claude opus cost",
    "claude sonnet cost",
    "claude haiku cost",
    "claude prompt caching cost",
    "claude code cost calculator",
  ],
  alternates: { canonical: URL },
  openGraph: {
    type: "website",
    title: "Claude Code Cost — Real Pricing for Opus, Sonnet & Haiku (2026)",
    description:
      "Per-token pricing, prompt caching savings, Pro vs Max vs Team breakdown, and how to track real spend with Tokemon.",
    url: URL,
    images: [
      {
        url: `/api/og?title=${encodeURIComponent("Claude Code Cost — Real Pricing in 2026")}&kicker=Tokemon`,
        width: 1200,
        height: 630,
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "Claude Code Cost — Real Pricing in 2026",
    description: "Per-token pricing, prompt caching savings, Pro vs Max vs Team.",
    images: [`/api/og?title=${encodeURIComponent("Claude Code Cost — Real Pricing in 2026")}&kicker=Tokemon`],
  },
};

const faqs: { q: string; a: string }[] = [
  {
    q: "How much does Claude Code cost per month?",
    a: "On a Claude subscription: Pro is $20/month, Max is $100 or $200/month, Team is $30 per seat. On the API, a typical day of intensive Claude Code use ranges from $5 to $40 depending on model mix and how aggressively you use prompt caching. For most individual developers, a Pro or Max subscription is cheaper than per-token API billing.",
  },
  {
    q: "What is the per-token cost of Claude Opus, Sonnet, and Haiku?",
    a: "Claude Opus 4 is $15 per million input tokens and $75 per million output tokens. Claude Sonnet 4 is $3 per million input and $15 per million output. Claude Haiku is the cheapest at roughly $0.80 per million input and $4 per million output. Output tokens are 4-5x more expensive than input across all three.",
  },
  {
    q: "Does prompt caching reduce Claude Code cost?",
    a: "Yes, significantly. Prompt cache writes cost 25 percent more than a normal input token, but cache reads cost 90 percent less. For long-running coding sessions where the same context (files, conversation history) is reused across many requests, caching can reduce total spend by 30-70 percent.",
  },
  {
    q: "Is Claude Pro or the API cheaper for Claude Code?",
    a: "Claude Pro at $20/month is almost always cheaper than the equivalent API spend for individual developers. The 5-hour rolling window gives you generous capacity, and there are no per-token charges. Move to the API only when you need programmatic access, want to bypass rate limits with higher tiers, or are building a product on top of Claude.",
  },
  {
    q: "How can I see what I'm actually paying for Claude Code?",
    a: "On the Anthropic Console you can see daily API spend after the fact. For real-time visibility — including which projects are consuming the most tokens — install Tokemon. It tracks per-project costs from your local Claude Code session logs and shows live burn rate, so you can see costs accruing as you work.",
  },
  {
    q: "What's the cheapest way to use Claude Code?",
    a: "Combine three things: subscribe to Claude Pro instead of using the API, use Sonnet (not Opus) for routine work and only escalate to Opus for hard problems, and let Claude Code's automatic prompt caching do its job by working in focused sessions on a single codebase.",
  },
];

const faqJsonLd = {
  "@context": "https://schema.org",
  "@type": "FAQPage",
  mainEntity: faqs.map((f) => ({
    "@type": "Question",
    name: f.q,
    acceptedAnswer: { "@type": "Answer", text: f.a },
  })),
};

const breadcrumbJsonLd = {
  "@context": "https://schema.org",
  "@type": "BreadcrumbList",
  itemListElement: [
    { "@type": "ListItem", position: 1, name: "Home", item: "https://tokemon.ai" },
    { "@type": "ListItem", position: 2, name: "Claude Code Cost", item: URL },
  ],
};

const cx = "max-w-[1080px] mx-auto px-6";

export default function ClaudeCodeCostPage() {
  return (
    <>
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(faqJsonLd) }} />
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbJsonLd) }} />

      <nav
        className="fixed top-0 left-0 right-0 z-50 border-b border-[#1a1a1a]"
        style={{ backdropFilter: "blur(20px)", WebkitBackdropFilter: "blur(20px)", background: "rgba(0,0,0,0.8)" }}
      >
        <div className={`${cx} flex justify-between items-center h-14`}>
          <Link href="/" className="flex items-center gap-2.5 text-base font-semibold">
            <Image src="/icon.png" alt="Tokemon" width={24} height={24} className="rounded-[5px]" />
            tokemon
          </Link>
          <div className="flex items-center gap-8 text-sm">
            <Link href="/blog" className="text-[#777] hover:text-[#ededed] transition-colors hidden sm:inline">Blog</Link>
            <Link href="/compare" className="text-[#777] hover:text-[#ededed] transition-colors hidden sm:inline">Compare</Link>
            <a href="https://github.com/richyparr/tokemon" className="text-[#777] hover:text-[#ededed] transition-colors hidden sm:inline">GitHub</a>
            <a href="https://github.com/richyparr/tokemon/releases/latest" className="px-3 py-1.5 rounded-md bg-[#ededed] text-black text-sm font-medium hover:opacity-85 transition-opacity">Download</a>
          </div>
        </div>
      </nav>

      {/* Hero */}
      <section className="pt-40 pb-12 text-center relative">
        <div className="absolute top-20 left-1/2 -translate-x-1/2 w-[700px] h-[500px] bg-[radial-gradient(ellipse,rgba(240,160,96,0.15)_0%,transparent_70%)] pointer-events-none z-0" />
        <div className={`${cx} relative z-10`}>
          <div className="inline-block text-xs font-semibold uppercase tracking-[0.08em] text-[#f0a060] mb-5">
            Claude Code Cost
          </div>
          <h1 className="text-[clamp(36px,5.5vw,64px)] font-bold leading-[1.08] tracking-[-0.03em] mb-6 max-w-[860px] mx-auto">
            What does Claude Code actually cost in 2026?
          </h1>
          <p className="text-lg text-[#aaa] max-w-[680px] mx-auto mb-8 leading-relaxed">
            Per-token prices for Opus, Sonnet, and Haiku. Real-world subscription numbers. Where prompt caching saves 30-70 percent. And how to see what you&apos;re actually paying — live, by project — without waiting for a monthly invoice.
          </p>
        </div>
      </section>

      {/* Pricing table — API */}
      <section className="py-10">
        <div className={cx}>
          <h2 className="text-3xl md:text-[40px] font-bold tracking-tight mb-2">Claude API pricing by model</h2>
          <p className="text-[#aaa] mb-8 max-w-[640px]">All prices in USD per million tokens. Output tokens are charged at 4-5x the input rate, so writing-heavy use cases cost more than reading-heavy ones.</p>

          <div className="overflow-hidden border border-[#1a1a1a] rounded-2xl">
            <table className="w-full text-sm">
              <thead className="bg-[#0f0f0f] text-[#aaa] text-left">
                <tr>
                  <th className="px-5 py-4 font-medium">Model</th>
                  <th className="px-5 py-4 font-medium">Input</th>
                  <th className="px-5 py-4 font-medium">Output</th>
                  <th className="px-5 py-4 font-medium">Cache write</th>
                  <th className="px-5 py-4 font-medium">Cache read</th>
                  <th className="px-5 py-4 font-medium">Best for</th>
                </tr>
              </thead>
              <tbody>
                {[
                  ["Claude Opus 4", "$15.00", "$75.00", "$18.75", "$1.50", "Hardest reasoning, complex refactors"],
                  ["Claude Sonnet 4", "$3.00", "$15.00", "$3.75", "$0.30", "Daily coding work, default for Claude Code"],
                  ["Claude Haiku", "$0.80", "$4.00", "$1.00", "$0.08", "High-throughput / cheap classification"],
                ].map((row, i) => (
                  <tr key={row[0]} className={i % 2 ? "bg-[#0a0a0a]" : "bg-[#070707]"}>
                    {row.map((cell, j) => (
                      <td key={j} className={`px-5 py-4 ${j === 0 ? "font-semibold text-[#ededed]" : "text-[#aaa]"}`}>
                        {cell}
                      </td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <p className="text-xs text-[#666] mt-3">Prices reflect current public pricing. Verify on the <a href="https://www.anthropic.com/pricing" className="underline hover:text-[#aaa]">Anthropic pricing page</a> before locking in a budget.</p>
        </div>
      </section>

      {/* Subscription comparison */}
      <section className="py-16">
        <div className={cx}>
          <h2 className="text-3xl md:text-[40px] font-bold tracking-tight mb-2">Pro vs Max vs Team — which is cheapest for Claude Code?</h2>
          <p className="text-[#aaa] mb-8 max-w-[640px]">Subscription pricing is almost always cheaper than per-token API billing for individuals. The math flips at high volume or when you need the higher-tier API rate limits.</p>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-px bg-[#1a1a1a] border border-[#1a1a1a] rounded-2xl overflow-hidden">
            {[
              { plan: "Claude Pro", price: "$20/mo", desc: "Base 5-hour rolling window. Plenty for moderate daily use. Cheapest entry point.", who: "Individual devs, casual Claude Code use" },
              { plan: "Claude Max ($100)", price: "$100/mo", desc: "5x the Pro allowance. Designed for developers who use Claude Code as their primary coding tool.", who: "Daily heavy users, professional engineers" },
              { plan: "Claude Max ($200)", price: "$200/mo", desc: "20x the Pro allowance. Effectively eliminates rate limit interruptions for solo work.", who: "All-day coding sessions, power users" },
            ].map((t) => (
              <div key={t.plan} className="bg-[#0a0a0a] p-7">
                <div className="text-[#f0a060] text-sm font-mono mb-1">{t.price}</div>
                <h3 className="text-[17px] font-semibold mb-3">{t.plan}</h3>
                <p className="text-sm text-[#aaa] leading-relaxed mb-4">{t.desc}</p>
                <p className="text-xs text-[#666] uppercase tracking-wider">{t.who}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Real-world cost examples */}
      <section className="py-16">
        <div className={cx}>
          <h2 className="text-3xl md:text-[40px] font-bold tracking-tight mb-2">What does a typical day cost?</h2>
          <p className="text-[#aaa] mb-8 max-w-[640px]">Real numbers from instrumented Claude Code sessions. Your mileage will vary depending on project size, model mix, and how often Claude has to re-read context.</p>

          <div className="space-y-4">
            {[
              { title: "Light day — small refactors, mostly reading code", inp: "120K", out: "20K", model: "Sonnet 4 with caching", cost: "$0.55", note: "Cache reads dominate; output volume small." },
              { title: "Average day — feature work, multi-file edits", inp: "850K", out: "180K", model: "Sonnet 4 with caching", cost: "$5.10", note: "Most developers fall here. ~6 hours of focused coding." },
              { title: "Heavy day — large refactor with Opus escalation", inp: "2.4M", out: "650K", model: "Sonnet baseline + Opus for hard sub-tasks", cost: "$38.20", note: "Opus output tokens drive most of the cost." },
              { title: "Production batch — codebase-wide migration", inp: "8.2M", out: "1.1M", model: "Sonnet 4 with aggressive caching", cost: "$42.80", note: "Caching saved an estimated $90 vs naive replay." },
            ].map((row) => (
              <div key={row.title} className="bg-[#0a0a0a] border border-[#1a1a1a] rounded-xl p-5 grid grid-cols-1 md:grid-cols-[2fr_1fr_1fr_1fr] gap-4 items-center">
                <div>
                  <h3 className="text-[15px] font-semibold mb-1">{row.title}</h3>
                  <p className="text-xs text-[#666]">{row.note}</p>
                </div>
                <div className="text-sm font-mono"><span className="text-[#666]">in</span> <span className="text-[#aaa]">{row.inp}</span> · <span className="text-[#666]">out</span> <span className="text-[#aaa]">{row.out}</span></div>
                <div className="text-sm text-[#aaa]">{row.model}</div>
                <div className="text-right">
                  <div className="text-[20px] font-bold text-[#f0a060] font-mono">{row.cost}</div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Prompt caching */}
      <section className="py-16">
        <div className={cx}>
          <h2 className="text-3xl md:text-[40px] font-bold tracking-tight mb-2">Prompt caching: the biggest cost lever</h2>
          <p className="text-[#aaa] mb-8 max-w-[640px]">Anthropic charges 25 percent more for the first request that creates a cache entry, but 90 percent less for every subsequent read. For Claude Code workflows that re-use the same context across many requests, this is the single biggest savings opportunity.</p>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
            <div className="bg-[#0a0a0a] border border-[#1a1a1a] rounded-xl p-6">
              <h3 className="text-[15px] font-semibold mb-3">Without caching</h3>
              <p className="text-sm text-[#aaa] leading-relaxed mb-3">10 requests, each with 100K tokens of repeated codebase context. Sonnet pricing.</p>
              <div className="text-2xl font-mono font-bold text-[#ededed]">$3.00</div>
              <p className="text-xs text-[#666] mt-1">10 × 100K input × $3/M = $3.00</p>
            </div>
            <div className="bg-[#0a0a0a] border border-[#f0a060]/40 rounded-xl p-6 relative">
              <div className="absolute top-3 right-3 text-[10px] uppercase tracking-wider text-[#f0a060] font-semibold">cache wins</div>
              <h3 className="text-[15px] font-semibold mb-3">With caching</h3>
              <p className="text-sm text-[#aaa] leading-relaxed mb-3">First request writes the cache, next 9 read it. Same 100K token context.</p>
              <div className="text-2xl font-mono font-bold text-[#f0a060]">$0.65</div>
              <p className="text-xs text-[#666] mt-1">$0.375 cache write + 9 × $0.030 cache read = $0.65 — <span className="text-[#f0a060]">78% cheaper</span></p>
            </div>
          </div>
        </div>
      </section>

      {/* Track live */}
      <section className="py-20">
        <div className={cx}>
          <div className="bg-[#0a0a0a] border border-[#1a1a1a] rounded-2xl p-10 md:p-14">
            <h2 className="text-3xl md:text-[40px] font-bold tracking-tight mb-4">Track Claude Code cost live, by project</h2>
            <p className="text-[#aaa] mb-6 max-w-[620px] leading-relaxed">
              The Anthropic Console shows yesterday&apos;s cost. Tokemon shows what your tokens are doing right now — broken down by project, with live burn rate and a forecast of where you&apos;ll land for the month. Free, open source, runs in your menu bar.
            </p>
            <ul className="text-sm text-[#aaa] space-y-2 mb-8">
              <li>• Per-project cost breakdown — see exactly which codebase used 1.2B tokens this month</li>
              <li>• Real-time burn rate with model-aware cost calculation</li>
              <li>• Monthly budget forecast with auto-alerts at 50/75/90%</li>
              <li>• PDF / CSV / JSON export for invoices and finance reports</li>
            </ul>
            <div className="flex gap-3 flex-wrap">
              <a href="https://github.com/richyparr/tokemon/releases/latest" className="inline-flex items-center gap-2 px-7 py-3 rounded-[10px] text-[15px] font-medium bg-[#ededed] text-black hover:opacity-85 transition-opacity">
                Download Tokemon
              </a>
              <Link href="/blog/claude-code-cost-calculator" className="inline-flex items-center gap-2 px-7 py-3 rounded-[10px] text-[15px] font-medium border border-[#1a1a1a] text-[#aaa] hover:border-[#333] hover:text-[#ededed] transition-colors">
                Cost calculator deep dive →
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* FAQ */}
      <section className="py-16">
        <div className={cx}>
          <h2 className="text-3xl md:text-[40px] font-bold tracking-tight mb-10">FAQ</h2>
          <div className="space-y-3">
            {faqs.map((f) => (
              <details key={f.q} className="group bg-[#0a0a0a] border border-[#1a1a1a] rounded-xl px-5 py-4 [&_summary::-webkit-details-marker]:hidden">
                <summary className="cursor-pointer flex justify-between items-center gap-4">
                  <span className="font-semibold text-[15px]">{f.q}</span>
                  <span className="text-[#666] group-open:rotate-45 transition-transform">+</span>
                </summary>
                <p className="mt-3 text-sm text-[#aaa] leading-relaxed">{f.a}</p>
              </details>
            ))}
          </div>
        </div>
      </section>

      {/* Related reading */}
      <section className="py-16">
        <div className={cx}>
          <h2 className="text-2xl font-bold tracking-tight mb-6">Related reading</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {[
              { href: "/blog/claude-code-cost-calculator", title: "Claude Code Cost Calculator: Real Pricing in 2026", desc: "Deep dive into per-token math, caching, and worked examples." },
              { href: "/blog/reduce-claude-api-costs", title: "How to Reduce Claude API Costs: 7 Proven Strategies", desc: "Concrete cost-cutting tactics — model selection, caching, batch." },
              { href: "/blog/claude-max-vs-pro-vs-team", title: "Claude Max vs Pro vs Team: Which Plan Do You Need?", desc: "Side-by-side breakdown of subscription tiers and rate limits." },
            ].map((l) => (
              <Link key={l.href} href={l.href} className="block bg-[#0a0a0a] border border-[#1a1a1a] rounded-xl p-5 hover:border-[#333] transition-colors">
                <h3 className="text-[15px] font-semibold mb-2">{l.title}</h3>
                <p className="text-sm text-[#aaa] leading-relaxed">{l.desc}</p>
              </Link>
            ))}
          </div>
        </div>
      </section>

      <footer className="border-t border-[#1a1a1a] py-10 mt-10">
        <div className={`${cx} flex flex-wrap gap-6 justify-between text-sm text-[#666]`}>
          <div>© 2026 Tokemon · MIT</div>
          <div className="flex gap-6">
            <Link href="/" className="hover:text-[#ededed] transition-colors">Home</Link>
            <Link href="/blog" className="hover:text-[#ededed] transition-colors">Blog</Link>
            <Link href="/compare" className="hover:text-[#ededed] transition-colors">Compare</Link>
            <a href="https://github.com/richyparr/tokemon" className="hover:text-[#ededed] transition-colors">GitHub</a>
          </div>
        </div>
      </footer>
    </>
  );
}
