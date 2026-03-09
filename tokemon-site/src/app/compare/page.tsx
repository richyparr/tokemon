import Link from "next/link";
import type { Metadata } from "next";
import { getComparePages } from "@/lib/compare";

export const metadata: Metadata = {
  title: "Compare Tokemon vs Alternatives | Tokemon",
  description:
    "See how Tokemon compares to other Claude usage monitoring tools. Detailed feature comparisons to help you choose the right Claude Code usage tracker.",
  alternates: {
    canonical: "https://tokemon.ai/compare",
  },
  openGraph: {
    title: "Compare Tokemon vs Alternatives",
    description:
      "See how Tokemon compares to other Claude usage monitoring tools. Detailed feature comparisons.",
    url: "https://tokemon.ai/compare",
  },
};

export default async function CompareIndex() {
  const pages = await getComparePages();

  return (
    <div className="min-h-screen bg-[#0a0a0a]">
      <div className="max-w-4xl mx-auto px-6 pt-28 pb-24">
        <h1 className="text-4xl font-bold tracking-tight text-white mb-4">
          Tokemon vs Alternatives
        </h1>
        <p className="text-lg text-[#999] mb-12">
          Detailed comparisons to help you choose the right Claude usage monitor.
        </p>

        {pages.length === 0 ? (
          <p className="text-[#666]">No comparisons yet. Check back soon!</p>
        ) : (
          <div className="space-y-6">
            {pages.map((page) => {
              const formattedDate = new Date(page.date).toLocaleDateString(
                "en-US",
                {
                  year: "numeric",
                  month: "long",
                  day: "numeric",
                }
              );

              return (
                <Link
                  key={page.slug}
                  href={`/compare/${page.slug}`}
                  className="group block rounded-xl border border-[#222] bg-[#111] p-6 transition-colors hover:border-[#e8853b]/50 hover:bg-[#141414]"
                >
                  <h2 className="text-xl font-semibold text-white group-hover:text-[#e8853b] transition-colors mb-2">
                    {page.title}
                  </h2>
                  <p className="text-[#999] mb-3 line-clamp-2">
                    {page.description}
                  </p>
                  <time
                    dateTime={page.date}
                    className="text-sm text-[#666]"
                  >
                    {formattedDate}
                  </time>
                </Link>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
