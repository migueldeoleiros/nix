---
description: Review PR with findings-first output and scalability focus
agent: reviewer
subtask: true
---

Use the `pr-review` skill for this task.

Review workflow:
- follow the `pr-review` skill process and output format as the source of truth
- output findings in compact, structured format (severity + title, evidence, impact, fix)
- use `$1` as the base branch and `$2` as the source branch
- if `$1` is empty, default the base branch to `develop`
- if `$2` is empty, compare `HEAD` against the base branch
- prioritize correctness, regressions, scalability/performance risks, and missing safeguards
- include test/verification gaps for risky changes
- present findings first, ordered by severity, with concrete file references
- keep the summary brief and secondary

Baseline repository context:

Current git status:
!`git status --short`

Resolved base/source:
!`BASE="$1"; [ -n "$BASE" ] || BASE="develop"; SOURCE="$2"; [ -n "$SOURCE" ] || SOURCE="HEAD"; printf 'base=%s\nsource=%s\n' "$BASE" "$SOURCE"`

Current branch:
!`git branch --show-current`

Recent commits against base branch:
!`BASE="$1"; [ -n "$BASE" ] || BASE="develop"; SOURCE="$2"; [ -n "$SOURCE" ] || SOURCE="HEAD"; git log --oneline "origin/$BASE..$SOURCE" 2>/dev/null || git log --oneline "$BASE..$SOURCE" 2>/dev/null || true`

Changed files against base branch:
!`BASE="$1"; [ -n "$BASE" ] || BASE="develop"; SOURCE="$2"; [ -n "$SOURCE" ] || SOURCE="HEAD"; git diff --name-status "origin/$BASE...$SOURCE" 2>/dev/null || git diff --name-status "$BASE...$SOURCE" 2>/dev/null || true`

Diff against base branch:
!`BASE="$1"; [ -n "$BASE" ] || BASE="develop"; SOURCE="$2"; [ -n "$SOURCE" ] || SOURCE="HEAD"; git diff "origin/$BASE...$SOURCE" 2>/dev/null || git diff "$BASE...$SOURCE" 2>/dev/null || true`

If the shell context is empty or branch resolution is ambiguous, resolve the base/source pair explicitly before writing findings.

Usage examples:
- `/pr-review` (review current branch against develop)
- `/pr-review develop` (review current branch against develop)
- `/pr-review develop feature/manual-editing` (review feature/manual-editing against develop)

If there are no findings, state that explicitly and include residual risks or testing gaps.

User request:

$ARGUMENTS
