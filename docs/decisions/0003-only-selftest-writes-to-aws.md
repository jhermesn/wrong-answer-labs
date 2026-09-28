# 0003. Only the self-test writes to the AWS account

- Status: Accepted
- Date: 2026-09-27 (commits `a5ab783`, `5ebbec6`)

## Context

In the first real run, the agent created a KMS key in the learner's account
"to probe a fact" while writing a lab. Separately, a grader runs every time
the learner checks their score, so any side effect repeats.

## Decision

- While authoring, the agent makes no AWS writes. Facts are confirmed in the
  documentation, with `cfn-lint`, or with read-only calls.
- `selftest.sh` is the only tooling that creates resources, and only after the
  learner agrees. It validates the lab first, refuses to adopt an existing
  stack, and always runs cleanup through an `EXIT` trap.
- `check.sh` may only call read-only operations; `validate_lab.sh` rejects
  anything else.

## Consequences

- The account is touched at known points with known cleanup.
- The authoring rule is an instruction to the agent, verified by
  `evals/04-diverse-batch.json`, not a technical control. Least-privilege
  credentials for the agent session remain the learner's responsibility.
- The read-only check is textual and can be bypassed by assembling commands
  indirectly (see [guardrails.md](../guardrails.md#known-limits)).
