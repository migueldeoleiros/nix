---
description: Review PR with findings-first output and scalability focus
---

Use the `pr-review` skill for this task.

Review workflow:
- follow the `pr-review` skill process and output format as the source of truth
- output findings in compact, structured format (severity + title, evidence, impact, fix)
- infer branches from natural phrasing when present (for example: `<source-branch> into <base-branch>`)
- if only one branch is specified, treat it as the base branch and compare against `HEAD`
- if no branch is specified, compare `HEAD` against the repo's default/base branch (usually obvious from `origin/HEAD`)
- prioritize correctness, regressions, scalability/performance risks, and missing safeguards
- include test/verification gaps for risky changes
- present findings first, ordered by severity, with concrete file references
- keep the summary brief and secondary

Run these baseline checks before writing findings:

```bash
git fetch origin
SOURCE_BRANCH="<source-branch-from-request-or-HEAD>"
BASE_BRANCH="<base-branch-from-request-or-empty>"
if [ -z "$BASE_BRANCH" ]; then
  BASE_BRANCH="$(git symbolic-ref --short refs/remotes/origin/HEAD | cut -d/ -f2)"
fi
git log --oneline "origin/$BASE_BRANCH..origin/$SOURCE_BRANCH"
git diff --name-status "origin/$BASE_BRANCH...origin/$SOURCE_BRANCH"
git diff "origin/$BASE_BRANCH...origin/$SOURCE_BRANCH"
```

Usage examples:
- `/pr-review feature/manual-editing into develop`
- `/pr-review my-branch into main focus on performance regressions`
- `/pr-review develop` (review current branch against develop)

If there are no findings, state that explicitly and include residual risks or testing gaps.

User request:

$ARGUMENTS
