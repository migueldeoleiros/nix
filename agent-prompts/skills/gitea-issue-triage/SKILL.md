---
name: gitea-issue-triage
description: Draft and triage Gitea issues with labels, milestones, acceptance criteria, and ask-gated writes
---

# Gitea Issue Triage

## Use When

- The user wants to create, refine, split, label, comment on, or prioritize issues.
- Existing issues need duplicate checks, reproduction notes, acceptance criteria, or milestone planning.

## Workflow

1. Understand the request.
   - Identify target instance, owner/repo, problem, desired outcome, priority, labels, and milestone.
   - Ask when target repo or scope is ambiguous.

2. Gather context.
   - Use Gitea MCP to search/list/get issues, labels, milestones, comments, and related PRs.
   - Use local repo evidence when issue details depend on code behavior.

3. Draft first.
   - Issue title should be specific and action-oriented.
   - Body should fit the issue type: bugs need expected/actual/repro evidence; planning work needs context, scope, acceptance criteria, and risks.
   - Suggest labels/milestone, but do not apply them without approval.

4. Guard mutations.
   - Creating/editing issues, comments, labels, or milestones requires the exact Gitea mutation approval phrase and OpenCode permission approval.
   - Show exact payload before any write.

## Output

- Provide issue/comment drafts separately from actions taken.
- List suggested labels and milestone with rationale.
- State duplicate/related issue evidence when found.
