import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  timeout: 30_000,
  expect: { timeout: 10_000 },
  fullyParallel: true,
  retries: 0,
  reporter: [["html", { open: "never" }]],
  use: {
    baseURL: "http://localhost:3001",
    screenshot: "on",
    video: "retain-on-failure",
  },
  webServer: {
    command: "npm run dev -- -p 3001",
    port: 3001,
    reuseExistingServer: true,
    timeout: 30_000,
  },
  projects: [
    // Desktop
    { name: "Desktop Chrome", use: { ...devices["Desktop Chrome"] } },
    { name: "Desktop Safari", use: { ...devices["Desktop Safari"] } },
    { name: "Desktop Firefox", use: { ...devices["Desktop Firefox"] } },
    // Tablets
    { name: "iPad Pro 11", use: { ...devices["iPad Pro 11"] } },
    { name: "iPad Mini", use: { ...devices["iPad Mini"] } },
    // Mobile
    { name: "iPhone 15 Pro", use: { ...devices["iPhone 15 Pro"] } },
    { name: "iPhone SE", use: { ...devices["iPhone SE"] } },
  ],
});
