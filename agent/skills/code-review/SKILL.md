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
4. Check whether tests or verification cover the important paths. Reuse valid available evidence under `verification`; inspect its command, result, scope/receipt, and relevant output. Rerun checks when evidence is missing, invalid, or affected by changes.
5. Write findings with severity and concrete references when possible.

Default budget: one initial review plus one delta re-review of fixes. Persistent or new substantial blockers -> keep them open, report them, and ask to extend review. Use deeper review for high risk or an explicit user review request.

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

## Risk Tiers

Risk is determined by changed paths and content, not file count.

- `low/passive`: docs or generated files with no config impact
- `medium`: ordinary code/config changes
- `high`: security, auth, data integrity, concurrency, shared contracts, irreversible/destructive, or untested hot paths

## RDD Workflow

Review is bound to an exact candidate revision. Use `opencode-candidate-id` to capture the receipt.

1. Capture candidate scope before reviewing:
   - worktree: `opencode-candidate-id`
   - PR: `opencode-candidate-id --base REF --head REF`
   - worktree hash covers staged/unstaged diff + untracked content; receipt records branch, head, base, merge_base, candidate sha256
2. Record the exact receipt. Never fabricate hashes.
3. Evidence is valid only for that candidate revision.
4. Compare receipts at the same scope; worktree and PR hashes differ. PR receipts cover the committed diff only; proof needs a worktree receipt or clean checkout at the PR head, matched by head/base/merge_base.
5. Classify risk tier using the canonical tiers above.
6. Use risk-proportional depth:
   - `low/passive`: lightweight scan
   - `medium`: targeted author checks by default; one focused review lens when reviewing; independent review for concrete risk or request
   - `high`: independent verifier proof plus deeper review
7. Re-check the candidate receipt before finalizing. Drift -> assess affected checks and re-review changed scope; preserve original receipts and limits for retained evidence, never relabel old evidence as proof of the new revision.
8. Verification proof is separate from review judgment.
9. Do not commit, push, rebase, merge, or approve delivery.

Read reviewed untracked files; paths alone are not evidence.

## Red Flags

- leading with praise or summary before findings
- focusing on formatting while missing functional risk
- assuming a path is covered without checking tests or verification evidence
