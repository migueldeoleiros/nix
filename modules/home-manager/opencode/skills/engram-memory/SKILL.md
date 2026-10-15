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

## Role boundaries

- Read-only roles: use only permitted `engram_mem_current_project`, `engram_mem_context`, `engram_mem_search`, `engram_mem_get_observation`, `engram_mem_suggest_topic_key`. No saves, sessions, diagnostics, or other memory tools; availability does not grant permission.
- Writable `assistant`/`build`/`worker`: save selectively using the workflow below and actual tool permissions.
- Browser retains full tool permissions; behaviorally report durable findings to the parent for memory handling. This is not a blanket permission denial.

## When to save (writable roles)

- Bug fix, architecture decision, team convention, tool/library choice with tradeoffs.
- Non-obvious discovery, gotcha, or edge case.
- User preference, rejection, or confirmed direction.
- Save durable findings, not tool transcripts, redundant per-turn notes, or every tiny action.

Use `engram_mem_save` with:
- `capture_prompt: false` explicitly; never capture the raw prompt implicitly.
- `title`: verb + what, short and searchable.
- `type`: `bugfix`, `decision`, `architecture`, `pattern`, `config`, `discovery`, `preference`, `learning`.
- `scope`: `project` (default), `personal`, or `global`.
- `topic_key`: reuse a stable key to upsert evolving topics instead of duplicating records; use `engram_mem_suggest_topic_key` if unsure and permitted.
- `content` structured as:
  - **What**: one sentence.
  - **Why**: motivation.
  - **Where**: files or paths affected.
  - **Learned**: gotchas or edge cases (omit if none).

Do not save raw prompts, secrets, credentials, private paths, or proprietary code.

## Judgment and lifecycle (writable roles)

- If save returns `judgment_required`, handle each `candidates[]` entry with `engram_mem_judge` using that candidate's `judgment_id`, never the top-level ID.
- Ask the user before judging if confidence < 0.7, or if `supersedes`/`conflicts_with` concerns a decision, architecture, or policy; otherwise resolve silently from evidence.
- No plugin automatically creates a memory session per chat. Never invent session IDs or assume a chat ID is registered.
- Use only an authoritative runtime or successfully registered session ID. Without one, omit the ID and let Engram select its fallback; report ambiguity rather than guessing. `engram_mem_session_start` registers a caller-provided ID; it does not generate one.
- At meaningful completion/handoff, use `engram_mem_session_summary` for durable context, not after every small action; end only a known session when appropriate.

Do not use `engram_mem_save_prompt` or passive capture to store raw prompts.

## Project rules

- Call `engram_mem_current_project` before writing. Failed/ambiguous resolution is not empty history: stop and ask; never guess another project or global scope. If a returned project mismatches the expected project, stop and report.
- Successfully resolved project + no stored memories or empty context/search is normal first use; writable roles may make the first save.
- After successful detection, omitting the `project` argument is valid auto-resolution. A blank `project_path` in an explicit-project response alone does not mean projectless.
- `all_projects=true` is intentional global read only; do not use it for routine saves.
- Saves without a clear project context are blocked; report the blocker and skip the memory write rather than inventing scope.

## Safety

- Project and scope filters organize memory; they are not security boundaries.
- Memories are advisory. Validate stale records against current code and config.
- Do not save raw prompts, secrets, credentials, private paths, or proprietary code unless explicitly requested.
- Do not run cloud, export, import, sync, or project-merge actions unless explicitly requested.
- No automatic model calls through Engram; use it only for memory read/write.
