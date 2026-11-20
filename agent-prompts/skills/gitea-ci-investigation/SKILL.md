---
name: gitea-ci-investigation
description: Investigate Gitea PR CI status using Actions run/job logs, commit statuses, and local reproduction
---

# Gitea CI Investigation

## Use When

- PR status, checks, or Actions output is unclear.
- Failing job logs or check output are needed.
- The user asks why CI failed or whether a PR is merge-ready.

## MCP Compatibility

Tool names/methods below describe official gitea-mcp. Inspect the connected catalog first: Pi may still use the legacy Forgejo-compatible server. Use available equivalents (for example `gitea_get_pull_request` / `gitea_list_pr_files`), not absent consolidated tools. If an operation or Actions logs are unavailable, report the limit and use local evidence or an authenticated API when appropriate.

## Workflow

1. Gather remote evidence first.
   - Use `gitea_pull_request_read` (`get`, `get_files`, `get_commits`, `get_status`, `get_reviews`, `get_comments`) for PR metadata, mergeability, changed files, commits, reviews, and comments.
   - Use `gitea_actions_run_read` (`list_runs`, `get_run`, `list_run_jobs`, `get_job_log_preview`, `download_job_log`) for runs, jobs, and logs; `gitea_commit_read` (`get_status`) for commit statuses.
   - Use user-provided CI snippets if available.
   - Do not treat missing runner/job or commit-status detail as pass/fail evidence.
   - Rerun/cancel/dispatch via `gitea_actions_run_write` only when the user asks.

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
- State what came from Actions logs/statuses vs. other sources.
- If CI logs are unavailable, say so and provide the best local evidence.
- Do not invent job names, failure output, or check status.
- If blocked by missing secrets, unavailable containers, or environment mismatch, report the blocker and next best check.

## Output

- CI evidence: remote status, local reproduction, and assumptions as separate bullets.
- If failing, include the smallest failing command/job and likely cause.
- If inconclusive, give concrete next evidence needed.
