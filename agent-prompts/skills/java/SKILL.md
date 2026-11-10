---
name: java
description: Java backend robustness checklist; use when writing or reviewing Java and Spring code
---

# Java

Use for Java/Spring code. Goal: boring code. Few bugs. Easy review. CI quiet.

## Do

- Follow nearby project style first.
- Keep change small.
- Name things clear.
- Cut dead code, unused imports, commented-out code, stale TODOs.
- Keep methods short enough to read.
- Avoid duplicate logic and magic literals.
- Prefer guard clauses over deep nesting.
- Avoid hard-to-read ternaries; use `if`/`else` when clearer.
- Prefer pattern matching/guards over nested type checks when supported; keep modern Java syntax compatible with project target.
- Avoid empty branches and nested conditionals when a guard/extract method reads better.
- Validate input at API boundaries.
- Avoid null surprises; return empty collections, not null.
- Use `Optional` safely; no blind `.get()`.
- Catch narrow exceptions. Never swallow errors.
- Preserve cause when wrapping exceptions.
- Use try-with-resources for closeable resources.
- Use constructor injection in Spring.
- Keep controllers thin; put logic in services.
- Add pagination/limits for lists.
- Use transactions for atomic writes.
- Parameterize queries. Never concat user input into SQL.
- Never hardcode or log secrets/tokens/private data.
- Add focused tests for changed behavior and edge cases.
- Keep tests deterministic: inject/fake time, no system clock, sleeps, random, or flaky order assumptions.

## Before Done

- Could it crash?
- Could it leak data?
- Could auth be bypassed?
- Is it too complex?
- Is failure handled?
- Is behavior tested?

Report only real issues: `blocking`, `should fix`, `optional`.
