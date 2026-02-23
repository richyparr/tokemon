"use client";

import TextType from "@/components/TextType";

export function TerminalInstall() {
  return (
    <div className="inline-block mt-6 rounded-lg border border-[#252525] bg-[#0a0a0a] overflow-hidden">
      {/* Title bar */}
      <div className="flex items-center gap-2 px-4 py-2.5 bg-[#111] border-b border-[#1a1a1a]">
        <span className="w-3 h-3 rounded-full bg-[#ff5f57]" />
        <span className="w-3 h-3 rounded-full bg-[#febc2e]" />
        <span className="w-3 h-3 rounded-full bg-[#28c840]" />
        <span className="ml-2 text-[11px] text-[#555]">Terminal</span>
      </div>
      {/* Command */}
      <div className="px-5 py-4 font-mono text-[13px] whitespace-nowrap overflow-x-hidden">
        <span className="text-[#28c840]">~</span>
        <span className="text-[#555] mx-1.5">$</span>
        <TextType
          text="brew tap richyparr/tokemon && brew install --cask tokemon"
          typingSpeed={35}
          loop={false}
          showCursor={true}
          cursorCharacter="&#9608;"
          cursorClassName="!text-[#777] animate-pulse"
          className="inline text-[#ccc]"
          as="span"
          initialDelay={1000}
          style={{ whiteSpace: "nowrap" }}
        />
      </div>
    </div>
  );
}
