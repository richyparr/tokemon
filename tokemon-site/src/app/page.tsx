import Image from "next/image";
import { HeroTyping } from "./HeroTyping";
import { HeroBackground } from "./HeroBackground";
import { HeroCTA } from "./HeroCTA";
import { TerminalInstall } from "./TerminalInstall";

/* ─── shared constants ─── */
const cx = "max-w-[1080px] mx-auto px-6"; // container
const divider = "h-px bg-gradient-to-r from-transparent via-[#1a1a1a] to-transparent";

/* ─── data ─── */
const features: {
  label: string;
  title: string;
  desc: string;
  solution: string;
  quote: { b: string; t: string };
  img: string;
  alt: string;
  reverse?: boolean;
}[] = [
  {
    label: "The problem",
    title: "You don\u2019t know if you\u2019ll hit the limit before your session resets",
    desc: "Claude rate limits reset on a rolling window. Without visibility into your usage trend, you\u2019re flying blind \u2014 burning through tokens with no idea when you\u2019ll hit the wall.",
    solution:
      "Tokemon charts your usage over 24 hours and 7 days, calculates your burn rate per hour, and estimates exactly when you\u2019ll hit your limit at the current pace.",
    quote: {
      b: "Estimated limit: 12h 59m",
      t: " \u2014 at your current burn rate of 6.5%/hr, you have plenty of runway. But if it drops to 2 hours? You\u2019ll know immediately.",
    },
    img: "/ss-bg-2.png",
    alt: "Usage trend chart with burn rate",
  },
  {
    label: "The problem",
    title: "You have no idea which projects are eating your tokens",
    desc: "If you\u2019re billing clients for token usage or managing a budget across projects, you need to know where tokens are going. Manually tracking this is impossible.",
    solution:
      "Tokemon parses your local session logs and breaks down token usage by project \u2014 showing exactly how many tokens each codebase consumed over 7, 30, or 90 days.",
    quote: {
      b: "Billing clients?",
      t: ' Now you can show that \u201crefchecks\u201d used 1.2B tokens and \u201ccandidreei\u201d used 448M. Export the data to PDF or CSV and attach it to your invoice.',
    },
    img: "/ss-bg-5.png",
    alt: "Project breakdown showing per-project token usage",
    reverse: true,
  },
  {
    label: "The problem",
    title: "Your team is burning through API budget with zero visibility",
    desc: "You\u2019ve set a monthly budget but have no idea how much has been spent, what the daily run rate is, or whether you\u2019ll blow past the limit before month-end.",
    solution:
      "Connect your Admin API key and Tokemon gives you a real-time budget gauge \u2014 dollars spent, days remaining, and a forecast that tells you if you\u2019re on pace or heading for an overage.",
    quote: {
      b: "$5.43 of $100 spent, 9 days left.",
      t: " Forecast says you\u2019ll finish at $8.15 \u2014 well under budget. But auto-alerts at 50%, 75%, and 90% ensure you\u2019ll never be caught off guard.",
    },
    img: "/ss-bg-4.png",
    alt: "Budget tracking with gauge and forecast",
  },
  {
    label: "The problem",
    title: "As an admin, you can\u2019t see who\u2019s using what",
    desc: "Managing a team\u2019s Claude usage shouldn\u2019t require digging through billing dashboards. You need a quick view of total cost, total tokens, and usage patterns across your organization.",
    solution:
      "Tokemon connects to the Admin API and surfaces organization-wide analytics \u2014 total cost, input/output tokens, cache usage, and a usage history chart spanning 7 to 90 days.",
    quote: {
      b: "Team leads and finance:",
      t: " See $3.14 total cost, 2.2M tokens across the org, and a usage history that shows exactly when spikes happened. Export it for your monthly report.",
    },
    img: "/ss-bg-3.png",
    alt: "Organization usage analytics",
    reverse: true,
  },
  {
    label: "The problem",
    title: "You need to justify token costs to clients or management",
    desc: "\u201cWe used a lot of tokens\u201d doesn\u2019t cut it. You need real data in a format people can read \u2014 whether you\u2019re a freelancer billing clients or a team lead reporting to management.",
    solution:
      "Tokemon exports your usage data as PDF reports or CSV files. Per-project breakdowns, date-range summaries, cost data \u2014 everything formatted and ready to attach to an invoice or share in a meeting.",
    quote: {
      b: "Freelancers:",
      t: " Export a 30-day PDF showing each client project\u2019s token usage and cost. Attach it to your invoice. No more guessing, no more disputes.",
    },
    img: "/ss-bg-6.png",
    alt: "Usage history and analytics for export",
  },
];

