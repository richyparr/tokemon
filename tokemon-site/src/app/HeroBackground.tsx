"use client";

import { useEffect, useState } from "react";
import PixelBlast from "@/components/PixelBlast";

const MOBILE_BREAKPOINT = 768;

export function HeroBackground() {
  const [isMobile, setIsMobile] = useState(false);

  useEffect(() => {
    const check = () => setIsMobile(window.innerWidth < MOBILE_BREAKPOINT);
    check();
    window.addEventListener("resize", check);
    return () => window.removeEventListener("resize", check);
  }, []);

  if (!isMobile) return null;

  return (
    <div
      className="absolute inset-0 z-0 overflow-hidden"
      style={{
        opacity: 0.4,
        maskImage: "radial-gradient(ellipse 50% 45% at 50% 45%, transparent 0%, black 100%)",
        WebkitMaskImage: "radial-gradient(ellipse 50% 45% at 50% 45%, transparent 0%, black 100%)",
      }}
    >
      <PixelBlast
        variant="circle"
        pixelSize={4}
        color="#e8853b"
        speed={0.3}
        patternScale={2.5}
        patternDensity={0.6}
        edgeFade={0.15}
        enableRipples={true}
        rippleSpeed={0.25}
        rippleThickness={0.12}
        rippleIntensityScale={0.8}
        transparent={true}
      />
    </div>
  );
}
