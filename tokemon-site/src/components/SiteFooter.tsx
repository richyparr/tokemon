import Link from "next/link";

export default function SiteFooter() {
  return (
    <footer className="border-t border-[#1a1a1a] py-10">
      <div className="max-w-[1200px] mx-auto px-6 flex flex-col sm:flex-row justify-between items-center gap-4">
        <div className="text-[13px] text-[#8a8a8a]">Built for developers who ship with Claude</div>
        <div className="flex flex-wrap justify-center gap-x-6 gap-y-2 text-[13px]">
          <Link href="/blog" className="text-[#8a8a8a] hover:text-[#ededed] transition-colors">Blog</Link>
          <Link href="/compare" className="text-[#8a8a8a] hover:text-[#ededed] transition-colors">Compare</Link>
          <a href="https://github.com/richyparr/tokemon" className="text-[#8a8a8a] hover:text-[#ededed] transition-colors">GitHub</a>
          <a href="https://github.com/richyparr/tokemon/releases/latest" className="text-[#8a8a8a] hover:text-[#ededed] transition-colors">Releases</a>
          <a href="https://github.com/richyparr/tokemon/issues" className="text-[#8a8a8a] hover:text-[#ededed] transition-colors">Issues</a>
          <a href="https://buymeacoffee.com/richyparr" target="_blank" rel="noopener noreferrer" className="text-[#8a8a8a] hover:text-[#ededed] transition-colors">Buy Me a Coffee</a>
        </div>
      </div>
    </footer>
  );
}
