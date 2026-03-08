import { notFound } from "next/navigation";
import type { Metadata } from "next";
import { getCompareSlugs } from "@/lib/compare";
import type { CompareMetadata } from "@/lib/compare";
import BlogLayout from "@/components/BlogLayout";

export const dynamicParams = false;

export function generateStaticParams() {
  const slugs = getCompareSlugs();
  return slugs.map((slug) => ({ slug }));
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;

  try {
    const mod = await import(`../../../../content/compare/${slug}.mdx`);
    const metadata = mod.metadata as CompareMetadata;

    return {
      title: `${metadata.title} | Tokemon`,
      description: metadata.description,
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

export default async function ComparePostPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;

  try {
    const mod = await import(`../../../../content/compare/${slug}.mdx`);
    const Content = mod.default;
    const metadata = mod.metadata as CompareMetadata;

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
      mainEntityOfPage: `https://tokemon.ai/compare/${slug}`,
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
