---
name: PR Review
description: Review PR commits against develop, focus on hidden risks, scalability, and high-impact mistakes
---

# PR Review

## Overview

Review the full PR delta against the first existing branch in this order: `develop`, `main`, `master`.

Core rule: findings first, ordered by severity, with concrete evidence.

## Scope

Base comparison:

```bash
git fetch origin
BASE_BRANCH="$(for b in develop main master; do git show-ref --verify --quiet "refs/remotes/origin/$b" && { printf "%s" "$b"; break; }; done)"
if [ -z "$BASE_BRANCH" ]; then
  echo "No base branch found on origin (checked: develop, main, master)" >&2
  exit 1
fi
git diff --name-status "origin/$BASE_BRANCH...HEAD"
git log --oneline "origin/$BASE_BRANCH..HEAD"
git diff "origin/$BASE_BRANCH...HEAD"
```

Always review all commits in the PR range (`origin/$BASE_BRANCH..HEAD`) and the combined diff (`origin/$BASE_BRANCH...HEAD`).

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
   - only after functional and risk concerns are covered

## Process

1. Understand intended behavior from commits/PR description.
2. Compare each commit to the evolving branch state, then inspect full net diff.
3. Look for hidden failure modes at load and at boundary conditions.
4. Validate assumptions against nearby code and existing tests.
5. Record findings with severity, file reference, and why it matters.

## What To Call Out Explicitly

- Hot paths that may degrade at 10x traffic or data volume.
- Places where complexity grows with input size unexpectedly.
- Missing safeguards (limits, pagination, circuit breakers, deadlines).
- State transitions that can drift under retries/concurrency.
- Large PRs where split/ordering of commits hides regressions.

## Output Format

- Findings first, ordered: `high` -> `medium` -> `low`.
- Each finding includes:
  - short title
  - severity
  - evidence (`path:line` or command output reference)
  - impact (what breaks now or later)
  - suggested fix direction (brief)
- After findings, add:
  - open questions/assumptions
  - brief overall risk summary
- If no findings, say so clearly and list residual risks/testing gaps.

## Red Flags

- reviewing only changed files without considering call sites
- relying on one commit diff and missing net effect of the branch
- focusing on style while skipping scaling or correctness risks
- saying "looks fine" without evidence or verification paths
