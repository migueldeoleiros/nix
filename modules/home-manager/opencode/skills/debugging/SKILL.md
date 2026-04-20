---
name: Debugging
description: Investigate problems systematically by finding root cause before fixing symptoms
---

# Debugging

## Overview

Move from symptoms to root cause before suggesting a fix.

Core rule: do not guess, stack random fixes, or call something solved without evidence.

## Workflow

1. Define the failure clearly.
   - What is happening?
   - What did the user expect instead?
   - What exact error, output, or behavior shows the failure?

2. Reproduce and bound the problem.
   - Find the smallest reliable reproduction.
   - Note whether it always happens, only sometimes happens, or depends on a specific environment.

3. Gather evidence before fixing.
   - Read the full error message and stack trace.
   - Check recent edits, config changes, dependency changes, and environment differences.
   - Trace the data flow or call path until you can explain where things first go wrong.

4. Compare with a working path.
   - Find a similar implementation, neighboring code path, or documented reference that works.
   - List the meaningful differences between working and broken behavior.

5. Form one hypothesis.
   - State the likely root cause explicitly.
   - Test only that hypothesis with the smallest useful change or observation.

6. Fix only after the cause is understood.
   - Prefer the smallest change that addresses the cause.
   - Avoid drive-by refactors while fixing a bug.

7. Re-verify the original symptom.
   - Confirm the failing case now works.
   - Check nearby regressions if the affected area is broad.

 ## Frontend Debugging

For visual/layout bugs (overflow, clipping, responsive issues) in browser-based projects, use the `frontend-visual-verification` skill instead of this general debugging workflow. It provides DevTools-based inspection, reproduction, and fix verification tailored for CSS/DOM issues.

## Red Flags

 - guessing from memory instead of reading the code or output
 - proposing multiple fixes at once
 - saying something should work without running the proving check
 - fixing the final crash site without tracing where the bad state came from

## Output Style

- start with the observed problem and strongest evidence
- separate facts, hypotheses, and next checks
- if blocked, ask for the smallest missing piece of information
