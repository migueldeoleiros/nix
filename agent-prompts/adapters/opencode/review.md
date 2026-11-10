---
description: Review changes with findings first, ordered by severity, bound to the exact candidate
agent: reviewer
subtask: true
---

Candidate receipt (evidence is valid only for this worktree revision):
!`opencode-candidate-id`

Current git status:
!`git status --short -uall --ignore-submodules=none`

Changed files:
!`git diff --name-status HEAD --ignore-submodules=none`

Diff:
!`git diff HEAD --no-ext-diff --no-textconv --no-color --ignore-submodules=none`

@BODY@
