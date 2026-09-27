# Wrong Answer Labs

[![ci](https://github.com/jhermesn/wrong-answer-labs/actions/workflows/ci.yml/badge.svg)](https://github.com/jhermesn/wrong-answer-labs/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Missed some questions on an AWS Certification practice exam? Paste them into
your AI coding agent and get hands-on labs that make you fix exactly what you
got wrong, in your own AWS account.

Each lab works like an
[AWS Microcredential](https://aws.amazon.com/blogs/training-and-certification/microcredentials-from-aws-are-now-free-heres-why-that-matters/):
a short business scenario, an environment deployed for you, challenges you
solve in the AWS Console without step-by-step instructions, and a grader that
checks your work. Topics too expensive or impossible to reproduce (Direct
Connect, AWS Organizations policies, cross-account sharing...) become study
notes with the official documentation instead.

## Get started

You do this once.

1. **Install the plugin.** Inside a Claude Code session (not your terminal), run:

   ```text
   /plugin marketplace add jhermesn/wrong-answer-labs
   /plugin install wrong-answer-labs@jhermesn
   ```

   Using another agent that supports [Agent Skills](https://agentskills.io/specification)?
   Copy the `skills/wrong-answer-labs/` folder into its skills directory.

2. **Install the tools**, or ask your agent to install them: the
   [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html),
   [cfn-lint](https://github.com/aws-cloudformation/cfn-lint),
   [cfn-guard](https://github.com/aws-cloudformation/cloudformation-guard),
   [ShellCheck](https://www.shellcheck.net/), `jq` and `curl`.
   On macOS: `brew install awscli cfn-lint cloudformation-guard shellcheck jq`.

3. **Sign in to AWS** with `aws login`. Use a study account, never production.

## Use it

1. **Tell your agent what you missed.** For example:

   > I'm studying for SAA-C03. These are the questions I got wrong: …

   Text, screenshots and PDFs all work. Include your answer and the correct
   one if you have it; if not, the agent works it out from the AWS docs.

2. **Get your labs.** The agent confirms each answer in the official docs,
   groups related questions into scenarios, and writes one lab per scenario,
   in the language you use with it. Every lab is checked for cost, security
   and correctness before you see it (see below).

3. **Study.** For each lab, open its `README.md`: deploy the environment
   (or ask the agent to), solve the challenges in the AWS Console, and run
   `check.sh` until every item shows ✅. Stuck? `solution/README.md` explains
   the answer and why each wrong option was wrong.

4. **Clean up.** Run `cleanup.sh` (or ask the agent to). It deletes everything
   the lab created, including what you made during the challenges.

You can also ask the agent to run the self-test first: it deploys the lab,
proves the grader and the reference solution work, and cleans up.

For a complete lab and a documentation-only entry, see
[`skills/wrong-answer-labs/examples/`](skills/wrong-answer-labs/examples/).

## Cost and safety

Labs run in **your** AWS account, so an AI-written lab is only trusted after
automatic checks pass:

- **Cost:** only resource types someone has reviewed are allowed, sizes are
  capped (small instances, small databases, small disks), and nothing may
  survive the cleanup. Each lab lists its estimated cost, taken from AWS's
  price list; most cost well under US$1.
- **Security:** no SSH or RDP open to the internet, no admin permissions, no
  public buckets or databases, container images pinned to an exact version.
- **Correctness:** the CloudFormation template is valid, the grader only reads
  your account, every AWS command in the scripts exists, and every
  documentation link works.

These checks cover the lab as written. What you do in the Console, or code a
lab runs, is outside them, so set an
[AWS Budget](https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html)
and always run the cleanup.

## Contributing

Found an expensive resource the checks miss, or a lab that came out wrong? See
[CONTRIBUTING.md](CONTRIBUTING.md). Security issues go through
[SECURITY.md](SECURITY.md).

## Disclaimer

Not affiliated with, endorsed by, or sponsored by Amazon Web Services. AWS and
AWS Certification are trademarks of Amazon.com, Inc. or its affiliates. Labs
generated here are not official assessments. You are responsible for any AWS
charges in your account.

## License

[MIT](LICENSE)
