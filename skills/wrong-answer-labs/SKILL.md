---
name: wrong-answer-labs
description: Turns AWS Certification questions a learner got wrong into hands-on labs in the style of AWS Microcredentials (CloudFormation environment, Console challenges, automated grader), or into documentation-only study notes when a lab would cost too much. Use when someone studying for an AWS Certification exam (CLF, AIF, SAA, SOA, DVA, DEA, MLA, SAP, DOP, SCS, ANS...) shares practice or exam questions they missed and wants to review them hands-on.
license: MIT
compatibility: Requires bash, cfn-lint, cfn-guard, shellcheck, jq and curl, plus network access for documentation lookups and link checks. AWS CLI v2 with credentials is needed only to deploy labs and run the self-test.
---

# AWS exam questions → hands-on labs

## Overview

Turn missed exam questions into AWS Microcredential-style labs: a business
scenario, a CloudFormation starting environment, challenges solved in the
Console without step-by-step, and an automated grader. Topics too expensive or
impossible to reproduce (Direct Connect, Outposts, Shield Advanced...) become
docs-only entries with official documentation instead.

Determinism comes from tools, not judgment: `cfn-lint`, `cfn-guard` rules
(cost + security), `shellcheck`, a link checker, and a real-account self-test.
Scripts are in this skill's `scripts/`; `<skill>` below is this skill's base directory.

## Inputs

- **Certification**: exam code (`SAA-C03`). If missing, ask; it decides depth and domains.
- **Questions**: text, screenshots or PDF. For each: stem, options, the learner's answer, and the correct answer if they have it.

Requires `cfn-lint`, `cfn-guard`, `shellcheck`, `jq`, `curl`; `checkov` optional. Missing? Tell the user the install command printed by the validator.

## Workflow

1. **Normalize** questions as `Q1..Qn`: tested concept, services, learner's answer, correct answer. When the correct answer is not given, derive it and confirm it in official AWS documentation: when the AWS Documentation MCP server (`awslabs.aws-documentation-mcp-server`) is connected, use its `search_documentation` then `read_documentation` tools; otherwise fetch docs.aws.amazon.com pages directly. No confirming doc → mark `⚠️ unverified`.
2. **Map domains** from the official exam guide (index: https://docs.aws.amazon.com/aws-certification/latest/examguides/aws-certification-exam-guides.html).
3. **Split into scenarios**: one lab per realistic scenario (1-5 challenges, ≤ 90 min). Questions that fit the same scenario share a lab (Multi-AZ database + load balancer + WAF are one "highly available web tier"); questions that do not fit together get a lab each. Never force unrelated questions into one lab.
4. **Decide lab vs docs-only** with `references/cost-policy.md`.
5. **Scaffold**: `bash <skill>/scripts/new_lab.sh <CERT> <kebab-slug> [--docs-only] [--root <dir>]`. Labs go to `./labs/<CERT>/<slug>/` in the current directory unless the user wants another `--root`. It prints the lab directory.
6. **Fill every `{{PLACEHOLDER}}`** following `references/lab-format.md`. Prose in the user's language; code, identifiers, file names and anchors stay as shipped.
7. **Gate**: `bash <skill>/scripts/validate_lab.sh <lab-dir>` until `PASS`. Fix the lab, never the rules.
8. **Self-test** (labs only): creates billable resources — ask the user first, and needs AWS credentials. `bash <skill>/scripts/selftest.sh <lab-dir>` must end in `SELFTEST PASS` (baseline 0/N, solved N/N, cleanup ran).
9. **Report**: one row per lab/docs-only entry with questions covered, estimated cost, validator result, and self-test result (or "not run" and why).

## Red flags — stop and fix the lab

| Temptation | Why it is wrong |
|---|---|
| Edit `rules/*.guard` (including adding a type to the allowlist) or add a suppression so the template passes | Rules are the cost/security contract. A lab that needs a type outside the allowlist is docs-only. Suppress a security rule only when that insecure setting is the challenge. |
| Use a custom resource or a Lambda that creates resources | It bypasses the cost and security gate. Not allowed. |
| Create, change or delete AWS resources while writing a lab ("just a quick probe") | Only `selftest.sh` touches the account, and only after the user agrees. Check facts in the docs, with `cfn-lint`, or with read-only calls. |
| Handwrite an app, container image or sample data | Use what already exists and is maintained first; see "Apps, images and code" in `references/lab-format.md`. |
| Parameterize an instance type/size | Learners could deploy something bigger than the guard validated. Sizes are literals. |
| Challenge text names the feature that answers it | Microcredentials give requirements, not solutions. State the outcome. |
| A check passes right after deploy | The template solved the challenge. Selftest will fail. |
| Price or doc URL from memory | Pricing page or Pricing API only; the validator curls every link. |
| Skip cleanup of resources created in challenges | They keep billing. List them in `cleanup.sh`. |

## Quick reference

| File | Purpose |
|---|---|
| `references/lab-format.md` | Scenario/challenge/grader/template rules, anchors |
| `references/cost-policy.md` | Lab vs docs-only criteria, cost table sourcing |
| `examples/SAA-C03/s3-accidental-delete` | Complete lab that passes the gate — copy its style |
| `examples/DVA-C02/sqs-lambda-retries` | Three grouped questions in one lab, with a grader that computes its expected value |
| `examples/SAA-C03/direct-connect-resiliency` | Complete docs-only entry |
| `scripts/price.sh` | On-demand prices from the Price List API for the cost table |
| `scripts/image_digest.sh` | Pins an Amazon ECR Public image tag to its digest |
| `rules/lab-cost.guard`, `rules/lab-security.guard` | cfn-guard policy, run by the validator |
