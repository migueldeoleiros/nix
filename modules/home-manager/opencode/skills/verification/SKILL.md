---
name: verification
description: Prove claims with fresh checks before saying work is complete or fixed
---

# Verification

## Overview

Do not claim success from intuition. Run the check that proves it.

Core rule: every positive claim needs fresh evidence from this session.

## Workflow

1. Name the claim.
   - Examples: tests pass, build succeeds, bug is fixed, review is complete.

2. Pick the proving check.
   - Tests for behavior changes.
   - Typecheck or diagnostics for typed code.
   - Build for integration confidence.
   - Manual reproduction for user-visible behavior.

3. Run the full check.
   - Prefer the real command over a weaker proxy.
   - Do not rely on stale output.

4. Read the result carefully.
   - Look at exit status, failures, warnings, and skipped steps.

5. Report only what the evidence supports.
   - If the check passed, say what passed.
   - If it failed, describe the failure plainly.
   - If no meaningful check was run, say verification is still pending.

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
