---
name: browser-devtools-investigation
description: Use Chrome DevTools MCP for browser debugging beyond CSS/layout verification
---

# Browser DevTools Investigation

## Overview

Use this skill when agents need browser access for non-layout tasks, such as reproducing remote bugs, inspecting runtime/network behavior, validating interaction flows, or prototyping scraping-oriented extraction logic.

Keep `frontend-visual-verification` for CSS/layout issues. Use this skill for broader browser investigation.

## Browser Setup

The `chrome-devtools` MCP server starts Chromium lazily when a DevTools tool is used. Use this command only for manual troubleshooting or when you need to pre-open a specific URL:

```bash
opencode-ensure-chromium-devtools
```

Set `OPENCODE_DEVTOOLS_URL` when you need that command to open a specific remote target first.

## When To Use

- remote production or staging bug triage in a real browser
- reproducing interaction bugs that require clicks, form input, or navigation across pages
- investigating console errors and failed network requests
- validating browser-visible behavior that cannot be proven by tests alone
- prototyping extraction flows (selectors, pagination behavior, dynamic content checks)

## Workflow

1. Define the claim or failure precisely.
   - What user-visible behavior is wrong?
   - What URL and preconditions are required (auth/session/feature flag)?

2. Reproduce in browser and capture baseline evidence.
   - open/select page
   - reproduce with minimal steps
   - collect only key evidence (one screenshot or one console/network finding)

3. Inspect the likely failure surface.
   - runtime: `chrome-devtools_list_console_messages`, `chrome-devtools_get_console_message`
   - network: `chrome-devtools_list_network_requests`, `chrome-devtools_get_network_request`
   - DOM/app state: `chrome-devtools_take_snapshot`, `chrome-devtools_evaluate_script`

4. Validate hypothesis with the smallest useful check.
   - run one focused interaction or script per hypothesis
   - avoid broad exploratory clicking without a concrete question

5. Re-verify after changes (or after applying a workaround).
   - repeat the same path used for baseline
   - report pass/fail against the original claim

## MCP Tools Available

When `chrome-devtools` MCP is active, common tools include:

- Page control: `chrome-devtools_new_page`, `chrome-devtools_navigate_page`, `chrome-devtools_list_pages`, `chrome-devtools_select_page`, `chrome-devtools_close_page`
- Interaction: `chrome-devtools_click`, `chrome-devtools_fill`, `chrome-devtools_fill_form`, `chrome-devtools_press_key`, `chrome-devtools_type_text`, `chrome-devtools_drag`, `chrome-devtools_upload_file`
- State inspection: `chrome-devtools_take_snapshot`, `chrome-devtools_evaluate_script`, `chrome-devtools_take_screenshot`
- Console/network: `chrome-devtools_list_console_messages`, `chrome-devtools_get_console_message`, `chrome-devtools_list_network_requests`, `chrome-devtools_get_network_request`
- Waiting/emulation: `chrome-devtools_wait_for`, `chrome-devtools_emulate`, `chrome-devtools_resize_page`
- Performance diagnostics (as needed): `chrome-devtools_lighthouse_audit`, `chrome-devtools_performance_start_trace`, `chrome-devtools_performance_stop_trace`, `chrome-devtools_performance_analyze_insight`, `chrome-devtools_take_memory_snapshot`

## Scraping Prototyping Notes

- verify selectors against dynamic DOM via `chrome-devtools_take_snapshot` and `chrome-devtools_evaluate_script`
- validate pagination/infinite-scroll behavior before coding extraction loops
- prefer stable attributes over brittle positional selectors
- respect site terms, robots directives, and rate limits before operationalizing a scraper

## Output Style

For each investigation, report:

```
Claim/Issue: [what was investigated]
Path: [URL + minimal reproduction steps]
Result: pass/fail/inconclusive
Evidence: [1-2 key console/network/DOM observations]
```

Keep output concise. Return synthesized evidence only; do not dump raw DevTools transcripts.
