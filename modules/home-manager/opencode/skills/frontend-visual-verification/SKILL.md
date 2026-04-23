---
name: Frontend Visual Verification
description: Verify frontend visual/layout issues using Chrome DevTools MCP
---

# Frontend Visual Verification

## Overview

Use Chrome DevTools via the `chrome-devtools` MCP to inspect, diagnose, and verify frontend visual issues. This skill is intentionally layout-focused: overflow, clipping, responsive regressions, and CSS/DOM rendering bugs.

For broader browser tasks (remote bug triage, end-to-end interaction debugging, scraping-flow prototyping), use the `browser-devtools-investigation` skill.

## Prerequisites

Before using DevTools MCP tools, ensure Chromium is available as a debuggable instance:

```bash
opencode-ensure-chromium-devtools
```

This attaches to an existing debuggable Chromium on `127.0.0.1:9222` (or launches one if none is found). Check `/tmp/opencode-chromium-devtools.log` on failures.

## Workflow

### 1. Detect the issue

Use DevTools to confirm the problem exists. Check:

```javascript
// Horizontal overflow
document.documentElement.scrollWidth > window.innerWidth

// Element causing overflow - run in browser console
[...document.querySelectorAll('*')]
  .filter(el => el.scrollWidth > el.clientWidth)
  .slice(0, 5)
  .map(el => ({ tag: el.tagName, class: el.className, width: el.scrollWidth, clientWidth: el.clientWidth }))

// Viewport info
window.innerWidth + 'x' + window.innerHeight
```

### 2. Test across viewports

Test at common breakpoints:

- Mobile: 390px width
- Tablet: 768px width
- Desktop: 1280px width
- Wide: 1920px width

For each viewport, capture:

- Whether overflow is present
- Which element is causing it
- Key computed styles (width, max-width, overflow, flex/grid properties)

### 3. Verify the fix

After code changes:

1. Refresh the page
2. Re-run the overflow detection
3. Confirm at all affected viewports
4. Report findings concisely

## MCP Tools Available

When `chrome-devtools` MCP is active, prefer these tools for layout verification:

- Navigation/pages: `chrome-devtools_new_page`, `chrome-devtools_navigate_page`, `chrome-devtools_list_pages`, `chrome-devtools_select_page`
- DOM/state inspection: `chrome-devtools_take_snapshot`, `chrome-devtools_evaluate_script`
- Visual evidence: `chrome-devtools_take_screenshot`
- Resize/emulation: `chrome-devtools_resize_page`, `chrome-devtools_emulate`
- Console/network checks: `chrome-devtools_list_console_messages`, `chrome-devtools_list_network_requests`, `chrome-devtools_get_network_request`
- Interaction helpers (when needed): `chrome-devtools_click`, `chrome-devtools_fill`, `chrome-devtools_press_key`, `chrome-devtools_wait_for`

## Output Style

For each verification, report:

```
Claim: [what was verified]
Viewport: [width tested]
Result: pass/fail
Evidence: [key DOM/CSS finding or screenshot confirmation]
```

Keep output concise. Include only the 1-2 key observations that prove or disprove the claim. Do not dump raw DevTools output.

## Red Flags

- verifying only at one viewport when the bug is viewport-dependent
- accepting a fix without re-running the overflow detection check
- trusting CSS source without checking computed styles in the live DOM

## Context Management

When running DevTools MCP tools in a subagent, summarize the output immediately and return only the synthesis to the parent context. Raw tool output should never flow unfiltered into the main conversation context.
