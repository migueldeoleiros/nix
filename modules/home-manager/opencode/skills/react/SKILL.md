---
name: react
description: React TypeScript robustness checklist; use when writing or reviewing React TS/TSX frontend code
---

# React TypeScript

Use for React TS/TSX code. Goal: boring code. Few bugs. Easy review. CI quiet.

## Do

- Follow nearby project style first.
- Keep change small.
- Type inputs, outputs, props, events, API data.
- Avoid `any`, blind casts, and lazy `!`.
- Remove dead code, unused props/imports/types, stale TODOs.
- Keep components focused.
- Avoid duplicate JSX and magic literals.
- Avoid hard-to-read ternaries; use `if`/early return when clearer.
- Prefer discriminated unions, narrowing helpers, and guards over nested `if`/type-check ladders.
- Avoid empty branches and nested conditionals when a guard/extract component reads better.
- Model loading, empty, error, success, disabled states.
- Handle promise failures. Do not ignore async results.
- Avoid stale async updates and state-after-unmount.
- Follow hook rules. Keep dependency arrays honest.
- Do not mutate props/state.
- Use stable keys; avoid index keys for changing lists.
- Prefer semantic HTML before ARIA.
- Keep keyboard, focus, labels, errors, alt text working.
- Never hardcode or log secrets/tokens/private data.
- Avoid unsafe HTML, eval, unsafe redirects, untrusted URLs.
- Add focused tests for changed user-visible behavior.
- Keep tests deterministic: inject/fake time, no system clock, sleeps, random, or flaky order assumptions.

## Before Done

- Could it crash?
- Could async race?
- Could data leak?
- Can keyboard user do it?
- Are states handled?
- Is behavior tested?

Report only real issues: `blocking`, `should fix`, `optional`.
