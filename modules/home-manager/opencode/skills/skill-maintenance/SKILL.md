---
name: skill-maintenance
description: Create or audit local SKILL.md files following the repository's compact style.
---

# Skill Maintenance

Use when adding a new skill or auditing/improving an existing local `SKILL.md`.

## Creating a skill

1. Confirm the pattern is reusable and no existing skill covers it.
2. Create `skills/<skill-name>/SKILL.md` under the local skill root.
3. Frontmatter:
   ```yaml
   ---
   name: <skill-name>
   description: <one-line trigger description>
   ---
   ```
4. Keep the body concise: `# Title`, `## Use When` / `## Workflow` / `## Rules`, `## Output`, and optional `## Safety` / `## Red Flags`.
5. Favor positive guidance; add explicit negative safety rules where needed.
6. Keep SKILL.md self-contained by default; add `assets/` or `references/` only when necessary.
7. Do not widen permissions, add external directories, or add extra tooling just to support a skill.
8. Do not add license/author metadata, `Keywords` sections, or tutorial prose.

## Auditing a skill

1. Read the existing `SKILL.md`.
2. Check: valid frontmatter, description is one line and trigger-first, content is actionable and concise, no bloat, safety rules are explicit.
3. Report findings with severity; apply changes only when asked.
4. Preserve author intent, activation semantics, and critical rules.

## Safety

- Do not delete meaningful content silently.
- Do not invent triggers, policies, or domain rules.
