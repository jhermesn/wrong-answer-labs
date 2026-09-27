# wrong-answer-labs

[![ci](https://github.com/jhermesn/wrong-answer-labs/actions/workflows/ci.yml/badge.svg)](https://github.com/jhermesn/wrong-answer-labs/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Got an AWS Certification practice question wrong? Tell your coding agent the exam
and paste the questions. This [Agent Skill](https://agentskills.io/specification)
turns it into a **hands-on lab** in the style of
[AWS Microcredentials](https://aws.amazon.com/blogs/training-and-certification/microcredentials-from-aws-are-now-free-heres-why-that-matters/):
a business scenario, a CloudFormation environment, challenges you solve in the
Console with no step-by-step, and an automated grader.

Topics that cost too much or cannot be reproduced in a study account (Direct
Connect, Outposts, Shield Advanced...) become study notes with official
documentation instead of a lab.

```text
$ bash check.sh lab-saa-c03-s3-accidental-delete
  ✅ [1] Deleted or overwritten reports can be restored
  ✅ [2] Rule expire-noncurrent-30d is enabled
  ✅ [2] Old versions are permanently deleted after 30 days

Score: 3/3
```

Lab prose is written in the language you use with the agent.

## Why labs are safe to run

The LLM writes the lab, but tools decide whether it ships:

| Gate | Tool | What it checks |
|---|---|---|
| Cost | [cfn-guard](https://github.com/aws-cloudformation/cloudformation-guard) rules | Default deny: only reviewed resource types, small literal sizes (t3/t4g, db.t*, small volumes and task sizes), no custom resources, no retained resources |
| Security | cfn-guard rules | No SSH/RDP open to the internet, IMDSv2, no `Action: *`, private S3, managed DB passwords |
| Template | [cfn-lint](https://github.com/aws-cloudformation/cfn-lint) | Valid CloudFormation, best practices |
| Grader | `validate_lab.sh` | `check.sh` only calls read-only AWS operations |
| Scripts | [ShellCheck](https://www.shellcheck.net/) | Grader and cleanup scripts are sound |
| Links | curl | Every doc and pricing link resolves (AWS docs soft-404s are detected) |
| Real run | `selftest.sh` | Validate → deploy → grader scores 0/N → reference solution → N/N → cleanup |

Every lab ships a `cleanup.sh` that empties buckets and deletes the stack.

The gates check the template, not what happens after it is deployed: your own
actions in the Console, or code a lab's Lambda function runs, are outside them.
That is why every lab also lists its estimated cost and why you should set a budget.

## Install

**Claude Code (plugin):** type these inside a Claude Code session, not in your
system shell:

```text
/plugin marketplace add jhermesn/wrong-answer-labs
/plugin install wrong-answer-labs@jhermesn
```

**Any agent that supports Agent Skills:** copy `skills/wrong-answer-labs/`
into the agent's skills directory (for Claude Code: `~/.claude/skills/`).

Then ask:

> I'm studying for SAA-C03. These are the questions I got wrong: ...

### Who runs what

| Step | Who |
|---|---|
| Install the plugin, sign in to AWS (`aws login`) | You, once |
| Install cfn-lint, cfn-guard, ShellCheck | You once, or the agent if you let it |
| Check answers, write labs, validate, price, self-test | The agent |
| Deploy a lab, solve it in the Console, run `check.sh`, run `cleanup.sh` | You (that is the lab), or ask the agent to deploy and clean up |
| Contribute: branch, commit, open a pull request | You or your agent |
| Test every pull request | CI |

### Requirements

| Tool | Install |
|---|---|
| cfn-lint | `pipx install cfn-lint` |
| cfn-guard | `brew install cloudformation-guard` or a [release binary](https://github.com/aws-cloudformation/cloudformation-guard/releases) |
| ShellCheck | `brew install shellcheck` / `apt install shellcheck` |
| jq, curl | usually preinstalled |
| Checkov (optional) | `pipx install checkov` |
| AWS CLI v2 | only to deploy labs and run `selftest.sh` |

## What a lab looks like

```
labs/SAA-C03/s3-accidental-delete/
  README.md            scenario, challenges, cost table, deploy and cleanup commands
  template.yaml        starting environment (CloudFormation)
  check.sh             automated grader
  cleanup.sh           deletes everything the lab created
  solution/README.md   annotated solution + answer key for your original questions
  solution/solve.sh    reference solution through the CLI
```

See [`skills/wrong-answer-labs/examples/`](skills/wrong-answer-labs/examples/)
for two full labs (SAA-C03 and DVA-C02) and a documentation-only entry.

## Cost

Labs run in **your** AWS account. The cost policy targets under US$1 per lab when
you run the cleanup at the end, and every lab lists its estimated cost with links
to the official pricing pages. Use a study account, never production, and set an
[AWS Budget](https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html).

## Repository layout

```
.claude-plugin/                     Claude Code plugin + marketplace manifests
skills/wrong-answer-labs/
  SKILL.md                          agent instructions
  references/                       lab format and cost policy
  rules/                            cfn-guard rules (cost + security)
  assets/                           lab and docs-only skeletons
  scripts/                          new_lab.sh, validate_lab.sh, selftest.sh, price.sh
  examples/                         labs that pass every gate
tests/                              regression tests (run: bash tests/run.sh)
evals/                              scenarios for checking agent behavior with the skill
```

## Contributing

Found an expensive resource the rules miss, or a lab that came out wrong?
See [CONTRIBUTING.md](CONTRIBUTING.md).

## Disclaimer

Not affiliated with, endorsed by, or sponsored by Amazon Web Services. AWS and
AWS Certification are trademarks of Amazon.com, Inc. or its affiliates. The lab
format is inspired by AWS Microcredentials; labs generated here are not official
assessments. You are responsible for any AWS charges in your account.

## License

[MIT](LICENSE)
