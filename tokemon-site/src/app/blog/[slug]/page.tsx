import { notFound } from "next/navigation";
import type { Metadata } from "next";
import { getPostSlugs, getRelatedPosts } from "@/lib/blog";
import type { BlogPostMetadata } from "@/lib/blog";
import BlogLayout from "@/components/BlogLayout";

export const dynamicParams = false;

export function generateStaticParams() {
  const slugs = getPostSlugs();
  return slugs.map((slug) => ({ slug }));
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;

  try {
    const mod = await import(`../../../../content/blog/${slug}.mdx`);
    const metadata = mod.metadata as BlogPostMetadata;

    return {
      title: `${metadata.title} | Tokemon`,
      description: metadata.description,
      alternates: {
        canonical: `https://tokemon.ai/blog/${slug}`,
      },
      openGraph: {
        type: "article",
        title: metadata.title,
        description: metadata.description,
        publishedTime: metadata.date,
        authors: [metadata.author],
      },
    };
  } catch {
    return {};
  }
}

// Slugs that are tutorial/how-to style and should get HowTo schema
const HOW_TO_SLUGS = [
  "how-to-track-claude-code-usage",
  "avoid-claude-rate-limits",
  "reduce-claude-api-costs",
  "claude-token-monitoring-guide",
];

export default async function BlogPostPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;

  try {
    const mod = await import(`../../../../content/blog/${slug}.mdx`);
    const Content = mod.default;
    const metadata = mod.metadata as BlogPostMetadata;

    const relatedPosts = await getRelatedPosts(slug, metadata.tags);

    const articleJsonLd = {
      "@context": "https://schema.org",
      "@type": "Article",
      headline: metadata.title,
      description: metadata.description,
      datePublished: metadata.date,
      dateModified: metadata.date,
      author: {
        "@type": "Person",
        name: "Richard Parr",
        url: "https://github.com/richyparr",
      },
      publisher: {
        "@type": "Organization",
        name: "Tokemon",
        url: "https://tokemon.ai",
        logo: {
          "@type": "ImageObject",
          url: "https://tokemon.ai/icon.png",
        },
      },
      mainEntityOfPage: `https://tokemon.ai/blog/${slug}`,
    };

    const breadcrumbJsonLd = {
      "@context": "https://schema.org",
      "@type": "BreadcrumbList",
      itemListElement: [
        {
          "@type": "ListItem",
          position: 1,
          name: "Home",
          item: "https://tokemon.ai",
        },
        {
          "@type": "ListItem",
          position: 2,
          name: "Blog",
          item: "https://tokemon.ai/blog",
        },
        {
          "@type": "ListItem",
          position: 3,
          name: metadata.title,
          item: `https://tokemon.ai/blog/${slug}`,
        },
      ],
    };

    // HowTo schema for tutorial-style posts
    const howToJsonLd = HOW_TO_SLUGS.includes(slug)
      ? {
          "@context": "https://schema.org",
          "@type": "HowTo",
          name: metadata.title,
          description: metadata.description,
          author: {
            "@type": "Person",
            name: "Richard Parr",
          },
          tool: {
            "@type": "HowToTool",
            name: "Tokemon",
          },
        }
      : null;

    return (
      <>
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(articleJsonLd) }}
        />
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbJsonLd) }}
        />
        {howToJsonLd && (
          <script
            type="application/ld+json"
            dangerouslySetInnerHTML={{ __html: JSON.stringify(howToJsonLd) }}
          />
        )}
        <BlogLayout metadata={metadata} slug={slug} relatedPosts={relatedPosts}>
          <Content />
        </BlogLayout>
      </>
    );
  } catch {
    notFound();
  }
}
