# 0002. Lab structure validated through HTML comment anchors

- Status: Accepted
- Date: 2026-09-23 (commit `1d042d8`)

## Context

Lab prose follows the learner's language, so headings change from one lab to
the next ("Scenario", "Cenário", ...). The validator still has to prove that
every section exists and that challenges, checks, solutions and source
questions line up.

## Decision

Structure is marked with fixed HTML comments that do not render and are never
translated:

- `<!-- section:<name> -->` for required sections;
- `<!-- challenge:N -->`, `<!-- solution:N -->` for challenges 1..N (N ≤ 5);
- `<!-- question:QN -->` for each source question.

`validate_lab.sh` counts and cross-checks these, and `check.sh` lines are
matched by their leading `check N`.

## Consequences

- Labs in any language pass the same gate.
- Anchors are a contract: they cannot be renamed without updating the assets,
  `validate_lab.sh`, `lab-format.md`, the examples and `tests/run.sh` together.
- Headings are unchecked; a lab can be structurally valid with poor headings.
