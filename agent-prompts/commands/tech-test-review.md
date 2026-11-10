Use the `tech-test-review` skill. Evaluate the candidate submission against the original test prompt and target role level; support algorithms, Java, frontend/Figma, backend/full-stack, and AI-agent workflow tests. Produce a fair hiring signal, separating evidence from assumptions and marking confidence.

If review depends on a running frontend, screenshots, Figma, or browser behavior, delegate `browser`: layout -> `frontend-visual-verification`; runtime/DOM/console/network -> `browser-devtools-investigation`. If artifacts are unavailable, state the limitation.

Required output:
- recommendation: `strong hire`, `hire`, `lean hire`, `lean no-hire`, `no-hire`, or `insufficient evidence`
- target level and confidence
- scorecard with 3-6 categories
- strongest positive signals and strongest concerns
- role calibration against target level
- follow-up interview questions
- residual risk and missing evidence

Candidate/role context:
@ARGUMENTS@
