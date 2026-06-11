import fs from "fs";
import path from "path";

export type BlogPostMetadata = {
  title: string;
  description: string;
  date: string;
  updated?: string;
  author: string;
  tags: string[];
  readingTime?: number;
};

export type BlogPost = BlogPostMetadata & {
  slug: string;
};

const CONTENT_DIR = path.join(process.cwd(), "content", "blog");
const WORDS_PER_MINUTE = 220;

export function getPostSlugs(): string[] {
  if (!fs.existsSync(CONTENT_DIR)) return [];
  return fs
    .readdirSync(CONTENT_DIR)
    .filter((file) => file.endsWith(".mdx"))
    .map((file) => file.replace(/\.mdx$/, ""));
}

/** URL-safe tag slug; tags in content may be human-readable keyphrases. */
export function slugifyTag(tag: string): string {
  return tag
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
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
    const metadata = fn() as BlogPostMetadata;

    const body = source.replace(match[0], "");
    const words = body.split(/\s+/).filter(Boolean).length;
    metadata.readingTime = Math.max(1, Math.ceil(words / WORDS_PER_MINUTE));

    return metadata;
  } catch {
    return null;
  }
}

export function getPostMetadata(slug: string): BlogPostMetadata | null {
  return extractMetadata(path.join(CONTENT_DIR, `${slug}.mdx`));
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

export function getAllTags(): { tag: string; label: string; count: number }[] {
  const slugs = getPostSlugs();
  const tags: Record<string, { label: string; count: number }> = {};

  for (const slug of slugs) {
    const filePath = path.join(CONTENT_DIR, `${slug}.mdx`);
    const metadata = extractMetadata(filePath);
    if (metadata) {
      for (const tag of metadata.tags) {
        const key = slugifyTag(tag);
        if (!tags[key]) tags[key] = { label: tag, count: 0 };
        tags[key].count += 1;
      }
    }
  }

  return Object.entries(tags)
    .map(([tag, { label, count }]) => ({ tag, label, count }))
    .sort((a, b) => b.count - a.count);
}

export async function getPostsByTag(tagSlug: string): Promise<BlogPost[]> {
  const allPosts = await getPosts();
  return allPosts.filter((p) => p.tags.some((t) => slugifyTag(t) === tagSlug));
}
