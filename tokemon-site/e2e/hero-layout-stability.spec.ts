import { test, expect } from "@playwright/test";

/**
 * Hero section layout stability tests.
 *
 * Validates that the typing animation in the hero h1 does NOT cause:
 * - Layout shifts (height changes in h1 or hero section)
 * - Text overflow beyond the hero container
 * - Content jumping during text cycling
 *
 * Runs across all configured devices (desktop, tablet, mobile).
 */

test.describe("Hero section layout stability", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/", { waitUntil: "domcontentloaded" });
  });

  test("hero h1 height remains stable during typing animation", async ({
    page,
  }) => {
    const h1 = page.locator("h1").first();
    await expect(h1).toBeVisible();

    // Get initial height after page load
    const initialBox = await h1.boundingBox();
    expect(initialBox).not.toBeNull();
    const initialHeight = initialBox!.height;

    // Sample the h1 height over 8 seconds (covers multiple animation cycles)
    // Typing speed is 80ms/char, delete is 40ms/char, pause is 2500ms
    // Full cycle for "rate limit" (10 chars): 800ms type + 2500ms pause + 400ms delete = ~3700ms
    const heights: number[] = [initialHeight];
    for (let i = 0; i < 16; i++) {
      await page.waitForTimeout(500);
      const box = await h1.boundingBox();
      if (box) heights.push(box.height);
    }

    const minHeight = Math.min(...heights);
    const maxHeight = Math.max(...heights);
    const heightDrift = maxHeight - minHeight;

    // Allow max 2px drift (subpixel rendering). Anything more = layout shift.
    expect(
      heightDrift,
      `h1 height shifted by ${heightDrift}px (min: ${minHeight}, max: ${maxHeight}). ` +
        `Heights sampled: [${heights.join(", ")}]`
    ).toBeLessThanOrEqual(2);
  });

  test("hero section height remains stable during typing animation", async ({
    page,
  }) => {
    const hero = page.locator("section").first();
    await expect(hero).toBeVisible();

    const initialBox = await hero.boundingBox();
    expect(initialBox).not.toBeNull();
    const initialHeight = initialBox!.height;

    const heights: number[] = [initialHeight];
    for (let i = 0; i < 16; i++) {
      await page.waitForTimeout(500);
      const box = await hero.boundingBox();
      if (box) heights.push(box.height);
    }

    const minHeight = Math.min(...heights);
    const maxHeight = Math.max(...heights);
    const heightDrift = maxHeight - minHeight;

    expect(
      heightDrift,
      `Hero section height shifted by ${heightDrift}px (min: ${minHeight}, max: ${maxHeight}). ` +
        `This causes the page to jump during animation.`
    ).toBeLessThanOrEqual(2);
  });

  test("CTA buttons position remains stable during typing animation", async ({
    page,
  }) => {
    // The elements below the h1 should not move vertically
    const cta = page.locator("section").first().locator("a, button").first();
    await expect(cta).toBeVisible();

    const initialBox = await cta.boundingBox();
    expect(initialBox).not.toBeNull();
    const initialY = initialBox!.y;

    const yPositions: number[] = [initialY];
    for (let i = 0; i < 16; i++) {
      await page.waitForTimeout(500);
      const box = await cta.boundingBox();
      if (box) yPositions.push(box.y);
    }

    const minY = Math.min(...yPositions);
    const maxY = Math.max(...yPositions);
    const yDrift = maxY - minY;

    expect(
      yDrift,
      `CTA button Y position shifted by ${yDrift}px (min: ${minY}, max: ${maxY}). ` +
        `Elements below the hero title are jumping.`
    ).toBeLessThanOrEqual(2);
  });

  test("typing text does not overflow hero container", async ({ page }) => {
    const h1 = page.locator("h1").first();
    const container = page.locator("h1").first().locator("..");

    await expect(h1).toBeVisible();

    // Check over several animation cycles
    for (let i = 0; i < 10; i++) {
      await page.waitForTimeout(800);

      const h1Box = await h1.boundingBox();
      const containerBox = await container.boundingBox();

      if (h1Box && containerBox) {
        // h1 should not be wider than its parent container
        expect(
          h1Box.width,
          `h1 (${h1Box.width}px) overflows container (${containerBox.width}px) at sample ${i}`
        ).toBeLessThanOrEqual(containerBox.width + 1); // 1px tolerance
      }
    }
  });

  test("hero screenshot at each animation phase", async ({ page }, testInfo) => {
    const hero = page.locator("section").first();
    await expect(hero).toBeVisible();

    // Capture screenshots at different points during the animation
    // to visually verify no layout issues
    for (let i = 0; i < 6; i++) {
      await page.waitForTimeout(1500);
      await testInfo.attach(`hero-animation-frame-${i}`, {
        body: await hero.screenshot(),
        contentType: "image/png",
      });
    }
  });
});

test.describe("Hero responsive rendering", () => {
  test("hero renders without horizontal scrollbar", async ({ page }) => {
    await page.goto("/", { waitUntil: "domcontentloaded" });

    const hasHorizontalScroll = await page.evaluate(() => {
      return document.documentElement.scrollWidth > document.documentElement.clientWidth;
    });

    expect(hasHorizontalScroll, "Page has horizontal scrollbar — content overflows viewport").toBe(
      false
    );
  });

  test("hero text is visible and not clipped", async ({ page }) => {
    await page.goto("/", { waitUntil: "domcontentloaded" });

    const h1 = page.locator("h1").first();
    await expect(h1).toBeVisible();
    await expect(h1).toContainText("by surprise again");

    // Verify the h1 is within the viewport
    const box = await h1.boundingBox();
    expect(box).not.toBeNull();
    const viewport = page.viewportSize()!;
    expect(box!.x).toBeGreaterThanOrEqual(0);
    expect(box!.x + box!.width).toBeLessThanOrEqual(viewport.width + 1);
  });

  test("full page screenshot", async ({ page }, testInfo) => {
    await page.goto("/", { waitUntil: "domcontentloaded" });
    await page.waitForTimeout(1000);

    await testInfo.attach("full-page", {
      body: await page.screenshot({ fullPage: true }),
      contentType: "image/png",
    });
  });
});
