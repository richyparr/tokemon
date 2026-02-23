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
  title: "Tokemon — Claude Usage Monitor for macOS",
  description:
    "A floating window that shows your Claude rate limits in real-time. Track session limits, burn rate, project costs, and team budgets from your menu bar.",
  openGraph: {
    type: "website",
    siteName: "Tokemon",
    title: "Tokemon — Claude Usage Monitor for macOS",
    description:
      "A floating window that shows your Claude rate limits in real-time. Track session limits, burn rate, project costs, and team budgets from your menu bar.",
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
    title: "Tokemon — Claude Usage Monitor for macOS",
    description:
      "A floating window that shows your Claude rate limits in real-time. Never hit a limit by surprise again.",
    images: ["/og.png"],
  },
  icons: { icon: "/icon.png", apple: "/icon.png" },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body
        className={`${geistSans.variable} ${geistMono.variable} font-sans antialiased bg-black text-[#ededed] overflow-x-hidden`}
        style={{ margin: 0 }}
      >
        {children}
      </body>
    </html>
  );
}
