"use client";

import { useState, useEffect, useRef, useCallback } from "react";

/* ═══════════════════════════════════════════════════════════
   Terminal line data
   Each line: [delay_ms, ...segments]
   Segment: [color, text]
   ═══════════════════════════════════════════════════════════ */

type Seg = [string, string]; // [color, text]
type TLine = { d: number; s: Seg[] };

const C = {
  g: "#4ec9b0", // green (paths)
  p: "#c586c0", // purple (keywords)
  b: "#569cd6", // blue (keywords/types)
  o: "#ce9178", // orange (strings)
  y: "#dcdcaa", // yellow (functions)
  n: "#b5cea8", // number green
  w: "#ccc",    // white/light
  d: "#555",    // dim
  x: "#444",    // box drawing
  a: "#e8853b", // accent (tokemon orange)
};

const LINES: TLine[] = [
  // Command
  { d: 600, s: [[C.g, "~/refchecks "], [C.d, "$ "], [C.w, "claude"]] },
  { d: 400, s: [[C.w, ""]] },
  // Welcome banner
  { d: 80, s: [[C.x, "╭──────────────────────────────────────────╮"]] },
  { d: 60, s: [[C.x, "│"], [C.a, "  ✻ "], ["#fff", "Welcome to Claude Code!"], [C.d, "           "], [C.x, "│"]] },
  { d: 60, s: [[C.x, "│"], [C.d, "    /Users/dev/refchecks"], [C.d, "               "], [C.x, "│"]] },
  { d: 60, s: [[C.x, "╰──────────────────────────────────────────╯"]] },
  { d: 600, s: [[C.w, ""]] },
  // User prompt
  { d: 1000, s: [["#fff", "> Add rate limiting to the API endpoints"]] },
  { d: 500, s: [[C.w, ""]] },
  // Claude thinking
  { d: 500, s: [[C.a, "● "], [C.w, "I'll add rate limiting. Let me examine the"]] },
  { d: 150, s: [[C.w, "  current setup..."]] },
  { d: 400, s: [[C.w, ""]] },
  { d: 400, s: [[C.d, "  Reading "], [C.g, "src/api/routes.ts"], [C.d, "..."]] },
  { d: 350, s: [[C.d, "  Reading "], [C.g, "src/middleware/auth.ts"], [C.d, "..."]] },
  { d: 500, s: [[C.w, ""]] },
  { d: 400, s: [[C.a, "● "], [C.w, "Found 8 unprotected endpoints. Creating rate limiter:"]] },
  { d: 300, s: [[C.w, ""]] },
  // Code file header
  { d: 200, s: [[C.d, "  "], [C.y, "src/middleware/rateLimit.ts"]] },
  { d: 100, s: [[C.x, "  ┌──────────────────────────────────────────"]] },
  // Code
  { d: 100, s: [[C.x, "  │ "], [C.p, "import"], [C.w, " { Redis } "], [C.p, "from"], [C.w, " "], [C.o, "'ioredis'"], [C.w, ";"]] },
  { d: 60, s: [[C.x, "  │"]] },
  { d: 100, s: [[C.x, "  │ "], [C.p, "const"], [C.w, " redis = "], [C.p, "new"], [C.w, " "], [C.y, "Redis"], [C.w, "(process.env.REDIS_URL);"]] },
  { d: 60, s: [[C.x, "  │"]] },
  { d: 100, s: [[C.x, "  │ "], [C.p, "export async function"], [C.w, " "], [C.y, "rateLimit"], [C.w, "("]] },
  { d: 80, s: [[C.x, "  │"], [C.w, "   key"], [C.d, ": "], [C.g, "string"], [C.w, ","]] },
  { d: 80, s: [[C.x, "  │"], [C.w, "   limit "], [C.p, "="], [C.w, " "], [C.n, "100"], [C.w, ","]] },
  { d: 80, s: [[C.x, "  │"], [C.w, "   window "], [C.p, "="], [C.w, " "], [C.n, "3600"]] },
  { d: 60, s: [[C.x, "  │"], [C.w, " ) {"]] },
  { d: 100, s: [[C.x, "  │"], [C.w, "   "], [C.p, "const"], [C.w, " count "], [C.p, "="], [C.w, " "], [C.p, "await"], [C.w, " redis."], [C.y, "incr"], [C.w, "(key);"]] },
  { d: 100, s: [[C.x, "  │"], [C.w, "   "], [C.p, "if"], [C.w, " (count === "], [C.n, "1"], [C.w, ") {"]] },
  { d: 100, s: [[C.x, "  │"], [C.w, "     "], [C.p, "await"], [C.w, " redis."], [C.y, "expire"], [C.w, "(key, window);"]] },
  { d: 60, s: [[C.x, "  │"], [C.w, "   }"]] },
  { d: 80, s: [[C.x, "  │"], [C.w, "   "], [C.p, "return"], [C.w, " count <= limit;"]] },
  { d: 60, s: [[C.x, "  │"], [C.w, " }"]] },
  { d: 100, s: [[C.x, "  └──────────────────────────────────────────"]] },
  { d: 400, s: [[C.w, ""]] },
  // Write prompt
  { d: 500, s: [[C.d, "  Write "], [C.g, "src/middleware/rateLimit.ts"], [C.d, "? "], [C.w, "(y/n)"]] },
];

