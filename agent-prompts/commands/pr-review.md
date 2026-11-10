Load `code-review` and `pr-review`; follow shared review rules, coverage, and output format. Review the requested candidate against its base, prioritizing concrete correctness, regression, scalability, reliability, and test-coverage findings with exact file and line references. Do not edit files.

Resolve an omitted base as the first existing branch among `develop`, `main`, `master`, checking local then `origin/` for each. If none exists, fail and report it. Default source to `HEAD`. Re-check the candidate receipt before findings; if base resolution or candidate evidence fails, report that explicitly before writing findings.

Candidate/base:
@ARGUMENTS@
