import Link from "next/link";
import type { BlogPostMetadata } from "@/lib/blog";
import type { BlogPost } from "@/lib/blog";

export default function BlogLayout({
  metadata,
  children,
  slug,
  relatedPosts,
  breadcrumbBase = "blog",
}: {
  metadata: BlogPostMetadata;
  children: React.ReactNode;
  slug?: string;
  relatedPosts?: BlogPost[];
  breadcrumbBase?: "blog" | "compare";
}) {
  const formattedDate = new Date(metadata.date).toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
  });

  const breadcrumbLabel = breadcrumbBase === "compare" ? "Compare" : "Blog";

  return (
    <div className="min-h-screen bg-[#0a0a0a]">
      <div className="max-w-3xl mx-auto px-6 pt-28 pb-24">
        {/* Visual breadcrumb */}
        <nav aria-label="Breadcrumb" className="mb-10">
          <ol className="flex items-center gap-2 text-sm text-[#999]">
            <li>
              <Link href="/" className="hover:text-[#e8853b] transition-colors">Home</Link>
            </li>
            <li className="text-[#444]">/</li>
            <li>
              <Link href={`/${breadcrumbBase}`} className="hover:text-[#e8853b] transition-colors">{breadcrumbLabel}</Link>
            </li>
            <li className="text-[#444]">/</li>
            <li className="text-[#ededed] truncate max-w-[300px]">{metadata.title}</li>
          </ol>
        </nav>

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
            {/* Tags */}
            {metadata.tags && metadata.tags.length > 0 && (
              <div className="flex flex-wrap gap-2 mt-4">
                {metadata.tags.map((tag) => (
                  <Link
                    key={tag}
                    href={`/blog/tag/${encodeURIComponent(tag)}`}
                    className="text-xs px-2.5 py-1 rounded-full bg-[#1a1a1a] border border-[#333] text-[#999] hover:text-[#e8853b] hover:border-[#e8853b]/50 transition-colors"
                  >
                    {tag}
                  </Link>
                ))}
              </div>
            )}
          </header>

          <div className="prose prose-invert prose-orange max-w-none">
            {children}
          </div>
        </article>

        {/* Related Posts */}
        {relatedPosts && relatedPosts.length > 0 && (
          <div className="mt-16 pt-8 border-t border-[#222]">
            <h3 className="text-lg font-semibold text-white mb-6">Related Posts</h3>
            <div className="grid gap-4 sm:grid-cols-2">
              {relatedPosts.slice(0, 4).map((post) => (
                <Link
                  key={post.slug}
                  href={`/blog/${post.slug}`}
                  className="group block rounded-xl border border-[#222] bg-[#111] p-5 transition-colors hover:border-[#e8853b]/50 hover:bg-[#141414]"
                >
                  <h4 className="text-sm font-medium text-white group-hover:text-[#e8853b] transition-colors mb-1 line-clamp-2">
                    {post.title}
                  </h4>
                  <p className="text-xs text-[#666] line-clamp-2">
                    {post.description}
                  </p>
                </Link>
              ))}
            </div>
          </div>
        )}

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
