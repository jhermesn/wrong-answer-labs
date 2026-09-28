# Contributing

Issues and pull requests are welcome.

## Good first contributions

- **A new resource type.** The cost gate is default deny: a type is usable in a
  lab only once it is on the allowlist in
  `skills/wrong-answer-labs/rules/lab-cost.guard`. To add one, read its pricing
  page, and if anything about it can grow the bill (instance size, count,
  capacity, provisioned throughput), add a size rule next to the allowlist.
  In the PR, link the pricing page and say what the smallest useful lab costs.
- **A cost rule.** Found a size or setting that makes a lab expensive? Add a rule
  to `lab-cost.guard` and
  [cfn-guard test cases](https://docs.aws.amazon.com/cfn-guard/latest/ug/testing-rules.html)
  to `tests/rules/lab-cost.test.yaml`: at least one where the rule fails and one
  where it passes or does not apply. Each failing case should break exactly one
  condition of the rule.
- **A security rule.** Same flow with `lab-security.guard` and
  `tests/rules/lab-security.test.yaml`.
- **An example lab** for another certification. With the skill installed, ask
  your agent to build a lab from real questions into
  `skills/wrong-answer-labs/examples/<CERT>/`, and let it run the self-test.
  Paste the self-test output in the PR: CI has no AWS account, so that is the
  one result it cannot reproduce.
- **A lab that came out wrong.** Open an issue with the question you used, the
  generated lab, and what was wrong. That is how `SKILL.md` gets better.

## Repository layout

```
.claude-plugin/              Claude Code plugin and marketplace manifests
skills/wrong-answer-labs/
  SKILL.md                   instructions the agent follows
  references/                lab format and cost policy
  rules/                     cfn-guard rules for cost and security
  assets/                    skeletons for labs and docs-only entries
  scripts/                   new_lab, validate_lab, selftest, price, image_digest
  examples/                  labs that pass every check
tests/                       tests for the rules and scripts (bash tests/run.sh)
evals/                       scenarios for checking how an agent uses the skill
docs/                        maintainer documentation and ADRs (docs/decisions/)
```

## Checks on your PR

CI runs on every pull request, with tool versions pinned in
`.github/workflows/ci.yml`. It validates `SKILL.md` against the Agent Skills
spec, runs ShellCheck, and runs `tests/run.sh`, which checks that:
- every resource type named in the rules exists in CloudFormation;
- every rule passes its test cases in `tests/rules/`, and has at least one
  failing case and one passing or skipped case;
- `validate_lab.sh` accepts every example and rejects deliberately broken labs;
- `new_lab.sh`, `price.sh` and `image_digest.sh` reject bad input;
- `selftest.sh` never deploys an unvalidated lab or adopts an existing stack.

Running it locally is optional.

## Releases

Releases are automatic. After each merge to `main`,
[release-please](https://github.com/googleapis/release-please) updates a
release pull request with the next version, worked out from the commit
messages, and the changelog. Merging that pull request tags the version,
publishes the GitHub release and bumps `.claude-plugin/plugin.json`, which is
what makes installed plugins update.

| Commit type | Next version (while below 1.0) |
|---|---|
| `fix:` | patch, e.g. 0.2.1 → 0.2.2 |
| `feat:` | minor, e.g. 0.2.1 → 0.3.0 |
| `feat!:` or `BREAKING CHANGE:` | minor, e.g. 0.2.1 → 0.3.0 |
| `docs:`, `test:`, `ci:`, `chore:` | no release on their own |

Never edit the version in `plugin.json` by hand.

## Conventions

- Code, comments, file names and script output in English. Lab prose follows the
  learner's language.
- A rule never gets relaxed so a lab passes. If a topic needs a denied resource,
  the lab becomes documentation-only (see `references/cost-policy.md`).
- Commits follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).
