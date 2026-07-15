---
description: Review candidate technical tests with role-calibrated scorecards
agent: reviewer
subtask: true
---

Use the `tech-test-review` skill for this task.

Review goal:
- evaluate the candidate submission against the original test prompt and target role level
- support algorithms, Java exercises, frontend/Figma tasks, backend/full-stack tasks, and AI-agent workflow tests
- produce a fair hiring signal, not just a generic code review
- separate evidence from assumptions and mark confidence clearly

Repository context, when available:

Recent commit history:
!`git log --oneline -20`

If the review depends on a running frontend, screenshots, Figma, or browser behavior:
- delegate `browser`: layout -> `frontend-visual-verification`; runtime/DOM/console/network -> `browser-devtools-investigation`
- if those artifacts are unavailable, state the limitation instead of guessing

Required output:
- recommendation: `strong hire`, `hire`, `lean hire`, `lean no-hire`, `no-hire`, or `insufficient evidence`
- target level and confidence
- scorecard with 3-6 categories
- strongest positive signals and strongest concerns
- role calibration: whether the submission meets the target level
- follow-up interview questions
- residual risk and missing evidence

User request:

$ARGUMENTS
