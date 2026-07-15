---
description: Investigate a bug methodically before proposing or applying a fix
agent: build
subtask: true
---

Use the `debugging` skill for this task.

Current git status:
!`git status --short`

Recent commits:
!`git log --oneline -10`

For browser-based debugging:
- delegate `browser`: layout -> `frontend-visual-verification`; runtime/DOM/console/network -> `browser-devtools-investigation`

Follow a root-cause-first workflow:
- restate the observed failure in concrete terms
- gather direct evidence first: exact errors, reproduction steps, recent changes, and affected files
- compare the broken path to a working path or reference implementation when possible
- form one specific hypothesis at a time and test it with the smallest useful check
- do not propose or apply fixes until the likely root cause is identified

If information is missing, say exactly what evidence is still needed.

User request:

$ARGUMENTS
