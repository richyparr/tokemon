import { test, expect } from "@playwright/test";

/**
 * E2E tests for blog SEO metadata, sitemap, and navigation.
 * Covers SEO-03 (structured data), SEO-04 (sitemap), SEO-05 (navigation).
 */

/* --- Blog SEO metadata --- */

test.describe("Blog SEO metadata", () => {
  test("blog post has correct title meta tag", async ({ page }) => {
    await page.goto("/blog/how-to-track-claude-code-usage", {
      waitUntil: "domcontentloaded",
    });
    const title = await page.title();
    expect(title).toContain("Track Claude Code Usage");
    expect(title).toContain("Tokemon");
  });

  test("blog post has og:type article", async ({ page }) => {
    await page.goto("/blog/how-to-track-claude-code-usage", {
      waitUntil: "domcontentloaded",
    });
    const ogType = await page
      .locator('meta[property="og:type"]')
      .getAttribute("content");
    expect(ogType).toBe("article");
  });

  test("blog post has Article JSON-LD", async ({ page }) => {
    await page.goto("/blog/how-to-track-claude-code-usage", {
      waitUntil: "domcontentloaded",
    });
    const jsonLd = await page
      .locator('script[type="application/ld+json"]')
      .allTextContents();
    const articleSchema = jsonLd.find((j) => j.includes('"Article"'));
    expect(articleSchema).toBeDefined();
    const parsed = JSON.parse(articleSchema!);
    expect(parsed["@type"]).toBe("Article");
    expect(parsed.headline).toBeTruthy();
    expect(parsed.author).toBeTruthy();
  });

  test("comparison page has Article JSON-LD", async ({ page }) => {
    await page.goto("/compare/tokemon-vs-ccusage", {
      waitUntil: "domcontentloaded",
    });
    const jsonLd = await page
      .locator('script[type="application/ld+json"]')
      .allTextContents();
    const articleSchema = jsonLd.find((j) => j.includes('"Article"'));
    expect(articleSchema).toBeDefined();
    const parsed = JSON.parse(articleSchema!);
    expect(parsed["@type"]).toBe("Article");
    expect(parsed.headline).toContain("ccusage");
  });

  test("comparison page has correct title", async ({ page }) => {
    await page.goto("/compare/tokemon-vs-ccusage", {
      waitUntil: "domcontentloaded",
    });
    const title = await page.title();
    expect(title).toContain("Tokemon vs ccusage");
    expect(title).toContain("Tokemon");
  });
});

/* --- Sitemap --- */

test.describe("Sitemap", () => {
  test("sitemap includes blog URLs", async ({ page }) => {
    const response = await page.goto("/sitemap.xml", {
      waitUntil: "domcontentloaded",
    });
    const body = await response?.text();
    expect(body).toContain("tokemon.ai/blog");
    expect(body).toContain("how-to-track-claude-code-usage");
  });

  test("sitemap includes comparison page URLs", async ({ page }) => {
    const response = await page.goto("/sitemap.xml", {
      waitUntil: "domcontentloaded",
    });
    const body = await response?.text();
    expect(body).toContain("tokemon-vs-ccusage");
    expect(body).toContain("tokemon-vs-claudebar");
  });

  test("sitemap has correct structure", async ({ page }) => {
    const response = await page.goto("/sitemap.xml", {
      waitUntil: "domcontentloaded",
    });
    const body = await response?.text();
    // Should have urlset namespace
    expect(body).toContain("urlset");
    // Should include homepage
    expect(body).toContain("https://tokemon.ai");
  });
});

/* --- Navigation --- */

test.describe("Navigation", () => {
  test("nav includes Blog link", async ({ page }) => {
    await page.goto("/", { waitUntil: "domcontentloaded" });
    const blogLink = page.locator('nav a[href="/blog"]');
    await expect(blogLink).toBeVisible();
    await expect(blogLink).toContainText("Blog");
  });

  test("blog link navigates to blog index", async ({ page }) => {
    await page.goto("/", { waitUntil: "domcontentloaded" });
    const blogLink = page.locator('nav a[href="/blog"]');
    await blogLink.click();
    await page.waitForURL("/blog");
    await expect(page.locator("h1")).toContainText("Blog");
  });
});
