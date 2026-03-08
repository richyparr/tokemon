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
