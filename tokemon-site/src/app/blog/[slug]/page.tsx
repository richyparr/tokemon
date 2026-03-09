import { notFound } from "next/navigation";
import type { Metadata } from "next";
import { getPostSlugs } from "@/lib/blog";
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
      },
      mainEntityOfPage: `https://tokemon.ai/blog/${slug}`,
    };

    return (
      <>
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(articleJsonLd) }}
        />
        <BlogLayout metadata={metadata}>
          <Content />
        </BlogLayout>
      </>
    );
  } catch {
    notFound();
  }
}
