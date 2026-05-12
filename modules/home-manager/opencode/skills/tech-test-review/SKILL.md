---
name: tech-test-review
description: Review candidate technical tests across algorithms, frontend builds, and AI-agent exercises with role-calibrated assessment
---

# Technical Test Review

## Overview

Review a candidate submission as an evaluator, not as a normal code reviewer.
Judge whether the work demonstrates the expected signal for the target role and
test format.

Core rule: assess job-relevant signal first, then implementation details.

## Inputs To Establish

Before scoring, identify or ask for:

1. Target role level
   - junior, mid, senior, staff/lead, or unknown

2. Test format
   - algorithm exercise, backend/API task, frontend/Figma implementation,
     full-stack feature, AI-agent workflow, or mixed

3. Review artifacts
   - prompt, candidate code, README/notes, commits, screenshots, Figma link,
     running app, tests, AI transcript, or evaluation rubric

4. Constraints
   - time limit, allowed libraries, AI usage policy, browser/device targets,
     expected completeness, and explicit must-haves

If any input is missing, continue with clear assumptions and mark confidence.

## Level Calibration

### Junior

Look for fundamentals and coachability:
- readable, mostly correct solution for the main path
- basic decomposition and naming
- simple edge-case awareness
- ability to explain tradeoffs and failures honestly
- limited polish is acceptable if the core is sound

### Mid-Level

Look for independent delivery:
- correct behavior across common edge cases
- appropriate data structures, component boundaries, and error handling
- meaningful tests or manual verification
- pragmatic decisions without over-engineering
- maintainable code another developer can extend

### Senior

Look for system judgment:
- robust handling of edge cases, failure states, and ambiguity
- clean architecture, explicit tradeoffs, and scalable boundaries
- strong testing strategy and confidence-building verification
- product and UX awareness, not just code completion
- ability to reduce scope safely and document remaining risk

### Staff/Lead

Look for leverage and decision quality:
- clear problem framing and prioritization under constraints
- architecture that supports future change and team ownership
- operational, security, performance, and accessibility awareness
- high-quality communication and rationale
- evidence of mentoring-level clarity in docs or review notes

## Format-Specific Rubrics

### Algorithm / Java Exercises

Assess:
- correctness for normal, boundary, invalid, empty, duplicate, and large inputs
- time and space complexity, including whether it matches the expected level
- simplicity and readability over cleverness
- Java idioms: collections, generics, null handling, immutability where useful
- tests or examples covering edge cases

Red flags:
- hardcoded answers or prompt-specific shortcuts
- unbounded recursion/loops without reason
- quadratic behavior where a linear or log-linear approach is expected
- hidden mutation that makes repeated calls fail
- no explanation of complexity for mid/senior candidates

### Frontend / Figma Implementation

Assess:
- visual fidelity: layout, spacing, typography, colors, states, and responsive behavior
- semantic HTML, accessibility, keyboard flow, focus states, and reduced-motion concerns
- component structure, state management, and data-flow simplicity
- loading, empty, error, and long-content states
- browser correctness on desktop and mobile
- whether deviations from Figma are intentional and documented

Red flags:
- pixel matching only at one viewport
- inaccessible custom controls
- brittle absolute positioning for normal layout
- no attention to overflow, truncation, or dynamic data
- senior candidates ignoring design-system or product tradeoffs

### Backend / API / Full-Stack Tasks

Assess:
- API contract clarity, validation, and error behavior
- persistence correctness, migrations, transactions, and concurrency assumptions
- auth/authz, secret handling, and data exposure risk
- test coverage at useful seams
- operational basics: logs, config, timeouts, retries, idempotency where relevant

Red flags:
- trusting client input blindly
- silent failure or swallowed errors
- no pagination/limits for collection endpoints
- race-prone writes or non-idempotent retry paths
- unclear setup instructions

### AI-Agent Workflow Tests

Assess the candidate's ability to drive AI systems, not just the final code:
- problem decomposition and delegation strategy
- prompt clarity, context management, and use of specs/plans
- verification discipline: tests, screenshots, logs, diff review, and manual checks
- ability to catch AI mistakes, hallucinations, and over-broad changes
- iteration quality: small steps, clear acceptance criteria, and rollback awareness
- final synthesis: what changed, why, evidence, risks, and follow-ups

Red flags:
- blindly accepting AI output without inspection
- no reproducible verification evidence
- broad rewrites unrelated to the task
- leaking secrets or uploading sensitive material to tools
- confusing tool success with product correctness

## Scoring Framework

Use a 1-5 score per category when a rubric is not provided:

1. Correctness / completeness
2. Code quality / maintainability
3. Testing / verification
4. Role-level judgment
5. Communication / documentation

Optional format-specific category:
- frontend: UX/accessibility/visual fidelity
- backend: reliability/security/data integrity
- AI-agent: orchestration and validation discipline
- algorithms: complexity and edge-case handling

Score meanings:
- 1: below bar; core expectations missing
- 2: weak; partial solution with important gaps
- 3: acceptable; meets core bar with manageable gaps
- 4: strong; exceeds expected level in meaningful areas
- 5: exceptional; rare signal for the target level

## Review Process

1. Restate the target role, test format, and assumptions.
2. Inspect the submission against the original prompt, not just generic best practices.
3. Separate blocking issues from level-dependent polish.
4. Look for positive hiring signal and negative risk signal.
5. Calibrate findings to the role level; do not punish juniors for senior-only concerns.
6. Identify what evidence is missing before making strong claims.
7. Give a hire/no-hire recommendation only when enough evidence exists.

## Output Format

Use this structure:

1. Recommendation
   - `strong hire`, `hire`, `lean hire`, `lean no-hire`, `no-hire`, or
     `insufficient evidence`
   - include target level and confidence: `high`, `medium`, or `low`

2. Scorecard
   - 3-6 categories with score, short rationale, and level calibration

3. Key evidence
   - strongest positive signals
   - strongest concerns, ordered by hiring impact
   - file/line references, screenshots, commands, or transcript snippets when available

4. Role calibration
   - whether the submission meets, exceeds, or falls short of the target level

5. Follow-up interview questions
   - 3-6 targeted questions to validate unclear areas

6. Residual risk
   - what was not verified and how that affects confidence

## Tone

- be fair, concrete, and role-calibrated
- avoid personal judgments; evaluate observable work
- distinguish evidence from assumptions
- do not rewrite the candidate's solution unless explicitly asked
- do not inflate minor style issues into hiring blockers
- call out excellent signal clearly when present
