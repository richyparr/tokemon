import type { PaceStatus } from "./types";

/**
 * Format a countdown in seconds to a human-readable string.
 * Returns "resetting" for 0 or negative values.
 */
export function formatCountdown(seconds: number): string {
  if (seconds <= 0) return "resetting";
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = seconds % 60;
  if (h > 0) return `${h}h ${m}m ${s}s`;
  if (m > 0) return `${m}m ${s}s`;
  return `${s}s`;
}

/**
 * Determine whether a usage window is on-track, ahead, or behind.
 *
 * The 5-hour window is 18,000,000 ms. We calculate how much of the window
 * has elapsed and compare to actual utilization. A delta within ±10 points
 * is considered "on-track".
 *
 * @param utilization - 0-100 percentage of window used
 * @param resetsAt    - Date when the window resets, or null if unknown
 */
export function computePace(utilization: number, resetsAt: Date | null): PaceStatus {
  if (resetsAt === null) return "unknown";
  const windowMs = 18_000_000; // 5 hours in milliseconds
  const remaining = resetsAt.getTime() - Date.now();
  const elapsed = windowMs - remaining;
  const elapsedFraction = Math.min(1, Math.max(0, elapsed / windowMs));
  const expectedUtilization = elapsedFraction * 100;
  const delta = utilization - expectedUtilization;
  if (delta > 10) return "behind";
  if (delta < -10) return "ahead";
  return "on-track";
}

/**
 * Safely parse an ISO-8601 date string. Returns null for any falsy or invalid input.
 */
export function parseResetDate(iso: string | undefined | null): Date | null {
  if (!iso) return null;
  const d = new Date(iso);
  if (isNaN(d.getTime())) return null;
  return d;
}

/**
 * Format a 0-100 number as a percentage string, rounding to the nearest integer.
 * Returns "--" for null or undefined.
 */
export function formatPercentage(pct: number | null | undefined): string {
  if (pct === null || pct === undefined) return "--";
  return `${Math.round(pct)}%`;
}

/**
 * Map a utilization percentage to a plain color name string.
 * The UI layer (index.tsx) maps these to Raycast Color constants.
 *
 * Thresholds:
 *  >= 90  → "red"
 *  >= 70  → "orange"
 *  >= 40  → "yellow"
 *  else   → "green"
 */
export function usageColor(pct: number): string {
  if (pct >= 90) return "red";
  if (pct >= 70) return "orange";
  if (pct >= 40) return "yellow";
  return "green";
}
