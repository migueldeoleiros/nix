---
name: gitea-release-changelog
description: Run standard release PRs and changelogs from project versions, conventional commits, and Gitea PR context
---

# Gitea Release / Changelog

## Use When

- The user asks for a release, release PR, changelog, release notes, or version planning.
- The work involves project versions, git-flow branches, or conventional commit summaries.

## MCP Compatibility

Tool names/methods below describe official gitea-mcp. Inspect the connected catalog first: Pi may still use the legacy Forgejo-compatible server. Use available equivalents (for example `gitea_get_pull_request` / `gitea_list_pr_files`), not absent consolidated tools. If an operation or Actions logs are unavailable, report the limit and use local evidence or an authenticated API when appropriate.

## Workflow

1. Detect release context.
   - Inspect current branch and branch layout before assuming `develop`, `main`, `master`, `release/*`, or `hotfix/*`.
   - For standard releases, confirm expected `develop` and `main`, check worktree status, inspect previous release PR titles/commit messages, detect the project version source and current version, and detect the last release merge from `main`.
   - Use `gitea_pull_request_read`, `gitea_list_pull_requests`, `gitea_tag_read`, `gitea_release_read`, and `gitea_commit_read` (`compare`) for PR/release metadata and git commands for branch/tag/history evidence.
   - For standard releases, use `origin/main..origin/develop` after the version bump as the changelog range.
   - If the release is not the standard flow and tags/releases are absent, ask for the changelog range or propose one for confirmation.

2. Prepare the standard version bump when requested.
   - Treat an explicit release request as approval for standard release operations only: update the project version in the repository's version source, commit `chore: bump up version to <version>`, push `develop`, create the release PR from `develop` to `main`, and fill the PR body with release notes.
   - For a minor release, bump `x.y.z` to `x.(y+1).0`.
   - Update only the project version field/file; leave unrelated files and unrelated untracked files untouched.
   - Run the repository's normal package/build verification command after the version bump.
   - Push `develop` to `origin`; if remote advanced, stop and ask whether to rebase or merge, recommending rebase onto latest `origin/develop`.

3. Build the changelog.
   - Always include a changelog in release PRs, even when previous release PRs did not.
   - Group entries by Features, Fixes, Refactors, and CI / Chores.
   - Prefer user-facing impact over raw commit messages.
   - Link or reference obvious PRs/issues when Gitea metadata or commit history provides them.
   - Include migration notes and risk callouts when release-relevant files changed.

4. Create the release PR.
   - Default standard release PR: base `main`, head `develop`, title `release: v<version>`.
   - Include these body sections: Summary, Changelog, Testing, Migration notes, Risk / Rollback.
   - Create via `gitea_pull_request_write`. Keep tags/releases as draft recommendations unless explicitly requested.

5. Check mergeability and scope risky mutations.
   - Check PR mergeability after creation; if mergeable, report PR URL and status.
   - If not mergeable, investigate and explain conflicting files, likely cause, and recommended resolution.
   - Ask before resolving conflicts or merging/rebasing `main` into `develop`.
   - After approved conflict resolution, merge `origin/main` into `develop`, preserve intended develop release changes unless told otherwise, run the repository's normal package/build verification command, commit `chore: merge main into develop for release`, push `origin/develop`, and re-check PR mergeability.
   - Non-standard mutations (branches, comments, tags via `gitea_tag_write`, releases via `gitea_release_write`, PR merge via `gitea_pull_request_write`) are allowed when the user explicitly requests that operation; full tool access does not authorize unrequested changes.
   - Do not create tags/releases/merge by default.
   - Confirm exact target and effect before destructive actions (force-push, reset, deleting branches/tags/releases, merging PRs); do not change deployment/runtime behavior outside approved conflict resolution.

## Output

- State branch/range/version evidence first.
- Separate standard release actions taken from drafts and recommendations.
- Report local verification command results.
- Call out unknown version, branch, milestone, mergeability, or release conventions.
