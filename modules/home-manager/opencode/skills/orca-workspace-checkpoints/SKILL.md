---
name: orca-workspace-checkpoints
description: Use when owning Orca workspace work; update milestone comments and board status.
---

# Orca Workspace Checkpoints

## Use When

- main `assistant`/`build` owns Orca workspace task
- checkpoints: repro, implementation, validation, blocker, handoff, acceptance
- meaningful milestones only; not every tool call/reply

## Workflow

1. Load `orca-cli`; resolve executable + version-matched guide. Orca unavailable -> skip; no startup just for checkpoints.
2. Task's actual cwd -> `ORCA worktree current --json`; retain full id. Read metadata: `ORCA worktree show --worktree id:<full-id> --json`. Never target UI focus.
3. One coordinator/main owner writes card. Delegates -> suggested checkpoints to owner; own workspace only when explicitly assigned. Shared cwd != ownership.
4. Comment: short, factual result/next step/blocker. Replace empty comment or own prior checkpoint only. Preserve human/other-owner text. Ownership unclear -> suggest, do not write.
5. Workspace-wide phase change only; subtask completion != workspace completion:
   - `in-progress`: investigating/implementing/validating
   - `in-review`: evidence ready; awaiting review/acceptance
   - `completed`: workspace task accepted/finished under agreed completion criteria; turn/worker ended != completed
   - blocked: retain phase; explain blocker; unread when human action needed
6. Apply with resolved executable + explicit id:

```text
ORCA worktree set --worktree id:<full-id> --comment "fix implemented; running integration tests" --workspace-status in-progress --json
```

7. New human-action blocker/review handoff -> `--unread`; ordinary progress -> preserve unread. No automatic `--read`. Verify changed fields: `worktree show --json`.

## Rules

- `ORCA` = resolved executable placeholder, not literal command. Linux outside Orca terminals: never invoke GNOME `orca` screen reader.
- metadata only; no Git, linked issue/PR, agent, terminal, orchestration task/dispatch mutations
- no enabling board-to-tracker sync; status change also updates external tracker -> approval first
- preserve custom statuses; default-id reset -> agreement first
- no secrets, private transcript excerpts, unverified success claims
- read-only agents -> suggestions; no permission widening
- optional update failed -> continue; never claim success. User requested Orca state -> report failure.

## Output

- concise task report: result, evidence, remaining blockers
- card metadata supplements report; never replaces it
