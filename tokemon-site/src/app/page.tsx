import Image from "next/image";
import { HeroTyping } from "./HeroTyping";
import { HeroBackground } from "./HeroBackground";
import { HeroCTA } from "./HeroCTA";
import { TerminalInstall } from "./TerminalInstall";
import { InteractiveDemo } from "./InteractiveDemo";

/* ─── shared constants ─── */
const cx = "max-w-[1200px] mx-auto px-6"; // container
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
    label: "Usage visibility",
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
    label: "Project tracking",
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
    label: "Budget management",
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
    label: "Team analytics",
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
    label: "Reporting & export",
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

const grid: [string, string, string][] = [
  ["\u{1F514}", "Slack & Discord alerts", "Webhook notifications before you hit limits. Set thresholds at 50%, 70%, 90% \u2014 get a ping in your team channel, not a surprise in your IDE."],
  ["\u{25B6}\u{FE0E}", "Terminal statusline", "Live in the terminal? Export usage to your shell prompt via ~/.tokemon/statusline. One-click zsh/bash setup with ANSI color coding."],
  ["\u{1F4CA}", "Usage summaries by period", "Filter analytics by 24h, 7 days, 30 days, or 90 days. See how your usage patterns change over time and identify high-consumption periods."],
  ["\u{1F465}", "Multi-profile support", "Manage personal and work accounts with independent credentials and alert thresholds. Switch between profiles instantly."],
  ["\u{1F3A8}", "6 menu bar styles", "Percentage, battery, progress bar, icon + bar, compact number, or traffic light. Optional monochrome mode to match native macOS styling."],
  ["\u{1F317}", "Three themes", "Native macOS (follows system), Light, or Dark with warm orange accents. Your choice across every window and panel."],
];

