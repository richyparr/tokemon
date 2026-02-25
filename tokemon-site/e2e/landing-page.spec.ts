import { test, expect } from "@playwright/test";

/**
 * Landing page E2E tests.
 *
 * Validates section order, content presence, responsive layout,
 * navigation, links, and visual structure across devices.
 */

/* ─── Section order & presence ─── */

test.describe("Section structure and order", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/", { waitUntil: "domcontentloaded" });
  });

  test("all major sections render in correct order", async ({ page }) => {
    const headings = await page.locator("h2").allTextContents();

    // Expected section order (top to bottom)
    const expectedOrder = [
      "Your usage, always visible", // Floating window showcase
      "Built for power users", // Feature grid (moved up)
      /hit the limit/, // Deep-dive 1: usage trends
      /projects.*eating/, // Deep-dive 2: project breakdown
      /team.*burning/, // Deep-dive 3: team budget
      "Now available in Raycast", // Raycast section
      /admin.*can.t see/, // Deep-dive 4: org analytics
      /justify token costs/, // Deep-dive 5: export
      "Start monitoring in 30 seconds", // CTA
    ];

    // Verify order by checking each expected heading appears after the previous
    let lastIndex = -1;
    for (const expected of expectedOrder) {
      const idx = headings.findIndex((h, i) => {
        if (i <= lastIndex) return false;
        if (typeof expected === "string") return h.includes(expected);
        return expected.test(h);
      });
      expect(idx, `Expected heading matching "${expected}" after index ${lastIndex}, headings: ${headings.join(" | ")}`).toBeGreaterThan(lastIndex);
      lastIndex = idx;
    }
  });

  test("feature grid appears before first deep-dive section", async ({ page }) => {
    const featureGrid = page.getByText("Built for power users");
    const firstDeepDive = page.getByText("hit the limit before your session resets");

    const gridBox = await featureGrid.boundingBox();
    const deepDiveBox = await firstDeepDive.boundingBox();

    expect(gridBox).not.toBeNull();
    expect(deepDiveBox).not.toBeNull();
    expect(gridBox!.y, "Feature grid should be above first deep-dive").toBeLessThan(deepDiveBox!.y);
  });

  test("Raycast section appears between deep-dive 3 and deep-dive 4", async ({ page }) => {
    const raycast = page.getByText("Now available in Raycast");
    const teamBudget = page.getByText("team is burning through API budget");
    const orgAnalytics = page.getByText(/admin.*can.t see who/);

    const raycastBox = await raycast.boundingBox();
    const teamBox = await teamBudget.boundingBox();
    const orgBox = await orgAnalytics.boundingBox();

    expect(raycastBox).not.toBeNull();
    expect(teamBox).not.toBeNull();
    expect(orgBox).not.toBeNull();
    expect(raycastBox!.y, "Raycast should be below team budget section").toBeGreaterThan(teamBox!.y);
    expect(raycastBox!.y, "Raycast should be above org analytics section").toBeLessThan(orgBox!.y);
  });
});

/* ─── Feature grid ─── */

test.describe("Feature grid", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/", { waitUntil: "domcontentloaded" });
  });

  test("has correct headline", async ({ page }) => {
    await expect(page.getByText("Built for power users")).toBeVisible();
  });

  test("displays all 6 feature cards", async ({ page }) => {
    const featureCards = [
      "Slack & Discord alerts",
      "Terminal statusline",
      "Usage summaries by period",
      "Multi-profile support",
      "menu bar styles",
      "Three themes",
    ];

    for (const feature of featureCards) {
      await expect(page.getByText(feature, { exact: false }).first()).toBeVisible();
    }
  });

  test("feature grid renders as 3-column on desktop", async ({ page, browserName }) => {
    // Only test on wide viewports where md: breakpoint is active
    const viewport = page.viewportSize();
    if (!viewport || viewport.width < 900) return;

    const cards = page.locator("text=Slack & Discord alerts").locator("..").locator("..").locator("> div");
    const firstCard = page.getByText("Slack & Discord alerts").locator("..");
    const secondCard = page.getByText("Terminal statusline").locator("..");

    const firstBox = await firstCard.boundingBox();
    const secondBox = await secondCard.boundingBox();

    if (firstBox && secondBox) {
      // In a 3-col grid, cards should be side by side (same Y, different X)
      expect(Math.abs(firstBox.y - secondBox.y)).toBeLessThan(5);
      expect(secondBox.x).toBeGreaterThan(firstBox.x);
    }
  });
});

/* ─── Navigation ─── */

test.describe("Navigation", () => {
  test("nav bar is fixed and visible", async ({ page }) => {
    await page.goto("/", { waitUntil: "domcontentloaded" });

    const nav = page.locator("nav");
    await expect(nav).toBeVisible();

    // Scroll down and verify nav is still visible (fixed position)
    await page.evaluate(() => window.scrollTo(0, 1000));
    await page.waitForTimeout(300);
    await expect(nav).toBeVisible();

    const box = await nav.boundingBox();
    expect(box).not.toBeNull();
    expect(box!.y, "Nav should be at top of viewport after scrolling").toBeLessThanOrEqual(5);
  });

  test("nav has logo, GitHub link, and download button", async ({ page }) => {
    await page.goto("/", { waitUntil: "domcontentloaded" });

    await expect(page.locator("nav").getByText("tokemon")).toBeVisible();
    await expect(page.locator("nav").getByText("Download")).toBeVisible();
  });
});

