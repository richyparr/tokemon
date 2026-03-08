import { test, expect } from "@playwright/test";

/**
 * E2E tests for blog and comparison page functionality.
 * Covers SEO-01 (blog index), SEO-02 (blog posts), SEO-06 (comparison pages).
 */

/* --- Blog index --- */

test.describe("Blog index", () => {
  test("blog index page loads and lists posts", async ({ page }) => {
    await page.goto("/blog", { waitUntil: "domcontentloaded" });
    await expect(page.locator("h1")).toContainText("Blog");
    // Should have at least 3 blog post links
    const postLinks = page.locator('a[href^="/blog/"]');
    await expect(postLinks).toHaveCount(3);
  });

  test("blog posts are sorted newest first", async ({ page }) => {
    await page.goto("/blog", { waitUntil: "domcontentloaded" });
    const dates = await page.locator("time").allTextContents();
    // Verify descending date order
    for (let i = 1; i < dates.length; i++) {
      expect(
        new Date(dates[i - 1]).getTime()
      ).toBeGreaterThanOrEqual(new Date(dates[i]).getTime());
    }
  });

  test("each blog card has title, description, and date", async ({ page }) => {
    await page.goto("/blog", { waitUntil: "domcontentloaded" });
    const cards = page.locator('a[href^="/blog/"]');
    const count = await cards.count();
    expect(count).toBeGreaterThanOrEqual(3);

    for (let i = 0; i < count; i++) {
      const card = cards.nth(i);
      // Each card should have an h2 title and a time element
      await expect(card.locator("h2")).toBeVisible();
      await expect(card.locator("time")).toBeVisible();
    }
  });
});

/* --- Blog post --- */

test.describe("Blog post", () => {
  test("blog post page renders MDX content", async ({ page }) => {
    await page.goto("/blog/how-to-track-claude-code-usage", {
      waitUntil: "domcontentloaded",
    });
    await expect(page.locator("h1")).toBeVisible();
    await expect(page.locator("article")).toBeVisible();
    // Should have prose styling
    await expect(page.locator(".prose")).toBeVisible();
  });

  test("blog post has syntax-highlighted code blocks", async ({ page }) => {
    await page.goto("/blog/how-to-track-claude-code-usage", {
      waitUntil: "domcontentloaded",
    });
    // rehype-pretty-code wraps code in pre > code
    const codeBlock = page.locator("pre code");
    await expect(codeBlock.first()).toBeVisible();
  });

  test("blog post has back-to-blog link", async ({ page }) => {
    await page.goto("/blog/how-to-track-claude-code-usage", {
      waitUntil: "domcontentloaded",
    });
    const backLink = page.locator('a[href="/blog"]');
    await expect(backLink).toBeVisible();
  });

  test("blog post has CTA section", async ({ page }) => {
    await page.goto("/blog/how-to-track-claude-code-usage", {
      waitUntil: "domcontentloaded",
    });
    await expect(page.getByText("Try Tokemon Free")).toBeVisible();
  });

  test("unknown blog slug returns 404", async ({ page }) => {
    const response = await page.goto("/blog/nonexistent-post", {
      waitUntil: "domcontentloaded",
    });
    expect(response?.status()).toBe(404);
  });
});

/* --- Comparison pages --- */

test.describe("Comparison pages", () => {
  test("comparison page renders content", async ({ page }) => {
    await page.goto("/compare/tokemon-vs-ccusage", {
      waitUntil: "domcontentloaded",
    });
    await expect(page.locator("h1")).toBeVisible();
    await expect(page.locator("article")).toBeVisible();
  });

  test("comparison page has comparison table", async ({ page }) => {
    await page.goto("/compare/tokemon-vs-ccusage", {
      waitUntil: "domcontentloaded",
    });
    await expect(page.locator("table").first()).toBeVisible();
  });

  test("claudebar comparison page renders", async ({ page }) => {
    await page.goto("/compare/tokemon-vs-claudebar", {
      waitUntil: "domcontentloaded",
    });
    await expect(page.locator("h1")).toBeVisible();
    await expect(page.locator("table").first()).toBeVisible();
  });

  test("comparison page has CTA section", async ({ page }) => {
    await page.goto("/compare/tokemon-vs-ccusage", {
      waitUntil: "domcontentloaded",
    });
    await expect(page.getByText("Try Tokemon Free")).toBeVisible();
  });

  test("unknown compare slug returns 404", async ({ page }) => {
    const response = await page.goto("/compare/nonexistent", {
      waitUntil: "domcontentloaded",
    });
    expect(response?.status()).toBe(404);
  });
});
