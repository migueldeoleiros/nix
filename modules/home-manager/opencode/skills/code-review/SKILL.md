---
name: code-review
description: Review changes by surfacing concrete findings, regressions, and testing gaps first
---

# Code Review

## Overview

Review for correctness, risk, and test coverage before style.

Core rule: findings first, summary second.

## Review Priorities

1. Correctness
   - bugs, broken flows, wrong assumptions, invalid edge-case handling

2. Regression risk
   - behavior changes that likely break existing callers or workflows

3. Missing validation or error handling
   - unhandled failure modes, unsafe defaults, hidden state assumptions

4. Test gaps
   - important paths changed without coverage or without a convincing manual check

5. Maintainability
   - avoidable complexity with concrete cost, only after correctness concerns

## Review Process

1. Understand the intended behavior.
2. Inspect the changed code and the surrounding context.
3. Look for what can fail, not just what the code appears to do.
4. Check whether tests or verification cover the important paths.
5. Write findings with severity and concrete references when possible.

## Complexity Review Ladder

Use after correctness/security/data integrity, or when complexity creates those risks.

1. Can code, files, config, or dependencies be deleted without losing required behavior?
2. Can custom code be replaced with stdlib/native platform capability?
3. Can a new abstraction be replaced with an existing repo pattern?
4. Can a new dependency be avoided with existing dependencies or direct code?
5. Report only concrete impact: maintenance cost, correctness risk, performance, security, or delivery drag.

## Output Style

- list findings first, ordered by severity
- each finding should explain the problem, why it matters, and where it appears
- keep the change summary brief and secondary
- if there are no findings, say so explicitly and mention residual risks or test gaps

## Red Flags

- leading with praise or summary before findings
- focusing on formatting while missing functional risk
- assuming a path is covered without checking tests or verification evidence
