---
description: Verify work with concrete evidence before claiming success
---

Use the `verification` skill for this task.

For browser-visible claims:
- use `frontend-visual-verification` for CSS/layout/responsive verification
- use `browser-devtools-investigation` for broader browser checks (remote repro, interactions, console/network evidence)

Before making any positive claim:
- identify the exact command or check that proves the claim
- run the full verification needed for the changed area
- read the output carefully, including failures, warnings, and exit status
- report only what the fresh evidence supports

If verification fails, explain the failure plainly and stop short of claiming success.

User request:

$ARGUMENTS
