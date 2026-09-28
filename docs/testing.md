# Testing

Two layers, because they test different things:

| Layer | Tests | Runs |
|---|---|---|
| `tests/` | The **tooling**: rules, validator, scripts | Automatically in CI on every PR |
| `evals/` | The **agent's behavior** with the skill | Manually, with a real agent session |

A third check, `selftest.sh`, tests a single **lab** in a real account; see
[lab-lifecycle.md](lab-lifecycle.md#self-test).

## `tests/run.sh`

```bash
bash tests/run.sh
```

Needs `cfn-lint`, `cfn-guard`, `shellcheck` and `jq`; `aws` is optional
(one case is skipped without it). No AWS credentials, no network: the
validator runs with `--offline` and AWS is faked. Prints `PASS`/`FAIL` per
case and exits non-zero on any failure.

| Suite | What it proves |
|---|---|
| Resource types | Every `AWS::*::*` type named in `rules/*.guard` exists in CloudFormation. Builds a throwaway template with all of them and fails on cfn-lint `E3006`. Catches typos that would make a rule silently never match. |
| Guard rules | `cfn-guard test` passes for each `rules/<name>.guard` against `tests/rules/<name>.test.yaml`, and every rule has at least one `FAIL` case and one `PASS` or `SKIP` case (coverage gate). |
| `validate_lab.sh` | Accepts every directory under `examples/*/*/`, and rejects deliberately broken copies of the examples (see below). |
| `new_lab.sh` | Scaffolds a lab and a docs-only entry; a fresh scaffold fails validation on placeholders; rejects an existing directory (73), a lowercase cert code (64) and a non-kebab slug (64). |
| `price.sh` | Rejects a missing service code (1) and a malformed filter (64). |
| `image_digest.sh` | Rejects non-ECR-Public images and images without a tag (64). |
| `selftest.sh` | With a fake `aws` on `PATH` that records every call: an invalid lab aborts with **zero** AWS calls; an existing stack aborts after only `describe-stacks`. |

### Negative validator cases

Each case copies an example, applies one breakage, and asserts both rejection
and the specific message:

| Case | Breakage | Expected message |
|---|---|---|
| `leftover-placeholder` | Append `{{TITLE}}` | unfilled placeholders |
| `missing-section` | Drop `section:cleanup` | README.md lacks `<!-- section:cleanup -->` |
| `ungraded-challenge` | Delete `check 2` | challenge 2 has no 'check 2 ...' line |
| `check-for-unknown-challenge` | Add `check 3` | check.sh grades challenge 3 |
| `challenge-numbering-gap` | Renumber challenge 2 → 3 | challenge numbering has a gap at 2 |
| `challenge-without-solution` | Drop `solution:2` | no `<!-- solution:2 -->` |
| `lab-without-questions` | Drop `question:` anchors | no `<!-- question:Q<n> -->` blocks |
| `retained-resource` | `DeletionPolicy: Retain` | guard violations |
| `invalid-template` | Misspell a property | cfn-lint findings |
| `mutating-grader` | `put-bucket-versioning` in `check.sh` | not read-only |
| `invented-cli-command` | `aws autoscaling wait group-not-exists` | AWS CLI commands that do not exist |
| `unsafe-script` | Unused variable | shellcheck findings |
| `docs-without-questions` | Drop `question:` in docs-only | no `<!-- question:Q<n> -->` blocks |

When you add a validator check, add a case here.

## Rule unit tests (`tests/rules/`)

Format: [cfn-guard test files](https://docs.aws.amazon.com/cfn-guard/latest/ug/testing-rules.html).
`lab-cost.test.yaml` has 130 cases, `lab-security.test.yaml` 61.

```yaml
- name: provisioned redshift cluster is not allowed
  input:
    Resources:
      Warehouse: {Type: AWS::Redshift::Cluster}
  expectations:
    rules: {COST_ALLOWED_RESOURCE_TYPES: FAIL}
```

Conventions:

- Each `FAIL` case breaks **exactly one** condition of the rule, so a broken
  condition cannot hide behind another one.
- `SKIP` means the rule's filter found nothing to evaluate.
- Every rule needs at least one `FAIL` and one `PASS`/`SKIP` case; the
  coverage gate in `run.sh` enforces it by grepping `<RULE>: FAIL` and
  `<RULE>: (PASS|SKIP)`.

### Adding a rule or resource type

1. Read the pricing page; decide which properties can grow the bill.
2. Add the type to the allowlist and a size rule next to it in
   `lab-cost.guard` (or a rule in `lab-security.guard`).
3. Add failing and passing cases to the matching `tests/rules/*.test.yaml`.
4. `bash tests/run.sh`.
5. In the PR, link the pricing page and state the smallest useful lab cost.

## Evals (`evals/`)

JSON scenarios in the format of Anthropic's skill authoring best practices:
a `query` sent as the first message and a list of `expected_behavior` lines.

| File | Exercises |
|---|---|
| `01-single-lab.json` | One question → one lab without giving the answer away; asks before self-test |
| `02-docs-only.json` | Direct Connect → docs-only (criterion 1); derives the missing answer |
| `03-grouped-batch.json` | Three SQS/Lambda questions grouped into one lab; documented values; real prices |
| `04-diverse-batch.json` | Unrelated topics split; Organizations → docs-only (criterion 4); digest-pinned ECR Public image; no AWS writes while authoring |

To run one: start a fresh agent session with the skill installed in an empty
directory, send the `query`, and score each `expected_behavior` line as met or
not met. Run them after any change to `SKILL.md` or `references/`, on each
supported model, and record the results in the pull request.
