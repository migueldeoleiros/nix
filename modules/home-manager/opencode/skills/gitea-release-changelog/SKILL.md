---
name: gitea-release-changelog
description: Draft git-flow release PRs and changelogs from conventional commits and Gitea PR context
---

# Gitea Release / Changelog

## Use When

- The user asks for a release PR, changelog, release notes, or version planning.
- The work involves git-flow release branches or conventional commit summaries.

## Workflow

1. Detect release context.
   - Inspect branches before assuming `develop`, `main`, `master`, `release/*`, or `hotfix/*`.
   - Use Gitea MCP for PR metadata and git commands for branch/tag history.
   - If tags/releases are absent, ask for the changelog range or propose one for confirmation.

2. Build the changelog draft.
   - Group conventional commits by type: `feat`, `fix`, `perf`, `refactor`, `docs`, `test`, `build`, `ci`, `chore`, and breaking changes.
   - Prefer user-facing impact over raw commit messages.
   - Link or reference PRs/issues when Gitea metadata is available.

3. Draft the release PR.
   - Confirm base/head branches before creating anything.
   - Include summary, changelog, testing, migration notes, risks, and rollback notes when relevant.
   - Keep tags/releases as draft recommendations unless explicitly requested.

4. Guard mutations.
   - Creating branches, PRs, comments, tags, or releases requires the exact Gitea mutation approval phrase and OpenCode permission approval.
   - Never create tags/releases by default.

## Output

- State branch/range evidence first.
- Provide the changelog and PR body as drafts unless mutation approval is present.
- Call out unknown version, branch, milestone, or release conventions.
