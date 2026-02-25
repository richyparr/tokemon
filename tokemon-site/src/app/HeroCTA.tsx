"use client";

import FadeContent from "@/components/FadeContent";

export function HeroCTA() {
  return (
    <>
      <div className="flex gap-3 justify-center md:justify-start flex-wrap mb-6">
        <FadeContent blur duration={800} delay={200} threshold={0.1}>
          <a
            href="https://github.com/richyparr/tokemon/releases/latest"
            className="inline-flex items-center gap-2 px-7 py-3 rounded-xl text-[15px] font-medium bg-[#ededed] text-black hover:opacity-85 transition-opacity"
          >
            Download for macOS
          </a>
        </FadeContent>
        <FadeContent blur duration={800} delay={400} threshold={0.1}>
          <a
            href="https://github.com/richyparr/tokemon"
            className="inline-flex items-center gap-2 px-7 py-3 rounded-xl text-[15px] font-medium border border-[#1a1a1a] text-[#777] hover:border-[#333] hover:text-[#ededed] transition-colors"
          >
            GitHub
          </a>
        </FadeContent>
      </div>
    </>
  );
}
