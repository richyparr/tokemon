import type { Metadata } from "next";
import Link from "next/link";
import Image from "next/image";

const PRIMARY_KW = "Claude Statusline";
const URL = "https://tokemon.ai/claude-statusline";

export const metadata: Metadata = {
  title: "Claude Statusline — Live Usage in Your Terminal Prompt",
  description:
    "Show live Claude Code usage, burn rate, and remaining session limit in your zsh or bash prompt. One-click setup with Tokemon — no scripts to maintain.",
  keywords: [
    "claude statusline",
    "claude code statusline",
    "claude terminal usage",
    "claude prompt indicator",
    "zsh claude usage",
    "bash claude usage",
    "claude session tracker terminal",
  ],
  alternates: { canonical: URL },
  openGraph: {
    type: "website",
    title: "Claude Statusline — Live Usage in Your Terminal Prompt",
    description:
      "Show live Claude usage, burn rate, and remaining session limit in your zsh or bash prompt. One-click setup with Tokemon.",
    url: URL,
    images: [
      {
        url: `/api/og?title=${encodeURIComponent("Claude Statusline — Live Usage in Your Prompt")}&kicker=Tokemon`,
        width: 1200,
        height: 630,
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "Claude Statusline — Live Usage in Your Terminal Prompt",
    description: "Show live Claude usage and burn rate in your zsh or bash prompt.",
    images: [`/api/og?title=${encodeURIComponent("Claude Statusline")}&kicker=Tokemon`],
  },
};

const faqs: { q: string; a: string }[] = [
  {
    q: "What is a Claude statusline?",
    a: "A Claude statusline is a live indicator embedded in your terminal prompt (zsh or bash) that shows your current Claude Code session percentage, weekly utilization, and burn rate. It updates automatically so you can see usage without leaving your editor.",
  },
  {
    q: "How does the Tokemon Claude statusline work?",
    a: "Tokemon writes your live usage to ~/.tokemon/statusline every poll. A small shell helper at ~/.tokemon/tokemon-statusline.sh reads the file and prints colored output. You source the helper in your .zshrc or .bashrc and call it from your prompt.",
  },
  {
    q: "Does the Claude statusline work with Powerlevel10k or Starship?",
    a: "Yes. The helper script outputs plain ANSI-colored text, so any prompt framework that supports custom segments — Powerlevel10k, Starship, Pure, Oh My Zsh — can include it as a custom segment that runs on each prompt redraw.",
  },
  {
    q: "Is the Claude statusline free?",
    a: "Yes. Tokemon is free and open source under the MIT license. The statusline feature is bundled — no subscription, no paid tier, no telemetry.",
  },
  {
    q: "Does it slow down my prompt?",
    a: "No. The statusline reads a single small file (~/.tokemon/statusline) on each prompt redraw — typically under 1ms. The actual Claude API polling happens in the background, not on prompt evaluation.",
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
    { "@type": "ListItem", position: 2, name: PRIMARY_KW, item: URL },
  ],
};

const cx = "max-w-[1080px] mx-auto px-6";

export default function ClaudeStatuslinePage() {
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
      <section className="pt-40 pb-16 text-center relative">
        <div className="absolute top-20 left-1/2 -translate-x-1/2 w-[700px] h-[500px] bg-[radial-gradient(ellipse,rgba(240,160,96,0.15)_0%,transparent_70%)] pointer-events-none z-0" />
        <div className={`${cx} relative z-10`}>
          <div className="inline-block text-xs font-semibold uppercase tracking-[0.08em] text-[#f0a060] mb-5">
            Claude Statusline
          </div>
          <h1 className="text-[clamp(36px,5.5vw,64px)] font-bold leading-[1.08] tracking-[-0.03em] mb-6 max-w-[840px] mx-auto">
            Live Claude usage in your terminal prompt
          </h1>
          <p className="text-lg text-[#aaa] max-w-[640px] mx-auto mb-10 leading-relaxed">
            Tokemon writes your Claude session percentage, weekly burn, and reset countdown straight into <code className="font-mono text-[#f0a060]">~/.tokemon/statusline</code> — read it from any zsh, bash, or fish prompt. One-click setup. No scripts to maintain.
          </p>

          <div className="flex gap-3 justify-center flex-wrap mb-10">
            <a href="https://github.com/richyparr/tokemon/releases/latest" className="inline-flex items-center gap-2 px-7 py-3 rounded-[10px] text-[15px] font-medium bg-[#ededed] text-black hover:opacity-85 transition-opacity">
              Download Tokemon
            </a>
            <Link href="/blog/how-to-track-claude-code-usage" className="inline-flex items-center gap-2 px-7 py-3 rounded-[10px] text-[15px] font-medium border border-[#1a1a1a] text-[#aaa] hover:border-[#333] hover:text-[#ededed] transition-colors">
              How it works
            </Link>
          </div>

          {/* Statusline preview */}
          <div className="max-w-[720px] mx-auto bg-[#0a0a0a] border border-[#1a1a1a] rounded-xl p-6 font-mono text-sm text-left shadow-[0_16px_48px_rgba(0,0,0,0.5)]">
            <div className="text-[#666] mb-2">~/code/refchecks {`(main)`}</div>
            <div>
              <span className="text-[#4ade80]">[S:42%</span> <span className="text-[#f0a060]">| W:71%</span> <span className="text-[#888]">| R:2h31m]</span> <span className="text-[#666]">$</span> <span className="text-[#aaa]">claude</span>
            </div>
            <div className="text-[#666] mt-3 text-xs">
              S = current 5-hour session • W = weekly rate-limit utilization • R = time until reset
            </div>
          </div>
        </div>
      </section>

      {/* Why */}
      <section className="py-20">
        <div className={cx}>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-px bg-[#1a1a1a] border border-[#1a1a1a] rounded-2xl overflow-hidden">
            {[
              { t: "Always visible", d: "Your Claude usage sits in the same prompt you're already looking at every command. No window to switch to, no menu bar to glance up at." },
              { t: "Updates in the background", d: "Tokemon polls the Claude usage API and writes the file. Your prompt redraw just reads a tiny cached value — under 1ms overhead." },
              { t: "Color-coded", d: "Green under 50%, orange past 70%, red past 90%. ANSI codes work in every modern terminal — Terminal.app, iTerm2, Alacritty, Ghostty, Warp." },
            ].map((f) => (
              <div key={f.t} className="bg-[#0a0a0a] p-8">
                <h3 className="text-[15px] font-semibold mb-2">{f.t}</h3>
                <p className="text-sm text-[#aaa] leading-relaxed">{f.d}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Setup */}
      <section className="py-16">
        <div className={cx}>
          <h2 className="text-3xl md:text-[40px] font-bold tracking-tight mb-2">Setup in 30 seconds</h2>
          <p className="text-[#aaa] mb-10 max-w-[620px]">Install Tokemon, enable the statusline export in Settings, then add one line to your shell rc file. The helper script auto-installs to <code className="font-mono text-[#f0a060]">~/.tokemon/tokemon-statusline.sh</code>.</p>

          <div className="space-y-5">
            <Step n={1} title="Install Tokemon">
              <pre className="bg-[#0a0a0a] border border-[#1a1a1a] rounded-lg p-4 text-sm font-mono overflow-x-auto"><code className="text-[#aaa]"><span className="text-[#f0a060]">$</span> brew install --cask richyparr/tokemon/tokemon</code></pre>
            </Step>
            <Step n={2} title="Enable the statusline">
              <p className="text-[#aaa] text-sm leading-relaxed">Open Tokemon Settings → <strong className="text-[#ededed]">Statusline</strong> tab → toggle on. Tokemon writes to <code className="font-mono text-[#f0a060]">~/.tokemon/statusline</code> every poll and drops a helper script next to it.</p>
            </Step>
            <Step n={3} title="Wire it into your prompt">
              <p className="text-[#aaa] text-sm leading-relaxed mb-3">Add to your <code className="font-mono text-[#f0a060]">.zshrc</code> or <code className="font-mono text-[#f0a060]">.bashrc</code>:</p>
              <pre className="bg-[#0a0a0a] border border-[#1a1a1a] rounded-lg p-4 text-sm font-mono overflow-x-auto"><code className="text-[#aaa]"><span className="text-[#666]"># Tokemon Claude statusline</span>{"\n"}source ~/.tokemon/tokemon-statusline.sh{"\n"}<span className="text-[#666]"># zsh:</span>{"\n"}PROMPT=<span className="text-[#4ade80]">{"'$(tokemon_statusline) %~ %# '"}</span>{"\n"}<span className="text-[#666]"># bash:</span>{"\n"}PS1=<span className="text-[#4ade80]">{"'$(tokemon_statusline) \\w \\$ '"}</span></code></pre>
            </Step>
          </div>
        </div>
      </section>

      {/* Feature breakdown */}
      <section className="py-20">
        <div className={cx}>
          <h2 className="text-3xl md:text-[40px] font-bold tracking-tight mb-10">What the Claude statusline shows</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-px bg-[#1a1a1a] border border-[#1a1a1a] rounded-2xl overflow-hidden">
            {[
              { k: "S — Session %", v: "Your current 5-hour rolling window utilization. Resets gradually as old requests age out, not on a fixed clock. Color shifts from green → orange → red as you climb." },
              { k: "W — Weekly %", v: "Anthropic's 2026 weekly rate limit on top of the 5-hour cap. The most common reason developers see rate-limit errors when their session window looks clear." },
              { k: "R — Reset countdown", v: "Time remaining in the current 5-hour window, calculated from your earliest counted request. Tells you exactly how long until your headroom regenerates." },
              { k: "Burn rate (optional)", v: "Tokens-per-hour rate from the past 30 minutes. Useful for predicting whether your current pace will exhaust the window before you wrap up." },
            ].map((f) => (
              <div key={f.k} className="bg-[#0a0a0a] p-8">
                <h3 className="text-[15px] font-semibold mb-2 text-[#f0a060] font-mono">{f.k}</h3>
                <p className="text-sm text-[#aaa] leading-relaxed">{f.v}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Compatibility */}
      <section className="py-16">
        <div className={cx}>
          <h2 className="text-3xl md:text-[40px] font-bold tracking-tight mb-6">Works with your prompt framework</h2>
          <p className="text-[#aaa] mb-8 max-w-[620px]">The Tokemon statusline outputs plain ANSI-colored text, so it slots into any prompt framework that supports custom segments.</p>
          <div className="flex flex-wrap gap-2">
            {["zsh", "bash", "fish", "Powerlevel10k", "Starship", "Pure", "Oh My Zsh", "tmux", "iTerm2", "Ghostty", "Alacritty", "Warp"].map((tag) => (
              <span key={tag} className="px-3 py-1.5 rounded-full border border-[#1a1a1a] bg-[#0a0a0a] text-sm text-[#aaa]">{tag}</span>
            ))}
          </div>
        </div>
      </section>

      {/* FAQ */}
      <section className="py-20">
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

      {/* CTA */}
      <section className="py-24 text-center">
        <div className={cx}>
          <h2 className="text-3xl md:text-[44px] font-bold tracking-tight mb-4">Get the Claude statusline running</h2>
          <p className="text-[#aaa] mb-8 max-w-[540px] mx-auto">Free, open source, signed and notarized by Apple. Less than a minute from download to live in your prompt.</p>
          <a href="https://github.com/richyparr/tokemon/releases/latest" className="inline-flex items-center gap-2 px-7 py-3 rounded-[10px] text-[15px] font-medium bg-[#ededed] text-black hover:opacity-85 transition-opacity">
            Download Tokemon for macOS
          </a>
          <div className="font-mono text-[13px] text-[#aaa] mt-6">
            <span className="text-[#f0a060]">$</span> brew install --cask richyparr/tokemon/tokemon
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

function Step({ n, title, children }: { n: number; title: string; children: React.ReactNode }) {
  return (
    <div className="flex gap-4 items-start bg-[#0a0a0a] border border-[#1a1a1a] rounded-xl p-5">
      <div className="flex-shrink-0 w-8 h-8 rounded-full bg-gradient-to-br from-[#f0a060] to-[#e88838] text-black font-bold flex items-center justify-center text-sm">{n}</div>
      <div className="flex-1 min-w-0">
        <h3 className="text-[15px] font-semibold mb-2">{title}</h3>
        {children}
      </div>
    </div>
  );
}
