---
name: gitea-pr-management
description: Manage Gitea PR metadata, changed files, branch planning, and merge-readiness without code-review scope creep
---

# Gitea PR Management

## Use When

- The user asks about PR metadata, changed files, branch/base/head planning, PR body drafting, or merge-readiness.
- The user does not explicitly ask for a code review.

## Workflow

1. Gather PR facts.
   - Use Gitea MCP for PR list/get, branch names, mergeability, commits, changed files, reviews, comments, title, and body.
   - Use git diff/log locally when the branch is available.
   - Ask if the target PR, base branch, or head branch is ambiguous.

2. Separate PR management from code review.
   - For metadata, descriptions, labels, milestones, branch/range, and merge readiness, continue with this skill.
   - If the user asks to review code, route to `reviewer` with the `pr-review` skill.

3. Draft improvements.
   - Draft PR title/body, summary, testing notes, risk notes, labels, milestone, and reviewer requests.
   - Use conventional commits and git-flow context when relevant.

4. Guard mutations.
   - Creating/editing PRs, comments, review requests, branch updates, labels, or milestones requires the exact Gitea mutation approval phrase and OpenCode permission approval.
   - Merge is out of scope; report readiness only.

## Output

- PR facts first: repo, PR, base/head, mergeability, changed files summary.
- Draft metadata/body changes separately from remote actions.
- State CI evidence limits and use `gitea-ci-investigation` when status/log detail is needed.