const raycastFeatures = [
  ["Usage dashboard", "Session percentage, weekly utilization, pace indicator, and reset countdown \u2014 all in a single Raycast command. Cmd+R to refresh."],
  ["Menu bar presence", "Usage percentage lives in your Raycast menu bar with a colored indicator (green/yellow/orange/red) that updates every 5 minutes."],
  ["Multi-profile", "Switch between personal and work Claude accounts instantly. Each profile has its own OAuth token and usage tracking."],
  ["Threshold alerts", "Set a usage percentage and get a notification before you hit the limit. Alerts fire once per session window \u2014 never spammy."],
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
      <section className="relative pt-32 md:pt-36 pb-10 text-center md:text-left overflow-hidden">
        <HeroBackground />
        <div className={`${cx} relative z-10`}>
          <div className="grid grid-cols-1 md:grid-cols-[minmax(0,1fr)_minmax(0,1.2fr)] gap-8 md:gap-12 items-center">
            {/* Left: text content */}
            <div>
              <div className="inline-block text-[13px] text-[#777] border border-[#1a1a1a] px-4 py-1.5 rounded-full mb-8 tracking-wide bg-black shadow-[0_0_0_20px_black,0_0_40px_30px_black]">
                Free &amp; open source for macOS &amp; Raycast
              </div>
              <h1 className="text-4xl sm:text-5xl md:text-[42px] lg:text-5xl font-bold leading-[1.08] tracking-tight mb-5 h-[130px] sm:h-[155px] md:h-[140px] lg:h-[160px]">
                Never hit a{" "}
                <HeroTyping />
                <br />
                by surprise again
              </h1>
              <p className="text-[16px] text-[#777] max-w-[540px] mx-auto md:mx-0 mb-8 leading-relaxed">
                Tokemon shows your Claude usage in real-time &mdash; from your menu bar, a floating window, or Raycast.
                Track session limits, burn rate, project costs, and team budgets.
              </p>
              <div className="mb-6 inline-flex items-center gap-2 text-[13px] text-[#555]">
                <svg width="14" height="14" viewBox="0 0 16 16" fill="none">
                  <path d="M8 1l2.245 4.55 5.02.73-3.633 3.54.858 5L8 12.67 3.51 15.82l.858-5L.735 7.28l5.02-.73L8 1z" fill="#e8853b"/>
                </svg>
                Open source &mdash; loved by developers who ship with Claude
              </div>
              <HeroCTA />
              <TerminalInstall />
            </div>
            {/* Right: interactive demo */}
            <div>
              <div className="hidden md:block">
                <InteractiveDemo />
              </div>
              <Image
                src="/ss-bg-1.png"
                alt="Tokemon popover showing real-time Claude usage"
                width={480}
                height={560}
                priority
                className="mx-auto rounded-xl border border-[#252525] md:hidden mt-8"
                style={{ boxShadow: "0 24px 80px rgba(0,0,0,0.6), 0 0 120px rgba(232,133,59,0.15)" }}
              />
            </div>
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
              <div key={src} className="relative rounded-xl overflow-hidden border border-[#1a1a1a] group">
                <Image src={src} alt={label} width={w} height={h} className="w-full block transition-transform duration-500 group-hover:scale-[1.02]" />
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

      {/* ── Feature grid (capabilities overview) ── */}
      <section className="py-24">
        <div className={cx}>
          <h2 className="text-center text-3xl md:text-5xl font-bold tracking-tight mb-14">
            Built for power users
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-px bg-[#1a1a1a] border border-[#1a1a1a] rounded-2xl overflow-hidden">
            {grid.map(([icon, title, desc]) => (
              <div key={title} className="bg-[#111] p-8 transition-colors duration-200 hover:bg-[#151515] border-t-2 border-t-[#e8853b]/10">
                <div className="text-xl mb-3" aria-hidden="true">{icon}</div>
                <h3 className="text-[15px] font-semibold mb-2">{title}</h3>
                <p className="text-sm text-[#777] leading-relaxed">{desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── Feature deep-dives (first 3) ── */}
      {features.slice(0, 3).map((f, i) => (
        <div key={i}>
          <div className={divider} />
          <section className="py-24">
            <div className={cx}>
              <div className={`grid grid-cols-1 md:grid-cols-2 gap-16 items-center${f.reverse ? " md:[direction:rtl]" : ""}`}>
                <div className={f.reverse ? "md:[direction:ltr]" : ""}>
                  <div className="text-xs font-semibold uppercase tracking-widest text-[#e8853b] mb-4">{f.label}</div>
                  <h2 className="text-2xl md:text-4xl font-bold tracking-tight mb-4 leading-tight">{f.title}</h2>
                  <p className="text-base text-[#777] leading-relaxed">{f.desc}</p>
                  <p className="text-base text-[#777] leading-relaxed mt-3">{f.solution}</p>
                  <div className="mt-5 p-4 px-5 bg-[#0a0a0a] border border-[#1a1a1a] rounded-xl text-sm text-[#777] leading-relaxed">
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
                    style={{ boxShadow: "0 16px 48px rgba(0,0,0,0.5), 0 0 80px rgba(232,133,59,0.06)" }}
                  />
                </div>
              </div>
            </div>
          </section>
        </div>
      ))}

      <div className={divider} />

      {/* ── Raycast ── */}
      <section className="py-24 relative overflow-hidden">
        <div
          className="absolute inset-0 pointer-events-none"
          style={{
            background: "radial-gradient(ellipse 60% 40% at 50% 0%, rgba(232,133,59,0.04) 0%, transparent 70%)",
          }}
        />
        <div className={`${cx} relative`}>
          <div className="text-center mb-14">
            <div className="inline-flex items-center gap-2 text-[13px] text-[#e8853b] border border-[#e8853b]/20 px-4 py-1.5 rounded-full mb-8 tracking-wide bg-[#e8853b]/5">
              New in v4.0
            </div>
            <h2 className="text-3xl md:text-5xl font-bold tracking-tight mb-4">
              Now available in Raycast
            </h2>
            <p className="text-[#777] text-[17px] max-w-[560px] mx-auto leading-relaxed">
              Your Claude usage inside the launcher you already use. No app switching, no menu bar clicking &mdash; just hit your hotkey.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-px bg-[#1a1a1a] border border-[#1a1a1a] rounded-2xl overflow-hidden mb-10">
            {raycastFeatures.map(([title, desc]) => (
              <div key={title} className="bg-[#111] p-8 transition-colors duration-200 hover:bg-[#151515]">
                <h3 className="text-[15px] font-semibold mb-2">{title}</h3>
                <p className="text-sm text-[#777] leading-relaxed">{desc}</p>
              </div>
            ))}
          </div>

          <div className="text-center">
            <p className="text-sm text-[#555] mb-3">Install from the Raycast Store, or clone and build locally:</p>
            <div className="inline-block rounded-lg border border-[#252525] bg-[#0a0a0a] px-5 py-3 font-mono text-[13px] text-[#999]">
              <span className="text-[#28c840]">~</span>
              <span className="text-[#555] mx-1.5">$</span>
              git clone &amp;&amp; cd tokemon-raycast &amp;&amp; npm i &amp;&amp; npm run dev
            </div>
          </div>
        </div>
      </section>

      {/* ── Feature deep-dives (remaining 2) ── */}
      {features.slice(3).map((f, i) => (
        <div key={i + 3}>
          <div className={divider} />
          <section className="py-24">
            <div className={cx}>
              <div className={`grid grid-cols-1 md:grid-cols-2 gap-16 items-center${f.reverse ? " md:[direction:rtl]" : ""}`}>
                <div className={f.reverse ? "md:[direction:ltr]" : ""}>
                  <div className="text-xs font-semibold uppercase tracking-widest text-[#e8853b] mb-4">{f.label}</div>
                  <h2 className="text-2xl md:text-4xl font-bold tracking-tight mb-4 leading-tight">{f.title}</h2>
                  <p className="text-base text-[#777] leading-relaxed">{f.desc}</p>
                  <p className="text-base text-[#777] leading-relaxed mt-3">{f.solution}</p>
                  <div className="mt-5 p-4 px-5 bg-[#0a0a0a] border border-[#1a1a1a] rounded-xl text-sm text-[#777] leading-relaxed">
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
                    style={{ boxShadow: "0 16px 48px rgba(0,0,0,0.5), 0 0 80px rgba(232,133,59,0.06)" }}
                  />
                </div>
              </div>
            </div>
          </section>
        </div>
      ))}

      <div className={divider} />

      {/* ── CTA ── */}
      <section className="py-24 text-center relative overflow-hidden">
        <div
          className="absolute inset-0 pointer-events-none"
          style={{
            background: "radial-gradient(ellipse 50% 50% at 50% 50%, rgba(232,133,59,0.03) 0%, transparent 70%)",
          }}
        />
        <div className={`${cx} relative`}>
          <h2 className="text-3xl md:text-5xl font-bold tracking-tight mb-4">Start monitoring in 30 seconds</h2>
          <p className="text-[#777] text-[17px] mb-10 max-w-[480px] mx-auto">Free, open source, no account needed. Just install and go.</p>
          <div className="flex gap-3 justify-center flex-wrap mb-8">
            <a
              href="https://github.com/richyparr/tokemon/releases/latest"
              className="inline-flex items-center gap-2 px-7 py-3 rounded-xl text-[15px] font-medium bg-[#ededed] text-black hover:bg-white transition-colors"
            >
              Download for macOS
            </a>
            <a
              href="https://github.com/richyparr/tokemon"
              className="inline-flex items-center gap-2 px-7 py-3 rounded-xl text-[15px] font-medium border border-[#252525] text-[#777] hover:border-[#444] hover:text-[#ededed] transition-colors"
            >
              View on GitHub
            </a>
          </div>
          <div className="flex flex-col sm:flex-row gap-4 sm:gap-8 justify-center items-center font-mono text-[13px] text-[#555]">
            <div>
              <span className="text-[#777] mr-2">macOS</span>
              <span className="text-[#e8853b]">$</span> brew install --cask tokemon
            </div>
            <div className="hidden sm:block text-[#252525]">|</div>
            <div>
              <span className="text-[#777] mr-2">Raycast</span>
              <span className="text-[#e8853b]">$</span> npm run dev
            </div>
          </div>
        </div>
      </section>

      {/* ── Footer ── */}
      <footer className="border-t border-[#1a1a1a] py-10">
        <div className={`${cx} flex flex-col sm:flex-row justify-between items-center gap-4`}>
          <div className="text-[13px] text-[#555]">Built for developers who ship with Claude</div>
          <div className="flex gap-6 text-[13px]">
            <a href="https://github.com/richyparr/tokemon" className="text-[#555] hover:text-[#ededed] transition-colors">GitHub</a>
            <a href="https://github.com/richyparr/tokemon/releases/latest" className="text-[#555] hover:text-[#ededed] transition-colors">Releases</a>
            <a href="https://github.com/richyparr/tokemon/issues" className="text-[#555] hover:text-[#ededed] transition-colors">Issues</a>
          </div>
        </div>
      </footer>
    </>
  );
}
