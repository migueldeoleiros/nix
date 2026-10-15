---
name: verification
description: Prove claims with fresh checks before saying work is complete or fixed
---

# Verification

## Overview

Do not claim success from intuition. Run the check that proves it.

Core rule: every positive claim needs fresh evidence from this session.

## Workflow

1. Name the exact claim: tests pass, build succeeds, bug fixed.
2. Capture candidate receipt before checks:
   - worktree: `opencode-candidate-id`
   - PR: `opencode-candidate-id --base REF --head REF`
   - record exact receipt; never fabricate hashes; evidence valid only for that revision
3. Pick strongest practical check: test, build, typecheck, lint, reproduction, browser proof, source inspection. Match depth to `code-review` risk tiers.
4. Run full check; real commands > weak proxies; no stale output.
5. Inspect full output: exit status, failures, warnings, skipped steps.
6. Re-check receipt before reporting. Drift -> invalidate only stale-revision evidence.
7. Report claim, command, observed result, decision (`pass`/`fail`/`partial`), residual risk. No meaningful check -> verification pending.

## Candidate Scope and Role

- compare receipts at the same scope; worktree and PR hashes differ
- PR receipt covers committed diff only; full PR proof requires clean checkout where HEAD equals PR head, matched by head/base/merge_base
- dirty/mismatched checkout -> report partial coverage and what was actually verified; no full PR-proof claim
- no candidate receipt -> label unbound evidence; no revision-bound signoff; never fabricate hashes
- verifier supplies proof; reviewer owns risk judgment; do not claim overall review complete
- do not commit, push, rebase, merge, or approve delivery

## Minimum Standard

- behavioral change: reproduce the original issue or run the closest real test
- code change: inspect diagnostics for changed files when available
- risky change: prefer both a targeted check and a broader regression check

## Red Flags

- should pass now
- looks good to me
- probably fixed
- trusting an agent or tool summary without inspecting the output

## Output Style

- tie each claim to the command or check that proved it
- keep the result factual and concise
- call out remaining risk when verification is partial
