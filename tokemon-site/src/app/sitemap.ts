import type { MetadataRoute } from "next";
import { getPostSlugs } from "@/lib/blog";
import { getCompareSlugs } from "@/lib/compare";

export default function sitemap(): MetadataRoute.Sitemap {
  const blogSlugs = getPostSlugs();
  const compareSlugs = getCompareSlugs();

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
    ...blogSlugs.map((slug) => ({
      url: `https://tokemon.ai/blog/${slug}`,
      lastModified: new Date(),
      changeFrequency: "monthly" as const,
      priority: 0.7,
    })),
    ...compareSlugs.map((slug) => ({
      url: `https://tokemon.ai/compare/${slug}`,
      lastModified: new Date(),
      changeFrequency: "monthly" as const,
      priority: 0.7,
    })),
  ];
}
