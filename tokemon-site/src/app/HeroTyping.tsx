"use client";

import TextType from "@/components/TextType";

export function HeroTyping() {
  return (
    <span
      className="inline"
      style={{
        background: "linear-gradient(135deg, #e8853b 0%, #f0a060 100%)",
        WebkitBackgroundClip: "text",
        WebkitTextFillColor: "transparent",
        backgroundClip: "text",
      }}
    >
      <TextType
        text={["rate limit", "token wall", "usage cap"]}
        typingSpeed={80}
        deletingSpeed={40}
        pauseDuration={2500}
        loop
        showCursor
        cursorCharacter="|"
        cursorClassName="!text-[#e8853b]"
        className="inline"
        as="span"
        style={{
          background: "linear-gradient(135deg, #e8853b 0%, #f0a060 100%)",
          WebkitBackgroundClip: "text",
          WebkitTextFillColor: "transparent",
          backgroundClip: "text",
        }}
      />
    </span>
  );
}
