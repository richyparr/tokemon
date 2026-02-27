import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  metadataBase: new URL("https://tokemon.ai"),
  title: "Tokemon — Claude Usage Monitor for macOS & Raycast",
  description:
    "Free, open-source Claude usage monitor for macOS and Raycast. Track token limits, burn rate, per-project costs, and team budgets in real-time from your menu bar. Get alerts before you hit rate limits.",
  keywords: [
    "Claude usage monitor",
    "Claude rate limit tracker",
    "Claude Code usage",
    "Claude token tracker",
    "Anthropic usage monitor",
    "Claude menu bar",
    "Claude macOS app",
    "Claude Raycast extension",
    "AI token usage",
    "Claude burn rate",
  ],
  openGraph: {
    type: "website",
    siteName: "Tokemon",
    title: "Tokemon — Claude Usage Monitor for macOS & Raycast",
    description:
      "Free, open-source Claude usage monitor. Track token limits, burn rate, per-project costs, and team budgets in real-time. Never hit a rate limit by surprise.",
    url: "https://tokemon.ai",
    images: [
      {
        url: "/og.png",
        width: 1200,
        height: 630,
        alt: "Tokemon — Claude usage monitor floating on your macOS desktop",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "Tokemon — Claude Usage Monitor for macOS & Raycast",
    description:
      "Free, open-source Claude usage monitor. Track token limits, burn rate, per-project costs, and team budgets in real-time.",
    images: ["/og.png"],
  },
  icons: { icon: "/icon.png", apple: "/icon.png" },
  other: {
    "theme-color": "#000000",
  },
};

const jsonLd = {
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  name: "Tokemon",
  applicationCategory: "DeveloperApplication",
  operatingSystem: "macOS 14+",
  offers: {
    "@type": "Offer",
    price: "0",
    priceCurrency: "USD",
  },
  description:
    "Open-source Claude usage monitor for macOS and Raycast. Track token limits, burn rate, per-project costs, and team budgets in real-time.",
  url: "https://tokemon.ai",
  downloadUrl: "https://github.com/richyparr/tokemon/releases/latest",
  softwareVersion: "4.0.0",
  author: {
    "@type": "Person",
    name: "Richard Parr",
    url: "https://github.com/richyparr",
  },
  license: "https://opensource.org/licenses/MIT",
  screenshot: "https://tokemon.ai/og.png",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <head>
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
        />
      </head>
      <body
        className={`${geistSans.variable} ${geistMono.variable} font-sans antialiased text-[#ededed] overflow-x-hidden`}
        style={{ margin: 0, background: "radial-gradient(ellipse 80% 50% at 50% 0%, #0a0a0a, #000 50%)" }}
      >
        {children}
      </body>
    </html>
  );
}