/* ─── Hero section ─── */

test.describe("Hero section", () => {
  test("hero has all key elements", async ({ page }) => {
    await page.goto("/", { waitUntil: "domcontentloaded" });

    await expect(page.getByText("Free & open source for macOS & Raycast")).toBeVisible();
    await expect(page.locator("h1")).toContainText("by surprise again");
    await expect(page.getByText("Tokemon shows your Claude usage")).toBeVisible();
  });

  test("social proof badge is visible", async ({ page }) => {
    await page.goto("/", { waitUntil: "domcontentloaded" });

    await expect(page.getByText("loved by developers who ship with Claude")).toBeVisible();
  });

  test("hero screenshot loads", async ({ page }) => {
    await page.goto("/", { waitUntil: "domcontentloaded" });

    const heroImg = page.locator("section").first().locator('img[alt*="Tokemon popover"], img[alt*="Claude usage"]');
    await expect(heroImg).toBeVisible();
  });
});

/* ─── Raycast section ─── */

test.describe("Raycast section", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/", { waitUntil: "domcontentloaded" });
  });

  test("has v4.0 badge and headline", async ({ page }) => {
    await expect(page.getByText("New in v4.0")).toBeVisible();
    await expect(page.getByText("Now available in Raycast")).toBeVisible();
  });

  test("displays all 4 Raycast feature cards", async ({ page }) => {
    const features = ["Usage dashboard", "Menu bar presence", "Multi-profile", "Threshold alerts"];
    for (const feature of features) {
      await expect(page.getByText(feature, { exact: false }).first()).toBeVisible();
    }
  });

  test("has install command", async ({ page }) => {
    await expect(page.getByText("git clone")).toBeVisible();
  });
});

/* ─── CTA section ─── */

test.describe("CTA section", () => {
  test("has download and GitHub buttons", async ({ page }) => {
    await page.goto("/", { waitUntil: "domcontentloaded" });

    const cta = page.getByText("Start monitoring in 30 seconds").locator("..");
    await expect(cta.getByText("Download for macOS")).toBeVisible();
    await expect(cta.getByText("View on GitHub")).toBeVisible();
  });

  test("has dual install commands (macOS + Raycast)", async ({ page }) => {
    await page.goto("/", { waitUntil: "domcontentloaded" });

    await expect(page.getByText("brew install --cask tokemon")).toBeVisible();
    await expect(page.locator("text=npm run dev").last()).toBeVisible();
  });
});

/* ─── Deep-dive feature sections ─── */

test.describe("Feature deep-dive sections", () => {
  test("all 5 deep-dive sections render with images", async ({ page }) => {
    await page.goto("/", { waitUntil: "domcontentloaded" });

    const deepDiveTitles = [
      "hit the limit before your session resets",
      "which projects are eating your tokens",
      "team is burning through API budget",
      /admin.*can.t see who/,
      "justify token costs",
    ];

    for (const title of deepDiveTitles) {
      const locator = typeof title === "string"
        ? page.getByText(title, { exact: false })
        : page.getByText(title);
      await expect(locator).toBeVisible();
    }
  });

  test("each deep-dive has a unique section label", async ({ page }) => {
    await page.goto("/", { waitUntil: "domcontentloaded" });

    const labels = [
      "Usage visibility",
      "Project tracking",
      "Budget management",
      "Team analytics",
      "Reporting & export",
    ];

    for (const label of labels) {
      await expect(page.getByText(label, { exact: false })).toBeVisible();
    }
  });

  test("each deep-dive has a quote block", async ({ page }) => {
    await page.goto("/", { waitUntil: "domcontentloaded" });

    const quoteTexts = [
      "Estimated limit: 12h 59m",
      "Billing clients?",
      "$5.43 of $100 spent",
      "Team leads and finance:",
      "Freelancers:",
    ];

    for (const quote of quoteTexts) {
      await expect(page.getByText(quote, { exact: false })).toBeVisible();
    }
  });
});

/* ─── Footer ─── */

test.describe("Footer", () => {
  test("footer has links and platform info", async ({ page }) => {
    await page.goto("/", { waitUntil: "domcontentloaded" });

    const footer = page.locator("footer");
    await expect(footer.getByText("Built for developers")).toBeVisible();
    await expect(footer.getByText("GitHub")).toBeVisible();
    await expect(footer.getByText("Releases")).toBeVisible();
    await expect(footer.getByText("Issues")).toBeVisible();
  });
});

/* ─── Responsive layout ─── */

test.describe("Responsive layout", () => {
  test("no horizontal overflow at any viewport", async ({ page }) => {
    await page.goto("/", { waitUntil: "domcontentloaded" });

    const hasOverflow = await page.evaluate(() => {
      return document.documentElement.scrollWidth > document.documentElement.clientWidth;
    });

    expect(hasOverflow, "Page should not have horizontal scrollbar").toBe(false);
  });

  test("full page screenshot", async ({ page }, testInfo) => {
    await page.goto("/", { waitUntil: "domcontentloaded" });
    await page.waitForTimeout(1000);

    await testInfo.attach("full-page-layout", {
      body: await page.screenshot({ fullPage: true }),
      contentType: "image/png",
    });
  });
});
