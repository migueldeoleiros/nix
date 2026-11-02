---
name: pr-review
description: Review full PR delta; find hidden risks, scaling failures, high-impact mistakes
---

# PR Review

## Overview

Review full PR delta. Infer branches from user request.
Prefer `<source-branch> into <base-branch>`.
One branch given: base = given branch; source = `HEAD`.
No branches: source = `HEAD`; base = first existing `develop`, `main`, `master`.

Core rule: findings first. Severity order. Concrete evidence.

## Scope

Fetch remote first. Use `git fetch`, not `git pull`; no local merge/rebase.
Default remote: `origin`. Different PR remote: use that.
Fetch fails: report; ask before stale-ref review.
Local commits: keep `HEAD`. Named branches: prefer fresh remote-tracking refs.
Explicit local-only review: keep local refs.

Fetch, then compare:

```bash
REMOTE="origin" # Replace with the PR remote when different.
git fetch "$REMOTE" || exit 1
SOURCE_BRANCH="<source-branch-from-request-or-HEAD>"
BASE_BRANCH="<base-branch-from-request-or-empty>"
if [ -z "$BASE_BRANCH" ]; then
  BASE_BRANCH="$(for b in develop main master; do
    if git show-ref --verify --quiet "refs/remotes/$REMOTE/$b"; then printf "%s" "$REMOTE/$b"; break; fi
    if git show-ref --verify --quiet "refs/heads/$b"; then printf "%s" "$b"; break; fi
  done)"
fi
if [ -z "$BASE_BRANCH" ]; then
  echo "No base branch found (checked: develop, main, master)" >&2
  exit 1
fi
for var in SOURCE_BRANCH BASE_BRANCH; do
  branch="${!var}"
  if [ "$branch" != HEAD ] && git show-ref --verify --quiet "refs/remotes/$REMOTE/$branch"; then
    printf -v "$var" '%s' "$REMOTE/$branch"
  fi
done
git diff --name-status "$BASE_BRANCH...$SOURCE_BRANCH"
git log --oneline "$BASE_BRANCH..$SOURCE_BRANCH"
git diff "$BASE_BRANCH...$SOURCE_BRANCH"
```

Review every PR commit (`$BASE_BRANCH..$SOURCE_BRANCH`) plus net diff (`$BASE_BRANCH...$SOURCE_BRANCH`).

## Review Priorities

1. Correctness and regressions
   - behavior breaks, broken contracts, edge-case handling, unsafe assumptions

2. Scalability and performance risk
   - N+1 queries, quadratic loops, unbounded memory growth, sync/blocking hotspots
   - repeated expensive work in request paths
   - missing pagination, batching, caching, or backpressure where needed

3. Reliability and operability
   - weak error handling, retries without limits, missing timeouts, silent failures
   - non-idempotent operations in retryable paths

4. Security and data integrity
   - input validation gaps, authz/authn flaws, unsafe defaults, race-prone writes

5. Test and verification gaps
   - risky paths changed without meaningful tests or reproducible checks

6. Maintainability
    - last; correctness and risks first

## Process

1. Read commits/PR description. Establish intent.
2. Review each commit against evolving branch state. Then full net diff.
3. Check load failures, boundary cases, hidden risks.
4. Check assumptions against nearby code and tests.
5. Record severity, file reference, impact.

## Call Out

- Hot paths failing at 10x traffic/data.
- Unexpected complexity growth with input size.
- Missing limits, pagination, circuit breakers, deadlines.
- State drift under retries/concurrency.
- Regressions hidden by large PRs or commit ordering.

## Output Format

- Findings first: `high` -> `medium` -> `low` -> `info` or `low` risk.
- Each finding: compact block.
  - ``<severity>` <short title>``
  - `Evidence:` 1-3 file:line references (max 3)
  - `Impact:` one sentence; what breaks now/later
  - `Fix:` one sentence; fix direction
- Max 4 bullets per finding.
- Independent regressions: separate findings.
- After findings:
  - `Open questions` — unverified assumptions
  - `Risk summary` — 1-2 lines; overall severity
- No findings: say so. List residual risks/testing gaps.

## RDD Workflow for PR Review

Load `code-review`; follow its RDD workflow and risk tiers.
PR receipt: use resolved `$BASE_BRANCH` / `$SOURCE_BRANCH` from Scope.
`opencode-candidate-id --base "$BASE_BRANCH" --head "$SOURCE_BRANCH"`.
Keep this skill's PR coverage and output format. No worktree receipt for PR scope.

## Red Flags

- Changed files only; call sites ignored.
- One commit only; branch net effect missed.
- Style focus; scaling/correctness skipped.
- "Looks fine" without evidence or verification paths.
