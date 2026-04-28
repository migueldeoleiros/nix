---
name: SonarQube Review
description: Incorporate SonarQube MCP findings into code and PR reviews without replacing human risk analysis
---

# SonarQube Review

Use SonarQube as a targeted static-analysis aid during reviews, not as the review itself.

Prefer narrow checks:
- snippet or changed-hunk analysis
- file-level issues, hotspots, coverage, or duplication
- PR/quality-gate data only when exact project and PR context is provided

Rules:
- validate SonarQube findings against the code before reporting them
- include SonarQube only as supporting evidence for relevant findings
- skip stale, unrelated, or false-positive issues
- continue the review if SonarQube is unavailable or lacks context
- never try to run a full scan; scans belong to CI/PR workflows outside the agent's permissions

Avoid guessing project keys, PR IDs, or branch context. Do not dump raw SonarQube output.
