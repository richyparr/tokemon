import Image from "next/image";
import Link from "next/link";

export default function SiteNav() {
  return (
    <>
      <a
        href="#main"
        className="sr-only focus:not-sr-only focus:fixed focus:top-2 focus:left-2 focus:z-[60] focus:bg-[#ededed] focus:text-black focus:px-4 focus:py-2 focus:rounded-lg focus:text-sm"
      >
        Skip to content
      </a>
      <nav
        className="fixed top-0 left-0 right-0 z-50 border-b border-[#1a1a1a]"
        style={{ backdropFilter: "blur(20px)", WebkitBackdropFilter: "blur(20px)", background: "rgba(0,0,0,0.8)" }}
      >
        <div className="max-w-[1200px] mx-auto px-6 flex justify-between items-center h-14">
          <Link href="/" className="flex items-center gap-2.5 text-base font-semibold">
            <Image src="/icon.png" alt="Tokemon" width={24} height={24} className="rounded-[5px]" />
            tokemon
          </Link>
          <div className="flex items-center gap-5 sm:gap-8 text-sm">
            <Link href="/blog" className="text-[#8a8a8a] hover:text-[#ededed] transition-colors">
              Blog
            </Link>
            <Link href="/compare" className="text-[#8a8a8a] hover:text-[#ededed] transition-colors hidden sm:inline">
              Compare
            </Link>
            <a href="https://github.com/richyparr/tokemon" className="text-[#8a8a8a] hover:text-[#ededed] transition-colors hidden sm:inline">
              GitHub
            </a>
            <a
              href="https://github.com/richyparr/tokemon/releases/latest"
              className="bg-[#ededed] text-black px-4 py-1.5 rounded-lg text-[13px] font-medium hover:opacity-85 transition-opacity"
            >
              Download
            </a>
          </div>
        </div>
      </nav>
    </>
  );
}
