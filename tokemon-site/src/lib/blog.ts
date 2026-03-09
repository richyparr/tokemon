import fs from "fs";
import path from "path";

export type BlogPostMetadata = {
  title: string;
  description: string;
  date: string;
  author: string;
  tags: string[];
};

export type BlogPost = BlogPostMetadata & {
  slug: string;
};

const CONTENT_DIR = path.join(process.cwd(), "content", "blog");

export function getPostSlugs(): string[] {
  if (!fs.existsSync(CONTENT_DIR)) return [];
  return fs
    .readdirSync(CONTENT_DIR)
    .filter((file) => file.endsWith(".mdx"))
    .map((file) => file.replace(/\.mdx$/, ""));
}

/**
 * Extracts the exported `metadata` object from an MDX file by reading its source.
 * This avoids dynamic imports which cause Turbopack warnings.
 */
function extractMetadata(filePath: string): BlogPostMetadata | null {
  try {
    const source = fs.readFileSync(filePath, "utf-8");
    // Match: export const metadata = { ... };
    const match = source.match(
      /export\s+const\s+metadata\s*=\s*(\{[\s\S]*?\n\};)/
    );
    if (!match) return null;

    // Use Function constructor to safely evaluate the object literal
    const fn = new Function(`return ${match[1].replace(/;$/, "")}`);
    return fn() as BlogPostMetadata;
  } catch {
    return null;
  }
}

export async function getPosts(): Promise<BlogPost[]> {
  const slugs = getPostSlugs();
  const posts: BlogPost[] = [];

  for (const slug of slugs) {
    const filePath = path.join(CONTENT_DIR, `${slug}.mdx`);
    const metadata = extractMetadata(filePath);
    if (metadata) {
      posts.push({ slug, ...metadata });
    }
  }

  return posts.sort(
    (a, b) => new Date(b.date).getTime() - new Date(a.date).getTime()
  );
}

export async function getRelatedPosts(currentSlug: string, tags: string[], limit = 4): Promise<BlogPost[]> {
  const allPosts = await getPosts();
  const others = allPosts.filter((p) => p.slug !== currentSlug);

  // Score by number of shared tags
  const scored = others.map((post) => ({
    post,
    score: post.tags.filter((t) => tags.includes(t)).length,
  }));

  scored.sort((a, b) => b.score - a.score);
  return scored.slice(0, limit).map((s) => s.post);
}

export function getAllTags(): { tag: string; count: number }[] {
  const slugs = getPostSlugs();
  const tagCounts: Record<string, number> = {};

  for (const slug of slugs) {
    const filePath = path.join(CONTENT_DIR, `${slug}.mdx`);
    const metadata = extractMetadata(filePath);
    if (metadata) {
      for (const tag of metadata.tags) {
        tagCounts[tag] = (tagCounts[tag] || 0) + 1;
      }
    }
  }

  return Object.entries(tagCounts)
    .map(([tag, count]) => ({ tag, count }))
    .sort((a, b) => b.count - a.count);
}

export async function getPostsByTag(tag: string): Promise<BlogPost[]> {
  const allPosts = await getPosts();
  return allPosts.filter((p) => p.tags.includes(tag));
}
