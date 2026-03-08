import Link from "next/link";
import type { Metadata } from "next";
import { getPosts } from "@/lib/blog";

export const metadata: Metadata = {
  title: "Blog | Tokemon",
  description:
    "Guides, tips, and insights on monitoring Claude Code usage, tracking AI token consumption, and getting the most out of your Anthropic subscription.",
};

export default async function BlogIndex() {
  const posts = await getPosts();

  return (
    <div className="min-h-screen bg-[#0a0a0a]">
      <div className="max-w-4xl mx-auto px-6 pt-28 pb-24">
        <h1 className="text-4xl font-bold tracking-tight text-white mb-4">
          Blog
        </h1>
        <p className="text-lg text-[#999] mb-12">
          Guides and insights on Claude Code usage monitoring
        </p>

        {posts.length === 0 ? (
          <p className="text-[#666]">No posts yet. Check back soon!</p>
        ) : (
          <div className="space-y-6">
            {posts.map((post) => {
              const formattedDate = new Date(post.date).toLocaleDateString(
                "en-US",
                {
                  year: "numeric",
                  month: "long",
                  day: "numeric",
                }
              );

              return (
                <Link
                  key={post.slug}
                  href={`/blog/${post.slug}`}
                  className="group block rounded-xl border border-[#222] bg-[#111] p-6 transition-colors hover:border-[#e8853b]/50 hover:bg-[#141414]"
                >
                  <h2 className="text-xl font-semibold text-white group-hover:text-[#e8853b] transition-colors mb-2">
                    {post.title}
                  </h2>
                  <p className="text-[#999] mb-3 line-clamp-2">
                    {post.description}
                  </p>
                  <time
                    dateTime={post.date}
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
