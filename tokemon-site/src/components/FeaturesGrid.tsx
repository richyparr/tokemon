const gridFeatures = [
  { title: "Slack & Discord alerts", desc: "Webhook notifications before you hit limits. Set thresholds at 50%, 70%, 90% — get a ping in your team channel, not a surprise in your IDE." },
  { title: "Terminal statusline", desc: "Live in the terminal? Export usage to your shell prompt via ~/.tokemon/statusline. One-click zsh/bash setup with ANSI color coding." },
  { title: "Usage summaries by period", desc: "Filter analytics by 24h, 7 days, 30 days, or 90 days. See how your usage patterns change over time and identify high-consumption periods." },
  { title: "Multi-profile support", desc: "Manage personal and work accounts with independent credentials and alert thresholds. Switch between profiles instantly." },
  { title: "5 menu bar styles", desc: "Percentage, battery, progress bar, icon + bar, or compact number. Optional monochrome mode to match native macOS styling." },
  { title: "Three themes", desc: "Native macOS (follows system), Light, or Dark with warm orange accents. Your choice across every window and panel." },
];

export function FeaturesGrid() {
  return (
    <section className="pb-30">
      <div className="max-w-[1080px] mx-auto px-6">
        <div className="text-center mb-14">
          <h2 className="text-3xl md:text-[44px] font-bold tracking-tight">And everything else you&apos;d expect</h2>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-px bg-border border border-border rounded-2xl overflow-hidden">
          {gridFeatures.map((f) => (
            <div key={f.title} className="bg-card p-8">
              <h3 className="text-[15px] font-semibold mb-2">{f.title}</h3>
              <p className="text-sm text-secondary-text leading-relaxed">{f.desc}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
