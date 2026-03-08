import { ImageResponse } from "next/og";
import { getCompareSlugs } from "@/lib/compare";
import type { CompareMetadata } from "@/lib/compare";

export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

export function generateStaticParams() {
  const slugs = getCompareSlugs();
  return slugs.map((slug) => ({ slug }));
}

export default async function OGImage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const mod = await import(`../../../../content/compare/${slug}.mdx`);
  const metadata = mod.metadata as CompareMetadata;

  return new ImageResponse(
    (
      <div
        style={{
          display: "flex",
          flexDirection: "column",
          width: "100%",
          height: "100%",
          background: "#0a0a0a",
          padding: "60px",
          justifyContent: "center",
        }}
      >
        <div
          style={{
            color: "#e8853b",
            fontSize: "24px",
            marginBottom: "16px",
          }}
        >
          tokemon.ai/compare
        </div>
        <div
          style={{
            color: "#ededed",
            fontSize: "56px",
            fontWeight: "bold",
            lineHeight: 1.2,
          }}
        >
          {metadata.title}
        </div>
        <div
          style={{
            color: "#777",
            fontSize: "24px",
            marginTop: "24px",
          }}
        >
          {metadata.description}
        </div>
      </div>
    ),
    { ...size }
  );
}
