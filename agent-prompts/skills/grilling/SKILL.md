---
name: grilling
description: Use when shaping an idea, resolving consequential planning choices, or asked to grill a proposal.
---

# Grilling

Reach shared understanding before committing to a plan. Treat decisions as a tree: upstream answers unlock downstream questions. Depth follows uncertainty, not a question quota.

## Ground

Read relevant code/docs + prior decisions first. Establish outcome, constraints, non-goals, success criteria. Facts -> investigate; consequential choices -> user. Skip settled questions.

## Ask a Round

Ask a small batch of independent questions whose prerequisites are settled. Questions depending on unanswered choices wait for the next round. Use structured questions when available.

Each question -> concrete choice, why it matters, alternatives + trade-offs, recommended answer + assumptions. Recommendations are proposals, not user decisions.

Example:
> Must this work offline? Changes storage + sync complexity.
> Recommend online-only for v1: smaller scope; requires a connection.

Wait for answers before following dependent branches.

## Follow the Tree

Update decisions after each round; prune invalid branches, ask newly unlocked questions. Challenge contradictions + costly assumptions without expanding scope speculatively.

Missing fact -> investigate; continue independent questions while waiting. Answer needs a prototype/check -> propose the smallest useful one, mark the choice blocked on evidence; do not keep rephrasing or guess.

## Close

Stop when consequential choices are settled or explicitly deferred with rationale + revisit trigger. Summarize choices, assumptions, blockers, acceptance criteria; confirm shared understanding. Blocking unknowns -> discovery/draft next step, not implementation-ready claim.

Carry decisions into the plan/spec handoff. Preserve role permissions, independent review, spec-writing ownership, approval gates. Grilling authorizes no execution or extra artifacts.
