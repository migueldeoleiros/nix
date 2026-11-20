---
name: gitea-issue-triage
description: Draft and triage Gitea issues with labels, milestones, acceptance criteria, and explicit-request writes
---

# Gitea Issue Triage

## Use When

- The user wants to create, refine, split, label, comment on, or prioritize issues.
- Existing issues need duplicate checks, reproduction notes, acceptance criteria, or milestone planning.

## MCP Compatibility

Tool names/methods below describe official gitea-mcp. Inspect the connected catalog first: Pi may still use the legacy Forgejo-compatible server. Use available equivalents (for example `gitea_get_pull_request` / `gitea_list_pr_files`), not absent consolidated tools. If an operation or Actions logs are unavailable, report the limit and use local evidence or an authenticated API when appropriate.

## Workflow

1. Understand the request.
   - Identify target instance, owner/repo, problem, desired outcome, priority, labels, and milestone.
   - Ask when target repo or scope is ambiguous.

2. Gather context.
   - Use `gitea_search_issues`, `gitea_list_issues`, `gitea_issue_read`, `gitea_label_read`, `gitea_milestone_read`, and `gitea_pull_request_read`/`gitea_list_pull_requests` for related PRs.
   - Use local repo evidence when issue details depend on code behavior.

3. Draft first.
   - Issue title should be specific and action-oriented.
   - Body should fit the issue type: bugs need expected/actual/repro evidence; planning work needs context, scope, acceptance criteria, and risks.
   - Suggest labels/milestone, but apply them only when the user asked for it.

4. Scope mutations.
   - Write via `gitea_issue_write`, `gitea_label_write`, `gitea_milestone_write` when the user explicitly requests it; full tool access does not authorize unrequested changes.
   - Show the payload for non-trivial writes; confirm before destructive actions (deleting issues/comments/labels/milestones).

## Output

- Provide issue/comment drafts separately from actions taken.
- List suggested labels and milestone with rationale.
- State duplicate/related issue evidence when found.
