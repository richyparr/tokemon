import Image from "next/image";

const cards = [
  { src: "/ss-ctx-2.png", label: "Coding in your editor", width: 1852, height: 1090 },
  { src: "/ss-ctx-3.png", label: "Browsing the web", width: 1852, height: 1090 },
  { src: "/ss-ctx-4.png", label: "Watching fullscreen video", width: 1852, height: 1090 },
  { src: "/ss-bg-7.png", label: "Floating window close-up", width: 422, height: 292 },
];

export function InAction() {
  return (
    <section className="py-20 pb-30">
      <div className="max-w-[1080px] mx-auto px-6">
        <h2 className="text-center text-3xl md:text-[44px] font-bold tracking-tight mb-3">Your usage, always visible</h2>
        <p className="text-center text-secondary-text text-[17px] mb-12">
          A compact floating window that stays on top of everything — fullscreen videos, browsers, your IDE. No clicking, no switching.
        </p>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {cards.map((card) => (
            <div key={card.src} className="relative rounded-xl overflow-hidden border border-border">
              <Image src={card.src} alt={card.label} width={card.width} height={card.height} className="w-full block" />
              <div className="absolute bottom-3 left-3 bg-black/75 backdrop-blur-md px-3 py-1.5 rounded-lg text-[13px] text-secondary-text">
                {card.label}
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
