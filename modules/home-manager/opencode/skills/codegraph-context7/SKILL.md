---
name: codegraph-context7
description: Use CodeGraph for indexed codebase questions and Context7 for external library documentation.
---

# CodeGraph & Context7

Use to avoid re-deriving answers with grep or web search when an indexed knowledge tool is available.

## CodeGraph — this codebase

Use for architecture, flows, "how does X work", bug impact, or symbols you are about to change.

- Tool: `codegraph_codegraph_explore`.
- Call it before reading files. One call usually returns relevant source grouped by file plus call paths and blast radius.
- Treat returned source as already `Read`; do not re-read the same files to confirm.
- Pass `projectPath` when querying a sub-project, monorepo service, or second repo.
- If `codegraph_codegraph_explore` is unavailable or the index is missing, fall back to native repo tools (`grep`, `read`, `glob`) rather than inventing secondary CodeGraph tools.
- Do not run `codegraph init`, `codegraph index`, `codegraph sync`, or export actions.

## Context7 — external libraries

Use for library, framework, SDK, API, CLI, or cloud-service documentation.

- Tools: `context7_resolve_library_id`, `context7_query_docs`.
- Call `context7_resolve_library_id` first with `libraryName` and `query` to get a Context7-compatible ID (e.g. `/vercel/next.js`).
- Then call `context7_query_docs` with `libraryId`, `query`, and optional `language`.
- Use it even for well-known libraries; training data may be stale.
- Context7 is for public documentation queries only. Do not include proprietary code, secrets, or private data.

## When NOT to use

- Do not use CodeGraph for library docs or Context7 for local code.
- Do not delegate a CodeGraph answer to a file-reading subagent when the index already contains the answer.
- Do not run indexing or mutation commands for either service.
