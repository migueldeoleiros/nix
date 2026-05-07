---
name: exploration-deep-dive
description: Systematically map unknown code areas and produce evidence-first findings with precise references
---

# Exploration Deep Dive

## Overview

Use this skill when basic discovery is not enough and you need a structured map of unfamiliar code.

Core rule: gather evidence first, infer second.

## When To Use

- unclear ownership boundaries across modules or packages
- feature behavior spans many files or layers
- root-cause exploration needs call-path and dependency mapping
- high uncertainty around where to implement safely

## Exploration Passes

1. Surface map
   - identify entrypoints, top-level modules, and configuration roots

2. Symbol and flow map
   - trace key functions, data paths, and call chains related to the question

3. Constraint map
   - capture invariants, feature flags, permissions, and environment assumptions

4. Risk map
   - identify likely change blast radius and brittle seams

## Output Format

- Facts first with file references (`path:line` when possible).
- Separate sections:
  - confirmed facts
  - inferred behavior (with confidence)
  - unknowns and evidence needed
  - recommended next inspection points
- Keep recommendations scoped and non-prescriptive unless requested.

## Red Flags

- jumping to implementation guidance without mapping call paths
- mixing assumptions into facts without labeling confidence
- reporting isolated snippets without system context
- stopping at one file when behavior clearly crosses boundaries
