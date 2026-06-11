"use client";

import { useState } from "react";
import TextType from "@/components/TextType";
import { useReducedMotion } from "@/lib/useReducedMotion";

const INSTALL_COMMAND = "brew install --cask richyparr/tokemon/tokemon";

export function TerminalInstall() {
  const [copied, setCopied] = useState(false);
  const reducedMotion = useReducedMotion();

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(INSTALL_COMMAND);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      // Clipboard unavailable (insecure context) — selection still works.
    }
  };

  return (
    <div className="inline-block max-w-full mt-6 rounded-lg border border-[#252525] bg-[#0a0a0a] overflow-hidden">
      {/* Title bar */}
      <div className="flex items-center gap-2 px-4 py-2.5 bg-[#111] border-b border-[#1a1a1a]">
        <span className="w-3 h-3 rounded-full bg-[#ff5f57]" />
        <span className="w-3 h-3 rounded-full bg-[#febc2e]" />
        <span className="w-3 h-3 rounded-full bg-[#28c840]" />
        <span className="ml-2 text-[11px] text-[#8a8a8a]">Terminal</span>
        <button
          onClick={copy}
          aria-label="Copy install command"
          className="ml-auto pl-4 text-[11px] text-[#8a8a8a] hover:text-[#ededed] transition-colors"
        >
          {copied ? "Copied ✓" : "Copy"}
        </button>
      </div>
      {/* Command */}
      <div className="px-5 py-4 font-mono text-[13px] max-sm:text-[11px] whitespace-nowrap overflow-x-auto">
        {reducedMotion ? (
          <span className="text-[#ccc]">{INSTALL_COMMAND}</span>
        ) : (
          <TextType
            text={INSTALL_COMMAND}
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
        )}
      </div>
    </div>
  );
}
