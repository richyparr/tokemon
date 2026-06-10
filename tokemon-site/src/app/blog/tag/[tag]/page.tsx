import Link from "next/link";
import type { Metadata } from "next";
import { getAllTags, getPostsByTag } from "@/lib/blog";
import SiteNav from "@/components/SiteNav";
import SiteFooter from "@/components/SiteFooter";

export const dynamicParams = false;

export function generateStaticParams() {
  const tags = getAllTags();
  return tags.map(({ tag }) => ({ tag }));
}

function tagLabel(tagSlug: string): string {
  return getAllTags().find((t) => t.tag === tagSlug)?.label ?? tagSlug;
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ tag: string }>;
}): Promise<Metadata> {
  const { tag } = await params;
  const label = tagLabel(tag);

  return {
    title: `Posts tagged "${label}" | Tokemon Blog`,
    description: `Articles about ${label} — Claude usage monitoring guides and tips.`,
    alternates: {
      canonical: `https://tokemon.ai/blog/tag/${tag}`,
    },
  };
}

export default async function TagPage({
  params,
}: {
  params: Promise<{ tag: string }>;
}) {
  const { tag } = await params;
  const label = tagLabel(tag);
  const posts = await getPostsByTag(tag);
  const allTags = getAllTags();

  return (
    <div className="min-h-screen">
      <SiteNav />
      <div id="main" className="max-w-4xl mx-auto px-6 pt-28 pb-24">
        <nav aria-label="Breadcrumb" className="mb-8">
          <ol className="flex items-center gap-2 text-sm text-[#999]">
            <li>
              <Link href="/" className="hover:text-[#e8853b] transition-colors">Home</Link>
            </li>
            <li className="text-[#444]">/</li>
            <li>
              <Link href="/blog" className="hover:text-[#e8853b] transition-colors">Blog</Link>
            </li>
            <li className="text-[#444]">/</li>
            <li className="text-[#ededed]">{label}</li>
          </ol>
        </nav>

        <h1 className="text-3xl font-bold tracking-tight text-white mb-4">
          Posts tagged &ldquo;{label}&rdquo;
        </h1>
        <p className="text-[#999] mb-10">
          {posts.length} {posts.length === 1 ? "article" : "articles"}
        </p>

        <div className="space-y-6 mb-16">
          {posts.map((post) => {
            const formattedDate = new Date(post.date).toLocaleDateString("en-US", {
              year: "numeric",
              month: "long",
              day: "numeric",
              timeZone: "UTC",
            });

            return (
              <Link
                key={post.slug}
                href={`/blog/${post.slug}`}
                className="group block rounded-xl border border-[#222] bg-[#111] p-6 transition-colors hover:border-[#e8853b]/50 hover:bg-[#141414]"
              >
                <h2 className="text-xl font-semibold text-white group-hover:text-[#e8853b] transition-colors mb-2">
                  {post.title}
                </h2>
                <p className="text-[#999] mb-3 line-clamp-2">{post.description}</p>
                <time dateTime={post.date} className="text-sm text-[#8a8a8a]">
                  {formattedDate}
                </time>
              </Link>
            );
          })}
        </div>

        {/* All tags */}
        <div className="border-t border-[#222] pt-10">
          <h2 className="text-lg font-semibold text-white mb-4">All Topics</h2>
          <div className="flex flex-wrap gap-2">
            {allTags.map(({ tag: t, label: l, count }) => (
              <Link
                key={t}
                href={`/blog/tag/${t}`}
                className={`text-sm px-3 py-1.5 rounded-full border transition-colors ${
                  t === tag
                    ? "bg-[#e8853b]/10 border-[#e8853b]/50 text-[#e8853b]"
                    : "bg-[#1a1a1a] border-[#333] text-[#999] hover:text-[#e8853b] hover:border-[#e8853b]/50"
                }`}
              >
                {l} ({count})
              </Link>
            ))}
          </div>
        </div>
      </div>
      <SiteFooter />
    </div>
  );
}
