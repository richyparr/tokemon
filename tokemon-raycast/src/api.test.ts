import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { parseCredentials, isTokenExpiringSoon, refreshAccessToken } from "./api";

describe("parseCredentials", () => {
  it("parses a valid Keychain JSON blob", () => {
    const blob = JSON.stringify({
      claudeAiOauth: {
        accessToken: "acc_123",
        refreshToken: "ref_456",
        expiresAt: 1700000000000,
      },
    });
    const result = parseCredentials(blob);
    expect(result).toEqual({
      accessToken: "acc_123",
      refreshToken: "ref_456",
      expiresAt: 1700000000000,
    });
  });

  it("returns null for a raw token string", () => {
    expect(parseCredentials("sk-ant-abc123")).toBeNull();
  });

  it("returns null for empty string", () => {
    expect(parseCredentials("")).toBeNull();
  });

  it("returns null for whitespace", () => {
    expect(parseCredentials("   ")).toBeNull();
  });

  it("returns null when accessToken is missing", () => {
    const blob = JSON.stringify({
      claudeAiOauth: {
        refreshToken: "ref_456",
        expiresAt: 1700000000000,
      },
    });
    expect(parseCredentials(blob)).toBeNull();
  });

  it("returns null when refreshToken is missing", () => {
    const blob = JSON.stringify({
      claudeAiOauth: {
        accessToken: "acc_123",
        expiresAt: 1700000000000,
      },
    });
    expect(parseCredentials(blob)).toBeNull();
  });

  it("returns null when expiresAt is missing", () => {
    const blob = JSON.stringify({
      claudeAiOauth: {
        accessToken: "acc_123",
        refreshToken: "ref_456",
      },
    });
    expect(parseCredentials(blob)).toBeNull();
  });

  it("returns null when expiresAt is not a number", () => {
    const blob = JSON.stringify({
      claudeAiOauth: {
        accessToken: "acc_123",
        refreshToken: "ref_456",
        expiresAt: "not-a-number",
      },
    });
    expect(parseCredentials(blob)).toBeNull();
  });

  it("returns null for JSON without claudeAiOauth key", () => {
    const blob = JSON.stringify({ someOtherKey: { accessToken: "abc" } });
    expect(parseCredentials(blob)).toBeNull();
  });

  it("handles whitespace around valid JSON", () => {
    const blob = `  ${JSON.stringify({
      claudeAiOauth: {
        accessToken: "acc_123",
        refreshToken: "ref_456",
        expiresAt: 1700000000000,
      },
    })}  `;
    const result = parseCredentials(blob);
    expect(result).not.toBeNull();
    expect(result?.accessToken).toBe("acc_123");
  });
});

describe("isTokenExpiringSoon", () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("returns true when token expires within 10 minutes", () => {
    vi.setSystemTime(new Date("2026-01-01T00:00:00Z"));
    const creds = {
      accessToken: "acc",
      refreshToken: "ref",
      expiresAt: Date.now() + 5 * 60 * 1000, // 5 minutes from now
    };
    expect(isTokenExpiringSoon(creds)).toBe(true);
  });

  it("returns true when token is already expired", () => {
    vi.setSystemTime(new Date("2026-01-01T00:00:00Z"));
    const creds = {
      accessToken: "acc",
      refreshToken: "ref",
      expiresAt: Date.now() - 1000, // 1 second ago
    };
    expect(isTokenExpiringSoon(creds)).toBe(true);
  });

  it("returns false when token has plenty of time left", () => {
    vi.setSystemTime(new Date("2026-01-01T00:00:00Z"));
    const creds = {
      accessToken: "acc",
      refreshToken: "ref",
      expiresAt: Date.now() + 60 * 60 * 1000, // 1 hour from now
    };
    expect(isTokenExpiringSoon(creds)).toBe(false);
  });

  it("returns true at exactly 10-minute boundary", () => {
    vi.setSystemTime(new Date("2026-01-01T00:00:00Z"));
    const creds = {
      accessToken: "acc",
      refreshToken: "ref",
      expiresAt: Date.now() + 10 * 60 * 1000, // exactly 10 min
    };
    expect(isTokenExpiringSoon(creds)).toBe(true);
  });

  it("returns false at 10 minutes + 1ms", () => {
    vi.setSystemTime(new Date("2026-01-01T00:00:00Z"));
    const creds = {
      accessToken: "acc",
      refreshToken: "ref",
      expiresAt: Date.now() + 10 * 60 * 1000 + 1,
    };
    expect(isTokenExpiringSoon(creds)).toBe(false);
  });
});

describe("refreshAccessToken", () => {
  const originalFetch = globalThis.fetch;

  afterEach(() => {
    globalThis.fetch = originalFetch;
  });

  it("returns new credentials on success", async () => {
    globalThis.fetch = vi.fn().mockResolvedValueOnce({
      ok: true,
      json: async () => ({
        access_token: "new_acc",
        refresh_token: "new_ref",
        expires_in: 3600,
      }),
    });

    const before = Date.now();
    const result = await refreshAccessToken("old_ref");
    const after = Date.now();

    expect(result.accessToken).toBe("new_acc");
    expect(result.refreshToken).toBe("new_ref");
    expect(result.expiresAt).toBeGreaterThanOrEqual(before + 3600 * 1000);
    expect(result.expiresAt).toBeLessThanOrEqual(after + 3600 * 1000);

    expect(globalThis.fetch).toHaveBeenCalledWith(
      "https://console.anthropic.com/v1/oauth/token",
      expect.objectContaining({
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
      }),
    );
  });

  it("throws TokenError on non-ok response", async () => {
    globalThis.fetch = vi.fn().mockResolvedValueOnce({
      ok: false,
      status: 401,
    });

    await expect(refreshAccessToken("bad_ref")).rejects.toThrow("Token refresh failed");
  });

  it("sends correct form body", async () => {
    globalThis.fetch = vi.fn().mockResolvedValueOnce({
      ok: true,
      json: async () => ({
        access_token: "new",
        refresh_token: "new_ref",
        expires_in: 3600,
      }),
    });

    await refreshAccessToken("my_refresh_token");

    const callArgs = (globalThis.fetch as ReturnType<typeof vi.fn>).mock.calls[0];
    const body = callArgs[1].body;
    const params = new URLSearchParams(body);
    expect(params.get("grant_type")).toBe("refresh_token");
    expect(params.get("refresh_token")).toBe("my_refresh_token");
    expect(params.get("client_id")).toBe("9d1c250a-e61b-44d9-88ed-5944d1962f5e");
  });
});
