import Link from "next/link";
import type { BlogPostMetadata } from "@/lib/blog";

export default function BlogLayout({
  metadata,
  children,
}: {
  metadata: BlogPostMetadata;
  children: React.ReactNode;
}) {
  const formattedDate = new Date(metadata.date).toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
  });

  return (
    <div className="min-h-screen bg-[#0a0a0a]">
      <div className="max-w-3xl mx-auto px-6 pt-28 pb-24">
        <Link
          href="/blog"
          className="inline-flex items-center gap-1 text-sm text-[#999] hover:text-[#e8853b] transition-colors mb-10"
        >
          &larr; Back to Blog
        </Link>

        <article>
          <header className="mb-10">
            <h1 className="text-3xl sm:text-4xl font-bold tracking-tight text-white mb-4">
              {metadata.title}
            </h1>
            <div className="flex items-center gap-3 text-sm text-[#999]">
              <span>{metadata.author}</span>
              <span className="text-[#444]">&middot;</span>
              <time dateTime={metadata.date}>{formattedDate}</time>
            </div>
          </header>

          <div className="prose prose-invert prose-orange max-w-none">
            {children}
          </div>
        </article>

        <div className="mt-16 pt-8 border-t border-[#222]">
          <div className="rounded-xl bg-[#111] border border-[#222] p-8 text-center">
            <h3 className="text-xl font-semibold text-white mb-2">
              Try Tokemon Free
            </h3>
            <p className="text-[#999] mb-6 max-w-md mx-auto">
              Monitor your Claude usage in real-time from your macOS menu bar.
              Open-source and always free.
            </p>
            <Link
              href="/"
              className="inline-flex items-center gap-2 bg-[#e8853b] hover:bg-[#d4742f] text-white font-medium px-6 py-3 rounded-lg transition-colors"
            >
              Download Tokemon
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}
