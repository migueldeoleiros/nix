---
description: Investigate a bug methodically before proposing or applying a fix
---

Use the `debugging` skill for this task.

For browser-based debugging:
- use `frontend-visual-verification` for CSS/layout bugs
- use `browser-devtools-investigation` for non-layout browser triage (remote repro, interaction paths, console/network failures)

Follow a root-cause-first workflow:
- restate the observed failure in concrete terms
- gather direct evidence first: exact errors, reproduction steps, recent changes, and affected files
- compare the broken path to a working path or reference implementation when possible
- form one specific hypothesis at a time and test it with the smallest useful check
- do not propose or apply fixes until the likely root cause is identified

If information is missing, say exactly what evidence is still needed.

User request:

$ARGUMENTS
