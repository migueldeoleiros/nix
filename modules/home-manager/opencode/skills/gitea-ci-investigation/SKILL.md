---
name: gitea-ci-investigation
description: Investigate Gitea PR CI status when MCP lacks job logs or check output
---

# Gitea CI Investigation

## Use When

- PR status, checks, or Actions output is unclear.
- Gitea MCP has PR metadata but not failing job logs.
- The user asks why CI failed or whether a PR is merge-ready.

## Workflow

1. Gather remote evidence first.
   - Use Gitea MCP for PR metadata, branches, mergeability, changed files, reviews, commits, and comments.
   - Use authenticated API or user-provided CI snippets if available.
   - Do not treat missing runner/job or commit-status detail as pass/fail evidence.

2. Inspect local workflow inputs.
   - Read workflow files, build scripts, package manifests, lockfiles, Docker/compose config, and changed files.
   - Identify which jobs should run for the PR branch and event.

3. Reproduce locally when useful.
   - Use `act --list` to enumerate workflows/jobs.
   - Use `act <event> -j <job>` for targeted job reproduction.
   - Prefer project-provided containers, env files, and secrets only when the user approves secret use.
   - Use Docker read/inspect/log commands to understand local runner failures.

4. Run project checks as needed.
   - Use the narrowest useful command: pnpm/npm/yarn/bun test-build-lint-typecheck, Maven/Gradle compile-test-verify-package/build/check, make test/build/check, pytest, cargo, or go checks.
   - Separate local reproduction failures from remote CI failures.

## Evidence Rules

- State what came from Gitea MCP, local commands, `act`, or user-provided logs.
- If CI logs are unavailable, say so and provide the best local evidence.
- Do not invent job names, failure output, or check status.
- If blocked by missing secrets, unavailable containers, or environment mismatch, report the blocker and next best check.

## Output

- CI evidence: remote status, local reproduction, and assumptions as separate bullets.
- If failing, include the smallest failing command/job and likely cause.
- If inconclusive, give concrete next evidence needed.
