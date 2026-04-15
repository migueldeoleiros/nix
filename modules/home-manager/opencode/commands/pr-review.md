---
description: Review PR with findings-first output and scalability focus
---

Use the `pr-review` skill for this task.

Review workflow:
- follow the `pr-review` skill process and output format as the source of truth
- compare against the repo's default/base branch (usually obvious from `origin/HEAD`)
- prioritize correctness, regressions, scalability/performance risks, and missing safeguards
- include test/verification gaps for risky changes
- present findings first, ordered by severity, with concrete file references
- keep the summary brief and secondary

Run these baseline checks before writing findings:

```bash
git fetch origin
BASE_BRANCH="$(git symbolic-ref --short refs/remotes/origin/HEAD | cut -d/ -f2)"
git log --oneline "origin/$BASE_BRANCH..HEAD"
git diff --name-status "origin/$BASE_BRANCH...HEAD"
git diff "origin/$BASE_BRANCH...HEAD"
```

If there are no findings, state that explicitly and include residual risks or testing gaps.

User request:

$ARGUMENTS
