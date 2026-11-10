---
name: codegraph-context7
description: Use CodeGraph for indexed codebase questions and Context7 for external library documentation.
---

# CodeGraph & Context7

Use to avoid re-deriving answers with grep or web search when an indexed knowledge tool is available.

## Tool discovery and invocation

- Treat `codegraph_explore` and the Context7 resolve/query operation names as logical operations, not callable identifiers.
- Discover registered tools through the harness's tool catalog; inspect namespace/server instructions and exact schemas before invocation. Invoke only the discovered registered identifier with schema-valid arguments; never guess or construct tool names based on another harness. If unavailable, fall back as described below.
- Tool discovery is not a service query and grants no additional permissions.

## CodeGraph — this codebase

Use for architecture, flows, "how does X work", bug impact, or symbols you are about to change.

- Discover the `codegraph_explore` operation; call it before reading files. One call usually returns relevant source grouped by file plus call paths and blast radius.
- Treat returned source as already read; do not re-read the same files to confirm.
- Pass the target `projectPath` as required by the discovered schema, especially for a sub-project, monorepo service, or second repo; do not assume a default index.
- If exploration is unavailable or the index is missing, fall back to available local tools rather than inventing secondary CodeGraph tools.
- Do not run indexing, initialization, synchronization, mutation, or export actions.

## Context7 — external libraries

Use for library, framework, SDK, API, CLI, or cloud-service documentation.

- Discover the library-ID resolver and documentation-query operations; use their actual identifiers and schemas.
- Resolve first with `libraryName` and `query` to get a compatible library ID (unless user supplied exact ID and schema permits it).
- Then query with `libraryId`, `query`, and optional `language` when supported. Follow discovered query limits.
- Use it even for well-known libraries; training data may be stale.
- Context7 is for public documentation queries only. Never include proprietary code, secrets, or private data.

## When NOT to use

- Do not use CodeGraph for library docs or Context7 for local code.
- Do not delegate a CodeGraph answer to a file-reading subagent when the index already contains the answer.
- Do not run indexing or mutation commands for either service.
