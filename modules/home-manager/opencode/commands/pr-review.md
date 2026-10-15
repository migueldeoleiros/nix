---
description: Review PR with findings-first output and scalability focus, bound to the exact candidate
agent: reviewer
subtask: true
---

Load `code-review` + `pr-review`; follow shared RDD rules and PR coverage/output format.

Scope:
- `$1` = base; empty -> first existing `develop`, `main`, `master` (local then `origin/` per branch); none -> fail
- `$2` = source; empty -> `HEAD`

Candidate context (initial receipt + snapshots; re-check receipt before findings):
!`sh -ec 'BASE="$1"; if [ -z "$BASE" ]; then for b in develop main master; do if git show-ref --verify --quiet "refs/heads/$b"; then BASE="$b"; break; fi; if git show-ref --verify --quiet "refs/remotes/origin/$b"; then BASE="origin/$b"; break; fi; done; fi; [ -n "$BASE" ] || { echo "error: no base branch found (checked: develop, main, master)" >&2; exit 1; }; SOURCE="${2:-HEAD}"; printf "base=%s\nsource=%s\n\n" "$BASE" "$SOURCE"; opencode-candidate-id --base "$BASE" --head "$SOURCE"; printf "\n--- status ---\n"; git status --short -uall --ignore-submodules=none; printf "\n--- changed files ---\n"; git diff --name-status "$BASE...$SOURCE" --ignore-submodules=none; printf "\n--- commits ---\n"; git log --oneline "$BASE..$SOURCE"; printf "\n--- diff ---\n"; git diff "$BASE...$SOURCE" --no-ext-diff --no-textconv --no-color --ignore-submodules=none' _ "$1" "$2"`

If base resolution fails, report it explicitly before writing findings.

Usage examples:
- `/pr-review` (review current branch against develop/main/master)
- `/pr-review develop` (review current branch against develop)
- `/pr-review origin/develop feature/manual-editing` (review feature/manual-editing against origin/develop)

User request:

$ARGUMENTS
