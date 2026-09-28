# Documentation

Technical documentation for maintainers and contributors of Wrong Answer Labs.
For installing and using the plugin as a learner, start with the
[project README](../README.md); for how to contribute, see
[CONTRIBUTING.md](../CONTRIBUTING.md).

| Document | What it covers |
|---|---|
| [architecture.md](architecture.md) | Components, how they fit together, trust boundaries |
| [lab-lifecycle.md](lab-lifecycle.md) | Authoring flow (agent), learner flow, what each lab file does |
| [guardrails.md](guardrails.md) | The static gate, every cost and security rule, suppressions, known limits |
| [scripts.md](scripts.md) | Reference for every script: arguments, requirements, exit codes |
| [testing.md](testing.md) | `tests/run.sh`, rule unit tests, evals, running locally |
| [ci-cd.md](ci-cd.md) | CI workflow, release automation, dependency pinning |
| [decisions/](decisions/) | Architecture Decision Records |

## Where the source of truth lives

These pages explain and cross-reference; they do not replace the files the
agent reads. When they disagree, the files below win and this documentation is
the bug.

| Topic | Source of truth |
|---|---|
| Agent workflow and red flags | [`skills/wrong-answer-labs/SKILL.md`](../skills/wrong-answer-labs/SKILL.md) |
| Lab format and anchors | [`references/lab-format.md`](../skills/wrong-answer-labs/references/lab-format.md) |
| Lab vs docs-only criteria | [`references/cost-policy.md`](../skills/wrong-answer-labs/references/cost-policy.md) |
| Cost and security policy | [`rules/*.guard`](../skills/wrong-answer-labs/rules/) |
| Tool versions | [`.github/workflows/ci.yml`](../.github/workflows/ci.yml) |

## Architecture Decision Records

| ADR | Decision |
|---|---|
| [0001](decisions/0001-default-deny-cost-gate.md) | Default-deny cost gate; rules are never relaxed to make a lab pass |
| [0002](decisions/0002-anchor-based-lab-structure.md) | Lab structure is validated through HTML comment anchors |
| [0003](decisions/0003-only-selftest-writes-to-aws.md) | Only `selftest.sh` writes to the AWS account; graders are read-only |
| [0004](decisions/0004-digest-pinned-ecr-public-images.md) | Container images come from Amazon ECR Public, pinned by digest |
| [0005](decisions/0005-automated-releases.md) | Versions and releases are automated with release-please |
