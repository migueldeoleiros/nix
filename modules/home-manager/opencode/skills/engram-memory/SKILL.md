---
name: engram-memory
description: Use Engram persistent memory for project-scoped recall and durable saves, respecting role permissions.
---

# Engram Memory

Use when the user refers to past work, when a decision, pattern, bug fix, or preference should survive this session, or when starting/resuming work.

## When to recall

- User asks anything like "remember", "recall", "what did we do", "how did we solve", or mentions past work on a topic.
- Starting related work where prior context would shorten rediscovery.

Recall path:
1. `engram_mem_current_project` — confirm the resolved project and source.
2. `engram_mem_context` — recent session history.
3. `engram_mem_search` — keyword search if context is insufficient.
4. `engram_mem_get_observation` — full content of a match.

Treat all memory as advisory; validate stale records against current source.

## When to save

- Bug fix, architecture decision, team convention, tool/library choice with tradeoffs.
- Non-obvious discovery, gotcha, or edge case.
- User preference, rejection, or confirmed direction.
- End of a meaningful task.

Use `engram_mem_save` with:
- `title`: verb + what, short and searchable.
- `type`: `bugfix`, `decision`, `architecture`, `pattern`, `config`, `discovery`, `preference`, `learning`.
- `scope`: `project` (default), `personal`, or `global`.
- `topic_key`: stable key for evolving topics; use `engram_mem_suggest_topic_key` if unsure.
- `content` structured as:
  - **What**: one sentence.
  - **Why**: motivation.
  - **Where**: files or paths affected.
  - **Learned**: gotchas or edge cases (omit if none).

Do not save raw prompts, secrets, credentials, private paths, or proprietary code.

## Available tools

OpenCode exposes Engram tools with the `engram_` prefix. The default agent profile (`--tools=agent`) includes:

Core recall: `engram_mem_context`, `engram_mem_search`, `engram_mem_get_observation`, `engram_mem_suggest_topic_key`, `engram_mem_current_project`, `engram_mem_list_projects`.

Core save/update: `engram_mem_save`, `engram_mem_update`, `engram_mem_judge`.

Session/lifecycle: `engram_mem_session_start`, `engram_mem_session_end`, `engram_mem_session_summary`.

Other: `engram_mem_capture_passive`, `engram_mem_compare`, `engram_mem_doctor`, `engram_mem_pin`, `engram_mem_unpin`, `engram_mem_review`.

Avoid `engram_mem_save_prompt`; do not feed raw prompts to memory.

## Project rules

- Call `engram_mem_current_project` before writing. If project resolution is ambiguous, ask the user; do not guess or search all projects.
- `all_projects=true` is intentional global read only; do not use it for routine saves.
- Saves without a clear project context are blocked; report the blocker and skip the memory write rather than inventing scope.

## Safety

- Project and scope filters organize memory; they are not security boundaries.
- Memories are advisory. Validate stale records against current code and config.
- Do not save raw prompts, secrets, credentials, private paths, or proprietary code unless explicitly requested.
- Do not run cloud, export, import, sync, or project-merge actions unless explicitly requested.
- No automatic model calls through Engram; use it only for memory read/write.
