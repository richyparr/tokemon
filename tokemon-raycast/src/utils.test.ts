import { describe, it, expect } from "vitest";
import { formatCountdown, computePace, parseResetDate, formatPercentage, usageColor } from "./utils";

describe("formatCountdown", () => {
  it("returns 'resetting' for 0 seconds", () => {
    expect(formatCountdown(0)).toBe("resetting");
  });

  it("returns 'resetting' for negative seconds", () => {
    expect(formatCountdown(-5)).toBe("resetting");
  });

  it("formats seconds only", () => {
    expect(formatCountdown(45)).toBe("45s");
  });

  it("formats minutes and seconds", () => {
    expect(formatCountdown(125)).toBe("2m 5s");
  });

  it("formats hours, minutes, and seconds", () => {
    expect(formatCountdown(3661)).toBe("1h 1m 1s");
  });

  it("formats whole hours with zero minutes and seconds", () => {
    expect(formatCountdown(7200)).toBe("2h 0m 0s");
  });
});

describe("computePace", () => {
  // Helper: build a resetsAt Date that is `remainingMs` ms in the future
  // Window = 18000000ms (5 hours)
  const windowMs = 18_000_000;

  function makeResetsAt(elapsedFraction: number): Date {
    const remaining = windowMs * (1 - elapsedFraction);
    return new Date(Date.now() + remaining);
  }

  it("returns 'on-track' when utilization matches elapsed fraction (50/50)", () => {
    const resetsAt = makeResetsAt(0.5);
    expect(computePace(50, resetsAt)).toBe("on-track");
  });

  it("returns 'behind' when burning fast (80% used, 20% elapsed)", () => {
    const resetsAt = makeResetsAt(0.2);
    expect(computePace(80, resetsAt)).toBe("behind");
  });

  it("returns 'ahead' when lots of headroom (10% used, 80% elapsed)", () => {
    const resetsAt = makeResetsAt(0.8);
    expect(computePace(10, resetsAt)).toBe("ahead");
  });

  it("returns 'unknown' when resetsAt is null", () => {
    expect(computePace(50, null)).toBe("unknown");
  });

  it("returns 'on-track' at exact boundary delta = 10", () => {
    // delta = utilization - expected = 10 exactly => on-track (not behind)
    const resetsAt = makeResetsAt(0.5); // expected = 50
    expect(computePace(60, resetsAt)).toBe("on-track");
  });

  it("returns 'on-track' at exact boundary delta = -10", () => {
    // delta = utilization - expected = -10 exactly => on-track (not ahead)
    const resetsAt = makeResetsAt(0.5); // expected = 50
    expect(computePace(40, resetsAt)).toBe("on-track");
  });
});

describe("parseResetDate", () => {
  it("returns a Date for a valid ISO string", () => {
    const result = parseResetDate("2026-02-22T12:00:00Z");
    expect(result).toBeInstanceOf(Date);
    expect(isNaN((result as Date).getTime())).toBe(false);
  });

  it("returns null for null", () => {
    expect(parseResetDate(null)).toBeNull();
  });

  it("returns null for undefined", () => {
    expect(parseResetDate(undefined)).toBeNull();
  });

  it("returns null for empty string", () => {
    expect(parseResetDate("")).toBeNull();
  });

  it("returns null for garbage input", () => {
    expect(parseResetDate("garbage")).toBeNull();
  });
});

describe("formatPercentage", () => {
  it("formats a whole number", () => {
    expect(formatPercentage(50)).toBe("50%");
  });

  it("rounds fractional percentages", () => {
    expect(formatPercentage(99.7)).toBe("100%");
  });

  it("formats zero", () => {
    expect(formatPercentage(0)).toBe("0%");
  });

  it("returns '--' for null", () => {
    expect(formatPercentage(null)).toBe("--");
  });

  it("returns '--' for undefined", () => {
    expect(formatPercentage(undefined)).toBe("--");
  });
});

describe("usageColor", () => {
  it("returns 'green' for 0%", () => {
    expect(usageColor(0)).toBe("green");
  });

  it("returns 'green' for 39%", () => {
    expect(usageColor(39)).toBe("green");
  });

  it("returns 'yellow' for 40%", () => {
    expect(usageColor(40)).toBe("yellow");
  });

  it("returns 'yellow' for 69%", () => {
    expect(usageColor(69)).toBe("yellow");
  });

  it("returns 'orange' for 70%", () => {
    expect(usageColor(70)).toBe("orange");
  });

  it("returns 'orange' for 89%", () => {
    expect(usageColor(89)).toBe("orange");
  });

  it("returns 'red' for 90%", () => {
    expect(usageColor(90)).toBe("red");
  });

  it("returns 'red' for 100%", () => {
    expect(usageColor(100)).toBe("red");
  });
});
