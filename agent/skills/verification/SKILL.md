---
name: verification
description: Prove claims with fresh checks before saying work is complete or fixed
---

# Verification

## Overview

Support success claims with the smallest sufficient check that proves them.

Core rule: every positive claim needs fresh evidence from this session.

## Workflow

1. Name the exact claim: tests pass, build succeeds, bug fixed.
2. Capture candidate receipt before checks:
   - worktree: `opencode-candidate-id`
   - PR: `opencode-candidate-id --base REF --head REF`
   - record exact receipt; never fabricate hashes; evidence valid only for that revision
3. Pick the smallest sufficient check: test, build, typecheck, lint, reproduction, browser proof, source inspection. Bound scope and cost upfront; match depth to `code-review` risk tiers.
4. Reuse valid same-session evidence below or run the chosen check to completion; prefer direct evidence for the claim. Await pending checks or report their status.
5. Inspect full output: exit status, failures, warnings, skipped steps.
6. Re-check receipt before reporting. Drift -> assess which checks are affected and rerun those needed; never relabel an old receipt as new evidence.
7. Report claim, command, observed result, decision (`pass`/`fail`/`partial`), residual risk. No meaningful check -> verification pending.

## Candidate Scope and Role

- compare receipts at the same scope; worktree and PR hashes differ
- PR receipt covers committed diff only; full PR proof requires clean checkout where HEAD equals PR head, matched by head/base/merge_base
- dirty/mismatched checkout -> report partial coverage and what was actually verified; no full PR-proof claim
- no candidate receipt -> label unbound evidence; no revision-bound signoff; never fabricate hashes
- verifier supplies proof; reviewer owns risk judgment; do not claim overall review complete
- do not commit, push, rebase, merge, or approve delivery

## Evidence Reuse and Cost

- Reuse fresh same-session evidence for the same claim, candidate revision, and scope; retain the exact command and result. Run checks for claims whose evidence is stale, unrelated, or missing.
- An agent's evidence packet is usable when it includes command, exit status/result, scope and candidate receipt, and relevant output. Inspect that evidence and request any missing details before deciding whether a rerun is needed.
- After candidate changes, assess affected checks and document any unaffected evidence retained with its original receipt and limits; identify the additional checks needed for new-revision or full PR proof.
- If a check is unexpectedly slow, broad, or blocked, pause and report the limit or ask how to proceed. Preserve required proof and label partial coverage as partial.

## Minimum Standard

- behavioral change: reproduce the original issue or run the closest real test
- code change: inspect diagnostics for changed files when available
- high-risk change: independent targeted proof; add broader regression checks when they cover a concrete risk the targeted check misses

## Check Scope

- Prompt/docs-only changes: inspect the diff and run relevant text checks.
- Configuration changes: start with relevant parsing, schema validation, or evaluation; use runtime checks for runtime claims.
- Build the affected output when the claim requires it; justify broader checks with the additional risk they cover.
- Follow repo-local guidance for ecosystem-specific commands; keep deployment, dependency updates, and rollback exercises within explicitly approved scope.

## Red Flags

- should pass now
- looks good to me
- probably fixed
- trusting an agent or tool summary without inspecting the output

## Output Style

- tie each claim to the command or check that proved it
- keep the result factual and concise
- call out remaining risk when verification is partial
