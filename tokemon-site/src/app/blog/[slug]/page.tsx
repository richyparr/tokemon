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

    const ogImage = `/api/og?title=${encodeURIComponent(metadata.title)}&kicker=Tokemon%20Blog`;
    return {
      title: metadata.title,
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
        images: [{ url: ogImage, width: 1200, height: 630 }],
      },
      twitter: {
        card: "summary_large_image",
        title: metadata.title,
        description: metadata.description,
        images: [ogImage],
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

// FAQ entries per slug — keep answers tight (40-80 words) so they're
// eligible for People Also Ask snippets. Questions and answers must
// reflect content that actually appears on the page.
const FAQ_MAP: Record<string, { question: string; answer: string }[]> = {
  "claude-rate-limits-explained": [
    {
      question: "What is the Claude rate limit?",
      answer:
        "Claude rate limits cap how much you can use Claude in a given period. Consumer plans (Pro, Max, Team) use a 5-hour rolling window plus a weekly cap. The Claude API uses per-minute requests (RPM), per-minute tokens (TPM), and per-day requests (RPD), with thresholds that scale with your usage tier.",
    },
    {
      question: "What is a Claude session limit?",
      answer:
        "A Claude session limit is the cap that applies to a single 5-hour usage window on Pro, Max, or Team. Once you cross the threshold within that window, you are locked out of the full-capability model until enough older requests fall off the rolling window.",
    },
    {
      question: "What is Claude's weekly rate limit?",
      answer:
        "Claude's weekly rate limit is a 7-day rolling cap added in 2026 on top of the existing 5-hour session limit. Both windows are enforced together, so you can hit the weekly cap even when your 5-hour window is clear. The Max $200 tier has a substantially higher weekly allowance than Pro.",
    },
    {
      question: "When does my Claude session reset?",
      answer:
        "Claude sessions never reset cleanly. Each individual request expires 5 hours after it was made, so your usable headroom rebuilds gradually as old requests fall off the rolling window. Heavy usage at 9 AM regenerates capacity at 2 PM, not at a fixed daily reset.",
    },
  ],
  "avoid-claude-rate-limits": [
    {
      question: "What is Claude's weekly rate limit?",
      answer:
        "Claude's weekly rate limit is a 7-day rolling cap Anthropic introduced in 2026 to prevent the heaviest users from monopolizing capacity. It applies on top of the 5-hour session limit, and both have to be under their thresholds for you to keep working.",
    },
    {
      question: "How long is a Claude session?",
      answer:
        "A Claude session uses a 5-hour rolling window. Each request you make counts against your allowance for the next 5 hours, then drops off automatically. You do not get a fixed daily reset — usage decays continuously as old requests age out.",
    },
    {
      question: "What's the difference between a Claude session limit and a rate limit?",
      answer:
        "Session limit refers specifically to the 5-hour rolling window cap on Pro, Max, and Team plans. Rate limit is the umbrella term covering all enforcement: the 5-hour session cap, the weekly cap, and the per-minute and per-day caps for API users.",
    },
    {
      question: "How do I avoid hitting Claude's rate limit?",
      answer:
        "Monitor your usage in real time, spread heavy work across multiple sessions, reduce context size with a .claudeignore file, use smaller models for simple tasks, and set threshold alerts at 70-80%. Tools like Tokemon show your current usage, burn rate, and projected time-to-limit from the menu bar.",
    },
  ],
  "claude-code-cost-calculator": [
    {
      question: "How much does Claude Code cost?",
      answer:
        "Claude Code on the API is billed per token. Opus 4 costs $15 per million input tokens and $75 per million output tokens. Sonnet 4 is $3/$15. Haiku is the cheapest at roughly $0.80/$4. A typical day of intensive coding ranges from $5 to $40 in API spend depending on model mix and prompt-caching usage.",
    },
    {
      question: "Does prompt caching reduce Claude API cost?",
      answer:
        "Yes. Prompt caching cuts repeat-context costs significantly. Cache writes cost 25 percent more than a normal input token, but cache reads cost 90 percent less. For long-running coding sessions where the same context is reused across many requests, caching can reduce total spend by 30-70 percent.",
    },
    {
      question: "What's the cheapest way to use Claude Code?",
      answer:
        "Subscribe to Claude Pro or Max instead of using the API directly. Claude Pro is $20/month flat with a generous 5-hour rolling window, and Max gives you 5x or 20x that for $100 or $200. For most individual developers a subscription is cheaper than per-token API billing.",
    },
  ],
  "claude-token-monitoring-guide": [
    {
      question: "How do I monitor my Claude token usage?",
      answer:
        "On Claude Code with Pro or Max, install Tokemon — a free macOS menu bar app that shows live usage percentage, burn rate per hour, and per-project breakdown. For API users, parse the x-ratelimit-remaining-tokens header on every API response or check the Anthropic Console dashboard.",
    },
    {
      question: "Why does Claude token monitoring matter?",
      answer:
        "Without monitoring you cannot see rate limits coming until you hit them mid-task. Live token tracking lets you forecast time-to-limit, choose lighter models for non-critical work, and catch unexpected cost spikes. It also gives freelancers a defensible per-project cost record for client billing.",
    },
    {
      question: "What's the difference between input tokens and output tokens?",
      answer:
        "Input tokens are everything you send to Claude — your prompt, context files, and conversation history. Output tokens are what Claude generates back. On the API, output tokens are 4-5x more expensive than input tokens, so concise prompts that ask for focused responses are the cheapest pattern.",
    },
  ],
};

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

    // FAQPage schema for posts with curated FAQ entries (eligible for PAA snippets)
    const faqEntries = FAQ_MAP[slug];
    const faqJsonLd = faqEntries
      ? {
          "@context": "https://schema.org",
          "@type": "FAQPage",
          mainEntity: faqEntries.map((f) => ({
            "@type": "Question",
            name: f.question,
            acceptedAnswer: {
              "@type": "Answer",
              text: f.answer,
            },
          })),
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
        {faqJsonLd && (
          <script
            type="application/ld+json"
            dangerouslySetInnerHTML={{ __html: JSON.stringify(faqJsonLd) }}
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
