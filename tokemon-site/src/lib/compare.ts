import fs from "fs";
import path from "path";

export type CompareMetadata = {
  title: string;
  description: string;
  date: string;
  author: string;
  tags: string[];
  competitor: string;
};

export type ComparePost = CompareMetadata & {
  slug: string;
};

const CONTENT_DIR = path.join(process.cwd(), "content", "compare");

export function getCompareSlugs(): string[] {
  if (!fs.existsSync(CONTENT_DIR)) return [];
  return fs
    .readdirSync(CONTENT_DIR)
    .filter((file) => file.endsWith(".mdx"))
    .map((file) => file.replace(/\.mdx$/, ""));
}

/**
 * Extracts the exported `metadata` object from an MDX file by reading its source.
 * Same pattern as blog.ts — avoids dynamic imports which cause Turbopack warnings.
 */
function extractMetadata(filePath: string): CompareMetadata | null {
  try {
    const source = fs.readFileSync(filePath, "utf-8");
    const match = source.match(
      /export\s+const\s+metadata\s*=\s*(\{[\s\S]*?\n\};)/
    );
    if (!match) return null;

    const fn = new Function(`return ${match[1].replace(/;$/, "")}`);
    return fn() as CompareMetadata;
  } catch {
    return null;
  }
}

export async function getComparePages(): Promise<ComparePost[]> {
  const slugs = getCompareSlugs();
  const posts: ComparePost[] = [];

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
