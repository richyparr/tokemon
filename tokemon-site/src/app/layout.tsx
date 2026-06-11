import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import { Analytics } from "@vercel/analytics/next";
import { APP_VERSION } from "@/lib/version";
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
  title: "Tokemon — Claude Code Usage Tracker & Monitor for macOS",
  description:
    "Free Claude usage tracker for macOS & Raycast. Real-time burn rate, per-project costs, team budgets, and rate-limit alerts — right in your menu bar.",
  keywords: [
    "claude usage tracker",
    "claude code usage tracker",
    "claude usage monitor",
    "claude code usage monitor",
    "claude code cost",
    "claude rate limit",
    "claude session limit",
    "claude statusline",
    "claude token tracker",
    "anthropic api usage",
    "claude menu bar",
    "claude macos app",
  ],
  alternates: {
    canonical: "https://tokemon.ai",
  },
  openGraph: {
    type: "website",
    siteName: "Tokemon",
    title: "Tokemon — Claude Code Usage Tracker & Monitor for macOS",
    description:
      "Free Claude usage tracker for macOS & Raycast. Real-time burn rate, per-project costs, team budgets, and rate-limit alerts — right in your menu bar.",
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
    title: "Tokemon — Claude Code Usage Tracker & Monitor for macOS",
    description:
      "Free Claude usage tracker for macOS & Raycast. Real-time burn rate, per-project costs, team budgets, and rate-limit alerts.",
    images: ["/og.png"],
  },
  icons: { icon: "/icon.png", apple: "/icon.png" },
  other: {
    "theme-color": "#000000",
  },
};

const jsonLd = [
  {
    "@context": "https://schema.org",
    "@type": "SoftwareApplication",
    name: "Tokemon",
    applicationCategory: "DeveloperApplication",
    operatingSystem: "macOS 26+",
    offers: {
      "@type": "Offer",
      price: "0",
      priceCurrency: "USD",
    },
    description:
      "Open-source Claude usage monitor for macOS and Raycast. Track token limits, burn rate, per-project costs, and team budgets in real-time.",
    url: "https://tokemon.ai",
    downloadUrl: "https://github.com/richyparr/tokemon/releases/latest",
    softwareVersion: APP_VERSION,
    author: {
      "@type": "Person",
      name: "Richard Parr",
      url: "https://github.com/richyparr",
    },
    license: "https://opensource.org/licenses/MIT",
    screenshot: "https://tokemon.ai/og.png",
  },
  {
    "@context": "https://schema.org",
    "@type": "Organization",
    name: "Tokemon",
    url: "https://tokemon.ai",
    logo: "https://tokemon.ai/icon.png",
    sameAs: [
      "https://github.com/richyparr/tokemon",
    ],
    founder: {
      "@type": "Person",
      name: "Richard Parr",
      url: "https://github.com/richyparr",
    },
  },
  {
    "@context": "https://schema.org",
    "@type": "WebSite",
    name: "Tokemon",
    url: "https://tokemon.ai",
  },
];

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
        <Analytics />
      </body>
    </html>
  );
}