const grid = [
  ["Slack & Discord alerts", "Webhook notifications before you hit limits. Set thresholds at 50%, 70%, 90% \u2014 get a ping in your team channel, not a surprise in your IDE."],
  ["Terminal statusline", "Live in the terminal? Export usage to your shell prompt via ~/.tokemon/statusline. One-click zsh/bash setup with ANSI color coding."],
  ["Usage summaries by period", "Filter analytics by 24h, 7 days, 30 days, or 90 days. See how your usage patterns change over time and identify high-consumption periods."],
  ["Multi-profile support", "Manage personal and work accounts with independent credentials and alert thresholds. Switch between profiles instantly."],
  ["5 menu bar styles", "Percentage, battery, progress bar, icon + bar, or compact number. Optional monochrome mode to match native macOS styling."],
  ["Three themes", "Native macOS (follows system), Light, or Dark with warm orange accents. Your choice across every window and panel."],
];

const actions: [string, string, number, number][] = [
  ["/ss-ctx-2.png", "Coding in your editor", 1852, 1090],
  ["/ss-ctx-3.png", "Browsing the web", 1852, 1090],
  ["/ss-ctx-4.png", "Watching fullscreen video", 1852, 1090],
  ["/ss-bg-7.png", "Floating window close-up", 422, 292],
];

