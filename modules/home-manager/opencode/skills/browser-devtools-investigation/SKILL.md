---
name: browser-devtools-investigation
description: Use for live browser repro, runtime, DOM, console, network, and interaction diagnosis.
---

# Browser DevTools Investigation

Use for browser diagnosis. Layout-only work -> `frontend-visual-verification`.

1. State claim, URL, preconditions, minimum repro.
2. Observe DOM, console, network, or screenshot.
3. Test one hypothesis at a time.
4. Re-run path after change.

Service failure:

```bash
systemctl --user status opencode-chromium-devtools
journalctl --user -u opencode-chromium-devtools
```

Return evidence only:

```
Claim: ...
Path: ...
Result: pass|fail|inconclusive
Evidence: ...
Risk: ...
```

No raw transcript.
