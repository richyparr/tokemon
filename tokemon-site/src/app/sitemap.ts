import type { MetadataRoute } from "next";
import { getPosts, getAllTags } from "@/lib/blog";
import { getComparePages } from "@/lib/compare";

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const posts = await getPosts();
  const comparePages = await getComparePages();
  const tags = getAllTags();

  return [
    {
      url: "https://tokemon.ai",
      lastModified: new Date(),
      changeFrequency: "weekly",
      priority: 1,
    },
    {
      url: "https://tokemon.ai/blog",
      lastModified: new Date(),
      changeFrequency: "weekly",
      priority: 0.8,
    },
    {
      url: "https://tokemon.ai/compare",
      lastModified: new Date(),
      changeFrequency: "weekly",
      priority: 0.8,
    },
    ...posts.map((post) => ({
      url: `https://tokemon.ai/blog/${post.slug}`,
      lastModified: new Date(post.date),
      changeFrequency: "monthly" as const,
      priority: 0.7,
    })),
    ...comparePages.map((page) => ({
      url: `https://tokemon.ai/compare/${page.slug}`,
      lastModified: new Date(page.date),
      changeFrequency: "monthly" as const,
      priority: 0.7,
    })),
    ...tags.map(({ tag }) => ({
      url: `https://tokemon.ai/blog/tag/${encodeURIComponent(tag)}`,
      lastModified: new Date(),
      changeFrequency: "weekly" as const,
      priority: 0.5,
    })),
  ];
}
