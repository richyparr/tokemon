import { ImageResponse } from "next/og";

const ACCENT = "#f0a060";
const ACCENT_2 = "#e88838";
const BG = "#000";

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const title = (searchParams.get("title") ?? "Tokemon").slice(0, 140);
  const kicker = (searchParams.get("kicker") ?? "tokemon.ai").slice(0, 60);

  return new ImageResponse(
    (
      <div
        style={{
          height: "100%",
          width: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
          padding: "72px",
          background: `radial-gradient(ellipse 80% 60% at 50% -10%, #1a0d04, ${BG} 60%)`,
          color: "#ededed",
          fontFamily: "system-ui, -apple-system, sans-serif",
        }}
      >
        {/* Top: brand + kicker */}
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
            <div
              style={{
                width: 56,
                height: 56,
                borderRadius: 14,
                background: `linear-gradient(135deg, ${ACCENT}, ${ACCENT_2})`,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                color: "#000",
                fontSize: 30,
                fontWeight: 800,
                letterSpacing: "-0.04em",
              }}
            >
              T
            </div>
            <div style={{ display: "flex", fontSize: 28, fontWeight: 700, letterSpacing: "-0.02em" }}>
              Tokemon
            </div>
          </div>
          <div
            style={{
              display: "flex",
              fontSize: 18,
              color: "#888",
              textTransform: "uppercase",
              letterSpacing: "0.12em",
              fontWeight: 600,
            }}
          >
            {kicker}
          </div>
        </div>

        {/* Title */}
        <div
          style={{
            display: "flex",
            fontSize: title.length > 80 ? 56 : title.length > 50 ? 64 : 72,
            fontWeight: 800,
            lineHeight: 1.08,
            letterSpacing: "-0.03em",
            maxWidth: "100%",
          }}
        >
          {title}
        </div>

        {/* Bottom: tagline + accent bar */}
        <div style={{ display: "flex", flexDirection: "column", gap: 18 }}>
          <div style={{ display: "flex", height: 4, width: 220, background: `linear-gradient(90deg, ${ACCENT}, transparent)` }} />
          <div style={{ display: "flex", fontSize: 22, color: "#aaa" }}>
            Claude Code usage tracker for macOS
          </div>
        </div>
      </div>
    ),
    {
      width: 1200,
      height: 630,
    }
  );
}
