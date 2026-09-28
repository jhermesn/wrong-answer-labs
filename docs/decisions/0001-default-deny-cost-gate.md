# 0001. Default-deny cost gate

- Status: Accepted
- Date: 2026-09-27 (commit `a5ab783`)

## Context

Labs are written by a model and deployed in the learner's own account. The
first cost gate was a denylist: any expensive type it did not name passed. In
practice a 16 TB io2 root volume, DAX, MemoryDB and MWAA all got through.
A denylist has to anticipate every expensive type AWS ships; it fails open.

## Decision

- `COST_ALLOWED_RESOURCE_TYPES` is an allowlist. A type passes only after
  someone reviewed how it bills.
- Every size or capacity knob on an allowed type gets a rule, and sizes must be
  literals so a parameter cannot deploy something bigger than what was checked.
- Custom resources are never allowed: their Lambda can create anything outside
  the gate.
- Rules are never relaxed to make a lab pass. A topic that needs a denied type
  becomes a docs-only entry.

## Consequences

- Fails closed: a new AWS service is unusable in labs until reviewed.
- Coverage grows only through PRs that add a type, a size rule and tests
  (CONTRIBUTING.md, [testing.md](../testing.md#adding-a-rule-or-resource-type)).
- Some legitimate topics are docs-only until then. That trades hands-on
  coverage for a bounded bill.
- The agent is told never to edit the rules, so the gate cannot be weakened
  from inside a lab-authoring session without it showing in a diff.
