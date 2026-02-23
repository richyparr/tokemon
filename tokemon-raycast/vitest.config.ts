import { defineConfig } from "vitest/config";
import path from "path";

export default defineConfig({
  css: { postcss: {} },
  test: {
    globals: false,
    alias: {
      "@raycast/api": path.resolve(__dirname, "src/__mocks__/@raycast/api.ts"),
    },
  },
});
