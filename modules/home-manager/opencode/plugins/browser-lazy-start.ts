import type { Plugin } from "@opencode-ai/plugin"

export const BrowserLazyStart: Plugin = async ({ $ }) => ({
  "tool.execute.before": async (input) => {
    if (input.tool.startsWith("chrome-devtools_") || input.tool.startsWith("playwright_")) {
      await $`opencode-ensure-chromium-devtools`
    }
  },
})
