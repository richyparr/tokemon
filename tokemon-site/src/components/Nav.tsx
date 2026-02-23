import Image from "next/image";

export function Nav() {
  return (
    <nav className="fixed top-0 left-0 right-0 z-50 backdrop-blur-xl bg-black/80 border-b border-border">
      <div className="max-w-[1080px] mx-auto px-6 flex justify-between items-center h-14">
        <div className="flex items-center gap-2.5 text-base font-semibold text-[#ededed]">
          <Image src="/icon.png" alt="Tokemon" width={24} height={24} className="rounded-[5px]" />
          tokemon
        </div>
        <div className="flex items-center gap-8 text-sm">
          <a href="https://github.com/richyparr/tokemon" className="text-secondary-text hover:text-[#ededed] transition-colors hidden sm:inline">GitHub</a>
          <a href="https://github.com/richyparr/tokemon/releases/latest" className="bg-[#ededed] text-black px-4 py-1.5 rounded-lg text-[13px] font-medium hover:opacity-85 transition-opacity">Download</a>
        </div>
      </div>
    </nav>
  );
}
