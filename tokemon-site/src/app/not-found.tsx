import Link from "next/link";
import SiteNav from "@/components/SiteNav";
import SiteFooter from "@/components/SiteFooter";

export default function NotFound() {
  return (
    <div className="min-h-screen flex flex-col">
      <SiteNav />
      <main id="main" className="flex-1 flex flex-col items-center justify-center text-center px-6 pt-14">
        <p className="text-xs font-semibold uppercase tracking-[0.08em] text-[#f0a060] mb-4">404</p>
        <h1 className="text-3xl sm:text-5xl font-bold tracking-tight mb-4">Page not found</h1>
        <p className="text-[#999] max-w-md mb-8">
          This page doesn&apos;t exist or has moved. Try one of these instead:
        </p>
        <div className="flex flex-wrap gap-3 justify-center">
          <Link href="/" className="px-6 py-3 rounded-xl text-[15px] font-medium bg-[#ededed] text-black hover:opacity-85 transition-opacity">
            Home
          </Link>
          <Link href="/blog" className="px-6 py-3 rounded-xl text-[15px] font-medium border border-[#252525] text-[#999] hover:border-[#444] hover:text-[#ededed] transition-colors">
            Blog
          </Link>
          <Link href="/compare" className="px-6 py-3 rounded-xl text-[15px] font-medium border border-[#252525] text-[#999] hover:border-[#444] hover:text-[#ededed] transition-colors">
            Compare
          </Link>
        </div>
      </main>
      <SiteFooter />
    </div>
  );
}
