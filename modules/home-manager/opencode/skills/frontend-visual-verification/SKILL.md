---
name: frontend-visual-verification
description: Use for live frontend layout, responsive, overflow, clipping, and screenshot verification.
---

# Frontend Visual Verification

Use for layout/responsive proof. Runtime/DOM/console/network diagnosis -> `browser-devtools-investigation`.

1. State claim and affected viewports.
2. Capture live DOM/screenshot evidence.
3. Test affected breakpoints. Check overflow and clipping.
4. Re-run after change.

Service failure:

```bash
systemctl --user status opencode-chromium-devtools
journalctl --user -u opencode-chromium-devtools
```

Return evidence only:

```
Claim: ...
Viewport: ...
Result: pass|fail|inconclusive
Evidence: ...
Risk: ...
```

No raw transcript.
