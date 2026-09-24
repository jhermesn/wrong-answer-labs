# Contributing

Issues and pull requests are welcome, in English or Portuguese.

## Good first contributions

- **A cost rule.** Found a resource type or size that makes a lab expensive?
  Add it to `skills/aws-exam-questions-to-labs/rules/lab-cost.guard`, add a
  resource that breaks it to `tests/fixtures/bad-cost.yaml`, and list the rule in
  `tests/fixtures/bad-cost.expected`.
- **A security rule.** Same flow with `lab-security.guard` and
  `tests/fixtures/bad-security.*`.
- **An example lab** for another certification. Create it with
  `bash skills/aws-exam-questions-to-labs/scripts/new_lab.sh <CERT> <slug> --root skills/aws-exam-questions-to-labs/examples`,
  make it pass `validate_lab.sh`, and paste the `selftest.sh` output in the PR.
- **A lab that came out wrong.** Open an issue with the question you used, the
  generated lab, and what was wrong. That is how `SKILL.md` gets better.

## Before opening a PR

```bash
bash tests/run.sh
```

It checks that:
- `tests/fixtures/good.yaml` passes every rule and cfn-lint;
- each `bad-*.yaml` fails exactly the rules in its `.expected` file;
- every example passes `validate_lab.sh`.

CI runs the same script plus ShellCheck. Tool versions are pinned in
`.github/workflows/ci.yml`.

## Conventions

- Code, comments, file names and script output in English. Lab prose follows the
  learner's language.
- A rule never gets relaxed so a lab passes. If a topic needs a denied resource,
  the lab becomes documentation-only (see `references/cost-policy.md`).
- Commits follow [Conventional Commits](https://www.conventionalcommits.org/).
