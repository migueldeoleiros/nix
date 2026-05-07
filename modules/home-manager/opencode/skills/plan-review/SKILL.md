---
name: plan-review
description: Review requirements and execution plans for sequencing flaws, hidden assumptions, and verification gaps
---

# Plan Review

## Overview

Use this skill to pressure-test a plan before implementation begins.

Independence rule: the reviewer using this skill should not be the same agent that authored the plan.

Core rule: findings first, ordered by severity.

## Review Priorities

1. Requirement fidelity
   - does the plan match explicit user intent and constraints
   - are acceptance criteria clear and testable

2. Sequencing and dependency safety
   - invalid ordering, missing prerequisites, unsafe parallelization
   - unclear merge points or integration boundaries

3. Assumptions and ambiguity
   - hidden assumptions that can change architecture or UX
   - unresolved decisions disguised as implementation steps

4. Verification and rollback
   - missing verification strategy for risky steps
   - no rollback path for high-impact changes

5. Scope control
   - scope creep, contradictory steps, or plan bloat

## Process

1. Restate intended outcome and constraints.
2. Scan the plan for dependency edges and ordering risks.
3. Mark assumptions that require explicit decisions.
4. Check each major phase has validation criteria.
5. Report findings with severity and fix direction.

## Output Format

- Findings first: `high` -> `medium` -> `low`.
- Each finding includes:
  - short title
  - severity
  - evidence (plan step or requirement reference)
  - impact if unchanged
  - suggested fix direction (brief)
- After findings, include:
  - open questions and assumptions
  - revised step ordering (if needed)
- If no findings, state that clearly and list residual assumptions.

## Red Flags

- approving plans with unresolved assumptions in early phases
- parallelizing tasks that share hidden state or interfaces
- lacking explicit verification for risky migrations or refactors
- mixing optional nice-to-haves with critical path steps