/* ═══════════════════════════════════════════════════════════
   Usage color helper
   ═══════════════════════════════════════════════════════════ */
function usageColor(pct: number): string {
  if (pct < 50) return "#28c840";
  if (pct < 70) return "#febc2e";
  if (pct < 90) return "#e8853b";
  return "#ff5f57";
}

/* ═══════════════════════════════════════════════════════════
   Menu Bar
   ═══════════════════════════════════════════════════════════ */
function DemoMenuBar({
  usage,
  popoverOpen,
  onTokemonClick,
}: {
  usage: number;
  popoverOpen: boolean;
  onTokemonClick: () => void;
}) {
  const color = usageColor(usage);

  return (
    <div
      className="relative z-30 flex items-center justify-between h-[26px] px-4 text-[11px] text-white/80 select-none shrink-0"
      style={{ background: "rgba(30,30,30,0.85)", backdropFilter: "blur(20px)" }}
    >
      <div className="flex items-center gap-4">
        <span className="text-[13px] font-medium opacity-80"></span>
        <span className="font-semibold">Terminal</span>
        <span className="text-white/40 hidden sm:inline">File</span>
        <span className="text-white/40 hidden sm:inline">Edit</span>
        <span className="text-white/40 hidden sm:inline">View</span>
      </div>
      <div className="flex items-center gap-3">
        <button
          onClick={onTokemonClick}
          className={`flex items-center gap-1.5 px-2 py-0.5 rounded -my-0.5 transition-colors cursor-pointer ${
            popoverOpen ? "bg-white/15" : "hover:bg-white/5"
          }`}
          aria-label="Toggle Tokemon popover"
          aria-expanded={popoverOpen}
        >
          <span className="text-[9px]" style={{ color }}>●</span>
          <span className="font-medium tabular-nums" style={{ color }}>{usage}%</span>
        </button>
        <span className="text-white/50 tabular-nums">Tue 10:13 PM</span>
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════════════════════
   Terminal Window
   ═══════════════════════════════════════════════════════════ */
function DemoTerminal({
  visibleCount,
  termRef,
}: {
  visibleCount: number;
  termRef: React.RefObject<HTMLDivElement | null>;
}) {
  return (
    <div
      className="absolute top-[36px] left-[12px] right-[12px] bottom-[12px] rounded-lg overflow-hidden flex flex-col"
      style={{ boxShadow: "0 8px 40px rgba(0,0,0,0.5)" }}
    >
      {/* Title bar */}
      <div className="flex items-center h-[30px] bg-[#2d2d2d] border-b border-[#1a1a1a] px-3 shrink-0">
        <span className="w-[10px] h-[10px] rounded-full bg-[#ff5f57] mr-1.5" />
        <span className="w-[10px] h-[10px] rounded-full bg-[#febc2e] mr-1.5" />
        <span className="w-[10px] h-[10px] rounded-full bg-[#28c840] mr-1.5" />
        <span className="flex-1 text-center text-[11px] text-[#666] -ml-12">
          claude &mdash; ~/refchecks
        </span>
      </div>
      {/* Body */}
      <div
        ref={termRef}
        className="flex-1 bg-[#1e1e1e] p-3 font-mono text-[11px] leading-[17px] overflow-y-auto overflow-x-hidden scrollbar-hide"
      >
        {LINES.slice(0, visibleCount).map((line, i) => (
          <div key={i} className="whitespace-pre min-h-[17px]">
            {line.s.map(([color, text], j) => (
              <span key={j} style={{ color }}>{text}</span>
            ))}
          </div>
        ))}
        {/* Blinking cursor on last line */}
        {visibleCount > 0 && visibleCount <= LINES.length && (
          <span className="inline-block w-[7px] h-[13px] bg-[#ccc] animate-pulse ml-0.5 -mb-[2px] align-text-bottom" />
        )}
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════════════════════
   Floating Window
   ═══════════════════════════════════════════════════════════ */
function DemoFloatingWindow({ usage }: { usage: number }) {
  const color = usageColor(usage);

  return (
    <div
      className="absolute bottom-[24px] right-[24px] z-20 w-[120px] rounded-xl overflow-hidden select-none"
      style={{
        background: "#1c1c1e",
        border: "1px solid #3a3a3c",
        boxShadow: "0 8px 32px rgba(0,0,0,0.6)",
      }}
    >
      {/* Mini title bar */}
      <div className="flex items-center gap-1 px-2.5 py-1.5">
        <span className="w-[7px] h-[7px] rounded-full bg-[#ff5f57]" />
        <span className="w-[7px] h-[7px] rounded-full bg-[#3a3a3c]" />
        <span className="w-[7px] h-[7px] rounded-full bg-[#3a3a3c]" />
      </div>
      {/* Content */}
      <div className="text-center pb-3 px-2">
        <div className="text-[28px] font-bold tabular-nums leading-none" style={{ color }}>
          {usage}%
        </div>
        <div className="text-[9px] text-[#888] mt-1">5-hour usage</div>
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════════════════════
   Popover
   ═══════════════════════════════════════════════════════════ */
function DemoPopover({ usage, onClose }: { usage: number; onClose: () => void }) {
  const color = usageColor(usage);

  const Row = ({ label, value, valueColor }: { label: string; value: string; valueColor?: string }) => (
    <div className="flex justify-between items-center py-[3px]">
      <span className="text-[#999]">{label}</span>
      <span className="font-medium tabular-nums" style={valueColor ? { color: valueColor } : undefined}>{value}</span>
    </div>
  );

  return (
    <>
      {/* Click-away overlay */}
      <div className="absolute inset-0 z-30" onClick={onClose} />
      {/* Popover */}
      <div
        className="absolute top-[30px] right-[40px] z-40 w-[240px] rounded-xl overflow-hidden text-[11px] text-[#ddd] animate-in fade-in slide-in-from-top-1 duration-200"
        style={{
          background: "#1c1c1e",
          border: "1px solid #3a3a3c",
          boxShadow: "0 12px 48px rgba(0,0,0,0.7)",
        }}
      >
        {/* Arrow */}
        <div
          className="absolute -top-[5px] right-[46px] w-[10px] h-[10px] rotate-45"
          style={{ background: "#1c1c1e", borderLeft: "1px solid #3a3a3c", borderTop: "1px solid #3a3a3c" }}
        />

        <div className="p-3 pt-2.5">
          {/* Profile */}
          <div className="flex items-center gap-1.5 text-[10px] text-[#999] mb-1">
            <span className="text-[8px] text-[#28c840]">●</span>
            <span>✓</span>
            <span>Default</span>
          </div>

          {/* Big percentage */}
          <div className="text-center py-2">
            <div className="text-[40px] font-bold tabular-nums leading-none" style={{ color }}>
              {usage}%
            </div>
            <div className="text-[11px] text-[#666] mt-1">resets in 2h 48m</div>
          </div>

          <div className="h-px bg-[#333] my-1.5" />

          {/* Usage stats */}
          <Row label="7-day usage" value="93.0%" />
          <Row label="7-day Sonnet" value="9.0%" />

          <div className="h-px bg-[#333] my-1.5" />

          {/* Extra usage */}
          <div className="text-[9px] text-[#666] uppercase tracking-wider mb-1">Extra Usage</div>
          <Row label="Spent this month" value="$3.99" />
          <Row label="Monthly limit" value="$50" />
          <Row label="Limit used" value="8.0%" />

          <div className="h-px bg-[#333] my-1.5" />

          {/* All profiles */}
          <div className="text-[9px] text-[#666] uppercase tracking-wider mb-1">All Profiles</div>
          <div className="flex justify-between items-center py-[3px]">
            <div className="flex items-center gap-1.5">
              <span className="text-[7px]" style={{ color }}>●</span>
              <span>Default</span>
            </div>
            <span className="font-medium tabular-nums" style={{ color }}>{usage}%</span>
          </div>
          <div className="flex justify-between items-center py-[3px]">
            <div className="flex items-center gap-1.5">
              <span className="text-[7px] text-[#555]">●</span>
              <span className="text-[#555]">Work</span>
            </div>
            <span className="text-[#555] italic text-[10px]">No creds</span>
          </div>

          <div className="h-px bg-[#333] my-1.5" />

          {/* Footer */}
          <div className="flex justify-between items-center text-[10px] text-[#555]">
            <span>Updated just now</span>
            <div className="flex gap-2">
              <span className="cursor-pointer hover:text-[#999]">↻</span>
              <span className="cursor-pointer hover:text-[#999]">⚙</span>
            </div>
          </div>
        </div>
      </div>
    </>
  );
}

/* ═══════════════════════════════════════════════════════════
   Main Component
   ═══════════════════════════════════════════════════════════ */
export function InteractiveDemo() {
  const [popoverOpen, setPopoverOpen] = useState(false);
  const [usage, setUsage] = useState(37);
  const [lineCount, setLineCount] = useState(0);
  const [isVisible, setIsVisible] = useState(false);
  const termRef = useRef<HTMLDivElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const timeoutsRef = useRef<ReturnType<typeof setTimeout>[]>([]);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  // Observe visibility
  useEffect(() => {
    const el = containerRef.current;
    if (!el) return;
    const obs = new IntersectionObserver(
      ([entry]) => { if (entry.isIntersecting) setIsVisible(true); },
      { threshold: 0.2 }
    );
    obs.observe(el);
    return () => obs.disconnect();
  }, []);

  // Run animation cycle
  const runCycle = useCallback(() => {
    // Clear previous
    timeoutsRef.current.forEach(clearTimeout);
    timeoutsRef.current = [];
    if (intervalRef.current) clearInterval(intervalRef.current);

    setLineCount(0);
    setUsage(37);
    setPopoverOpen(false);

    // Stream lines
    let cumulative = 0;
    LINES.forEach((line, i) => {
      cumulative += line.d;
      const t = setTimeout(() => setLineCount(i + 1), cumulative);
      timeoutsRef.current.push(t);
    });

    // Tick usage
    intervalRef.current = setInterval(() => {
      setUsage((prev) => (prev < 45 ? prev + 1 : prev));
    }, 1200);

    // Restart cycle after animation completes + pause
    const restartDelay = cumulative + 5000;
    const restart = setTimeout(() => {
      if (intervalRef.current) clearInterval(intervalRef.current);
      runCycle();
    }, restartDelay);
    timeoutsRef.current.push(restart);
  }, []);

  useEffect(() => {
    if (!isVisible) return;
    runCycle();
    return () => {
      timeoutsRef.current.forEach(clearTimeout);
      if (intervalRef.current) clearInterval(intervalRef.current);
    };
  }, [isVisible, runCycle]);

  // Auto-scroll terminal
  useEffect(() => {
    if (termRef.current) {
      termRef.current.scrollTop = termRef.current.scrollHeight;
    }
  }, [lineCount]);

  return (
    <div
      ref={containerRef}
      className="relative mx-auto w-full max-w-[720px] rounded-xl overflow-hidden border border-[#252525] select-none"
      style={{
        aspectRatio: "16 / 10",
        boxShadow: "0 24px 80px rgba(0,0,0,0.6), 0 0 120px rgba(232,133,59,0.12)",
      }}
      role="img"
      aria-label="Interactive demo of Tokemon monitoring Claude Code usage on macOS"
    >
      {/* Desktop wallpaper */}
      <div
        className="absolute inset-0"
        style={{
          background: `
            radial-gradient(circle at 30% 40%, rgba(99,102,241,0.08) 0%, transparent 50%),
            radial-gradient(circle at 70% 60%, rgba(14,165,233,0.05) 0%, transparent 50%),
            linear-gradient(145deg, #0f172a, #1e1b4b 50%, #0f172a)
          `,
        }}
      />

      {/* Content */}
      <div className="relative flex flex-col h-full">
        <DemoMenuBar
          usage={usage}
          popoverOpen={popoverOpen}
          onTokemonClick={() => setPopoverOpen((p) => !p)}
        />

        {/* Desktop area */}
        <div className="relative flex-1">
          <DemoTerminal visibleCount={lineCount} termRef={termRef} />
          <DemoFloatingWindow usage={usage} />
          {popoverOpen && <DemoPopover usage={usage} onClose={() => setPopoverOpen(false)} />}
        </div>
      </div>

      {/* Hint */}
      <div className="absolute bottom-1.5 left-0 right-0 text-center text-[9px] text-white/20 z-10 pointer-events-none">
        Click the menu bar icon to see the popover
      </div>
    </div>
  );
}
