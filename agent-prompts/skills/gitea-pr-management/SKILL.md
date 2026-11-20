---
name: gitea-pr-management
description: Manage Gitea PR metadata, changed files, branch planning, and merge-readiness without code-review scope creep
---

# Gitea PR Management

## Use When

- The user asks about PR metadata, changed files, branch/base/head planning, PR body drafting, or merge-readiness.
- The user does not explicitly ask for a code review.

## MCP Compatibility

Tool names/methods below describe official gitea-mcp. Inspect the connected catalog first: Pi may still use the legacy Forgejo-compatible server. Use available equivalents (for example `gitea_get_pull_request` / `gitea_list_pr_files`), not absent consolidated tools. If an operation or Actions logs are unavailable, report the limit and use local evidence or an authenticated API when appropriate.

## Workflow

1. Gather PR facts.
   - Use `gitea_list_pull_requests` and `gitea_pull_request_read` (`get`, `get_diff`, `get_files`, `get_commits`, `get_status`, `get_reviews`, `get_review_comments`, `get_comments`, `get_by_branches`) for branch names, mergeability, commits, changed files, reviews, comments, title, and body.
   - Use git diff/log locally when the branch is available.
   - Ask if the target PR, base branch, or head branch is ambiguous.

2. Separate PR management from code review.
   - For metadata, descriptions, labels, milestones, branch/range, and merge readiness, continue with this skill.
   - If the user asks to review code, route to `reviewer` with the `pr-review` skill.

3. Draft improvements.
   - Draft PR title/body, summary, testing notes, risk notes, labels, milestone, and reviewer requests.
   - Use conventional commits and git-flow context when relevant.

4. Scope mutations.
   - Create/edit/close/reopen PRs, update branches, and manage reviewers via `gitea_pull_request_write`; reviews/review comments via `gitea_pull_request_review_write`; labels/milestones via `gitea_issue_write`/`gitea_label_write`/`gitea_milestone_write`. Do so when the user explicitly requests it; full tool access does not authorize unrequested changes.
   - Merge only when the user explicitly requests it; confirm PR, merge method, and target branch first. Otherwise report readiness only.

## Output

- PR facts first: repo, PR, base/head, mergeability, changed files summary.
- Draft metadata/body changes separately from remote actions.
- State CI evidence limits and use `gitea-ci-investigation` when status/log detail is needed.
