"use client";

import Link from "next/link";

export default function Error({ reset }: { error: Error & { digest?: string }; reset: () => void }) {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center text-center px-6">
      <p className="text-xs font-semibold uppercase tracking-[0.08em] text-[#f0a060] mb-4">Error</p>
      <h1 className="text-3xl sm:text-5xl font-bold tracking-tight mb-4 text-[#ededed]">Something went wrong</h1>
      <p className="text-[#999] max-w-md mb-8">
        An unexpected error occurred while loading this page.
      </p>
      <div className="flex flex-wrap gap-3 justify-center">
        <button
          onClick={reset}
          className="px-6 py-3 rounded-xl text-[15px] font-medium bg-[#ededed] text-black hover:opacity-85 transition-opacity"
        >
          Try again
        </button>
        <Link href="/" className="px-6 py-3 rounded-xl text-[15px] font-medium border border-[#252525] text-[#999] hover:border-[#444] hover:text-[#ededed] transition-colors">
          Back home
        </Link>
      </div>
    </div>
  );
}
