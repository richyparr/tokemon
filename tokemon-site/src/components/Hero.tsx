"use client";

import Image from "next/image";
import TextType from "@/components/TextType";

export function Hero() {
  return (
    <section className="pt-40 pb-10 text-center relative">
      {/* Glow */}
      <div className="absolute top-20 left-1/2 -translate-x-1/2 w-[700px] h-[500px] bg-[radial-gradient(ellipse,var(--color-accent-glow)_0%,transparent_70%)] pointer-events-none z-0" />

      <div className="relative z-10 max-w-[1080px] mx-auto px-6">
        <div className="inline-block text-[13px] text-secondary-text border border-border px-4 py-1.5 rounded-full mb-8 tracking-wide">
          Free &amp; open source for macOS
        </div>

        <h1 className="text-[clamp(40px,6vw,72px)] font-bold leading-[1.08] tracking-[-0.03em] mb-6">
          Never hit a{" "}
          <span className="bg-gradient-to-br from-accent to-[#f0a060] bg-clip-text text-transparent">
            <TextType
              text={["rate limit", "token wall", "usage cap"]}
              typingSpeed={80}
              deletingSpeed={40}
              pauseDuration={2500}
              loop={true}
              showCursor={true}
              cursorCharacter="|"
              cursorClassName="text-accent"
              className="inline"
              as="span"
            />
          </span>
          <br />by surprise again
        </h1>

        <p className="text-lg text-secondary-text max-w-[540px] mx-auto mb-12 leading-relaxed">
          Tokemon floats on your screen showing Claude usage in real-time. Track session limits, weekly utilization, burn rate, project costs, and team budgets — all from your menu bar.
        </p>

        <div className="flex gap-3 justify-center flex-wrap mb-6">
          <a href="https://github.com/richyparr/tokemon/releases/latest" className="inline-flex items-center gap-2 px-7 py-3 rounded-[10px] text-[15px] font-medium bg-[#ededed] text-black hover:opacity-85 transition-opacity">
            Download for macOS
          </a>
          <a href="https://github.com/richyparr/tokemon" className="inline-flex items-center gap-2 px-7 py-3 rounded-[10px] text-[15px] font-medium border border-border text-secondary-text hover:border-[#333] hover:text-[#ededed] transition-colors">
            GitHub
          </a>
        </div>

        <div className="font-mono text-[13px] text-secondary-text mt-4">
          <span className="text-accent">$</span> brew tap richyparr/tokemon && brew install --cask tokemon
        </div>

        <div className="mt-16">
          <Image
            src="/ss-bg-2.png"
            alt="Tokemon popover showing usage trend chart and burn rate"
            width={480}
            height={560}
            className="rounded-xl border border-border-light shadow-[0_24px_80px_rgba(0,0,0,0.6),0_0_120px_var(--color-accent-glow)] mx-auto"
            priority
          />
        </div>
      </div>
    </section>
  );
}