/* ─── page ─── */
export default function Home() {
  return (
    <>
      {/* ── Nav ── */}
      <nav
        className="fixed top-0 left-0 right-0 z-50 border-b border-[#1a1a1a]"
        style={{ backdropFilter: "blur(20px)", WebkitBackdropFilter: "blur(20px)", background: "rgba(0,0,0,0.8)" }}
      >
        <div className={`${cx} flex justify-between items-center h-14`}>
          <div className="flex items-center gap-2.5 text-base font-semibold">
            <Image src="/icon.png" alt="Tokemon" width={24} height={24} className="rounded-[5px]" />
            tokemon
          </div>
          <div className="flex items-center gap-8 text-sm">
            <a href="https://github.com/richyparr/tokemon" className="text-[#777] hover:text-[#ededed] transition-colors hidden sm:inline">
              GitHub
            </a>
            <a
              href="https://github.com/richyparr/tokemon/releases/latest"
              className="bg-[#ededed] text-black px-4 py-1.5 rounded-lg text-[13px] font-medium hover:opacity-85 transition-opacity"
            >
              Download
            </a>
          </div>
        </div>
      </nav>

      {/* ── Hero ── */}
      <section className="relative pt-40 pb-10 text-center overflow-hidden">
        <HeroBackground />
        <div className={`${cx} relative z-10`}>
          <div className="inline-block text-[13px] text-[#777] border border-[#1a1a1a] px-4 py-1.5 rounded-full mb-8 tracking-wide bg-black shadow-[0_0_0_20px_black,0_0_40px_30px_black]">
            Free &amp; open source for macOS
          </div>
          <h1 className="text-5xl sm:text-6xl md:text-7xl font-bold leading-[1.08] tracking-tight mb-6 h-[170px] sm:h-[200px] md:h-[240px]">
            Never hit a{" "}
            <HeroTyping />
            <br />
            by surprise again
          </h1>
          <p className="text-lg text-[#777] max-w-[540px] mx-auto mb-12 leading-relaxed">
            Tokemon floats on your screen showing Claude usage in real-time. Track session limits, weekly utilization,
            burn rate, project costs, and team budgets &mdash; all from your menu bar.
          </p>
          <HeroCTA />
          <TerminalInstall />
          <div className="mt-16">
            <Image
              src="/ss-bg-2.png"
              alt="Tokemon popover showing usage trend chart and burn rate"
              width={480}
              height={560}
              priority
              className="mx-auto rounded-xl border border-[#252525]"
              style={{ boxShadow: "0 24px 80px rgba(0,0,0,0.6), 0 0 120px rgba(232,133,59,0.15)" }}
            />
          </div>
        </div>
      </section>

      <div className={divider} />

      {/* ── Floating window in action ── */}
      <section className="py-20 pb-28">
        <div className={cx}>
          <h2 className="text-center text-3xl md:text-5xl font-bold tracking-tight mb-3">Your usage, always visible</h2>
          <p className="text-center text-[#777] text-[17px] mb-12">
            A compact floating window that stays on top of everything &mdash; fullscreen videos, browsers, your IDE. No clicking, no switching.
          </p>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {actions.map(([src, label, w, h]) => (
              <div key={src} className="relative rounded-xl overflow-hidden border border-[#1a1a1a]">
                <Image src={src} alt={label} width={w} height={h} className="w-full block" />
                <div
                  className="absolute bottom-3 left-3 px-3 py-1.5 rounded-lg text-[13px] text-[#999]"
                  style={{ background: "rgba(0,0,0,0.75)", backdropFilter: "blur(8px)" }}
                >
                  {label}
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── Feature sections ── */}
      {features.map((f, i) => (
        <div key={i}>
          <div className={divider} />
          <section className="py-28">
            <div className={cx}>
              <div className={`grid grid-cols-1 md:grid-cols-2 gap-16 items-center${f.reverse ? " md:[direction:rtl]" : ""}`}>
                <div className={f.reverse ? "md:[direction:ltr]" : ""}>
                  <div className="text-xs font-semibold uppercase tracking-widest text-[#e8853b] mb-4">{f.label}</div>
                  <h2 className="text-2xl md:text-4xl font-bold tracking-tight mb-4 leading-tight">{f.title}</h2>
                  <p className="text-base text-[#777] leading-relaxed">{f.desc}</p>
                  <p className="text-base text-[#777] leading-relaxed mt-3">{f.solution}</p>
                  <div className="mt-5 p-4 px-5 bg-[#111] border border-[#1a1a1a] rounded-xl text-sm text-[#777] leading-relaxed">
                    <strong className="text-[#ededed]">{f.quote.b}</strong>
                    {f.quote.t}
                  </div>
                </div>
                <div className={`flex justify-center${f.reverse ? " md:[direction:ltr]" : ""}`}>
                  <Image
                    src={f.img}
                    alt={f.alt}
                    width={520}
                    height={400}
                    className="rounded-xl border border-[#252525] max-w-full h-auto"
                    style={{ boxShadow: "0 16px 48px rgba(0,0,0,0.5)" }}
                  />
                </div>
              </div>
            </div>
          </section>
        </div>
      ))}

      <div className={divider} />

      {/* ── Feature grid ── */}
      <section className="pb-28">
        <div className={cx}>
          <h2 className="text-center text-3xl md:text-5xl font-bold tracking-tight mb-14">
            And everything else you&apos;d expect
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-px bg-[#1a1a1a] border border-[#1a1a1a] rounded-2xl overflow-hidden">
            {grid.map(([title, desc]) => (
              <div key={title} className="bg-[#111] p-8">
                <h3 className="text-[15px] font-semibold mb-2">{title}</h3>
                <p className="text-sm text-[#777] leading-relaxed">{desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── CTA ── */}
      <section className="py-20 pb-28 text-center">
        <div className={cx}>
          <h2 className="text-3xl md:text-5xl font-bold tracking-tight mb-4">Start monitoring in 30 seconds</h2>
          <p className="text-[#777] text-[17px] mb-10">Free, open source, no account needed. Just install and go.</p>
          <div className="flex gap-3 justify-center flex-wrap mb-6">
            <a
              href="https://github.com/richyparr/tokemon/releases/latest"
              className="inline-flex items-center gap-2 px-7 py-3 rounded-xl text-[15px] font-medium bg-[#ededed] text-black hover:opacity-85 transition-opacity"
            >
              Download for macOS
            </a>
            <a
              href="https://github.com/richyparr/tokemon"
              className="inline-flex items-center gap-2 px-7 py-3 rounded-xl text-[15px] font-medium border border-[#1a1a1a] text-[#777] hover:border-[#333] hover:text-[#ededed] transition-colors"
            >
              View on GitHub
            </a>
          </div>
          <div className="font-mono text-[13px] text-[#777] mt-5">
            <span className="text-[#e8853b]">$</span> brew tap richyparr/tokemon && brew install --cask tokemon
          </div>
        </div>
      </section>

      {/* ── Footer ── */}
      <footer className="border-t border-[#1a1a1a] py-10">
        <div className={`${cx} flex flex-col sm:flex-row justify-between items-center gap-4`}>
          <div className="text-[13px] text-[#777]">Tokemon &mdash; macOS 14+ &middot; Free &amp; open source</div>
          <div className="flex gap-6 text-[13px]">
            <a href="https://github.com/richyparr/tokemon" className="text-[#777] hover:text-[#ededed] transition-colors">GitHub</a>
            <a href="https://github.com/richyparr/tokemon/releases/latest" className="text-[#777] hover:text-[#ededed] transition-colors">Releases</a>
            <a href="https://github.com/richyparr/tokemon/issues" className="text-[#777] hover:text-[#ededed] transition-colors">Issues</a>
          </div>
        </div>
      </footer>
    </>
  );
}
