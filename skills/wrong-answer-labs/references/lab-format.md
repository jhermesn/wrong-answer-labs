# Lab format (AWS Microcredential style)

AWS Microcredentials ("... Demonstrated") are timed (~90 min), performance-based
assessments: the learner is dropped into a live AWS environment with a business
scenario and a set of challenges, solves them in the Console with **no hints and
no step-by-step**, and is graded automatically on the resulting configuration.
Every lab this skill produces follows that shape.

## Contents

- Lab directory
- Anchors (the validator depends on them)
- Scenario
- Challenges
- Template (`template.yaml`)
- Apps, images and code
- Grader (`check.sh`)
- Cleanup (`cleanup.sh`)
- Solution (`solution/README.md` + `solution/solve.sh`)

## Lab directory

```
labs/<CERT>/<slug>/
  README.md            scenario + challenges (what, never how)
  template.yaml        starting environment (CloudFormation)
  check.sh             automated grader (AWS CLI + JMESPath)
  cleanup.sh           deletes the stack and anything created in the challenges
  solution/README.md   annotated solution + answer key for the source questions
  solution/solve.sh    reference solution through the CLI (used by selftest.sh)
```

## Anchors (the validator depends on them)

Headings may be in any language; these HTML comments may not change:

| Anchor | File | Rule |
|---|---|---|
| `<!-- section:<name> -->` | README.md | keep every one shipped in the asset template |
| `<!-- challenge:N -->` | README.md | one per challenge, numbered 1..N, N ≤ 5 |
| `<!-- solution:N -->` | solution/README.md | one per challenge |
| `<!-- question:QN -->` | solution/README.md (docs-only: README.md) | one per source question |

## Scenario

3-6 sentences. A fictional company, what it runs, what just went wrong or what
the business now needs, and the constraint that makes the exam's "best" answer
the right one (cost, least operational overhead, RPO/RTO, least privilege...).
The constraint must come from the question the learner got wrong.

## Challenges

Each challenge turns one misconception from the source questions into a task.
Prefer **troubleshoot** (template ships something broken or incomplete) and
**build/change** (learner creates or reconfigures) over "look at X".

```markdown
<!-- challenge:1 -->
### Challenge 1 — Survive an accidental delete

The compliance team requires that any object deleted from the `reports` bucket
(stack output `ReportsBucketName`) can be restored for 30 days.

**Acceptance criteria**
- A deleted or overwritten report can be restored from the bucket itself.
- A rule named `expire-noncurrent-30d` permanently removes old copies 30 days
  after they stop being current.
```

Rules:
- State the outcome and the constraint, never the Console path or the service
  feature name if naming it gives away the answer (write "can be restored",
  not "enable versioning").
- Acceptance criteria are observable facts the grader checks. Give **exact
  names** for anything the learner creates; reference stack resources by their
  stack **output** key.
- 1-5 challenges, total solve time ≤ 90 min. Order from simplest to hardest.

## Template (`template.yaml`)

- Provisions the starting state only. It must not satisfy any acceptance
  criterion (selftest enforces: baseline score 0/N).
- No hardcoded account IDs, regions, AZs or AMI IDs: `AWS::AccountId`,
  `AWS::Region`, `!GetAZs`, SSM public parameters for AMIs.
- Let CloudFormation generate physical names; expose what the learner needs as
  **Outputs** (`ReportsBucketName`, `AppUrl`...).
- Only resource types on the allowlist in `rules/lab-cost.guard`, with literal
  sizes (no parameters) inside its limits. Never custom resources.
- Security baseline from `rules/lab-security.guard`. A rule is suppressed only
  when the insecure setting is itself the challenge, via
  `Metadata.guard.SuppressedRules` on that one resource.
- EC2 access goes through SSM Session Manager (instance profile with
  `AmazonSSMManagedInstanceCore`), never SSH open to the internet.
- Every resource must be deletable by `delete-stack`: `DeletionPolicy: Delete`,
  no deletion protection, `EmptyOnDelete: true` on ECR repositories.
- Target deploy time ≤ 15 min; state it in the README.

## Apps, images and code

When a scenario needs something running (a web page, a batch job, sample
data), use the first option that works:

1. **No app at all**: a managed feature or the service's own test action
   (an ALB fixed response, an EventBridge test event).
2. **Operating system packages** from the AMI's repositories in `UserData`
   (`dnf install -y httpd`), with at most a one-line page of content.
3. **Official container images from Amazon ECR Public**
   (`public.ecr.aws/docker/library/...` or AWS-published images), configured
   with `Command`/`Environment`. Pin them by digest:
   `bash <skill>/scripts/image_digest.sh public.ecr.aws/<repository>:<tag>`
   prints the reference to use; the security rules reject tags. A template
   cannot build or push images, so never plan a custom image.
4. **Handwritten code** only for glue nothing above provides: inline
   (`ZipFile`, `UserData`), under about 30 lines, no third-party dependencies.

## Grader (`check.sh`)

One `check` line per acceptance criterion:

```bash
# check <challenge-number> "<description>" "<expected stdout>" <command...>
check 1 "Deleted or overwritten reports can be restored" "Enabled" \
  aws s3api get-bucket-versioning --bucket "$(stack_output ReportsBucketName)" \
    --query Status --output text

check 1 "Old copies are removed 30 days after they stop being current" "30" \
  aws s3api get-bucket-lifecycle-configuration --bucket "$(stack_output ReportsBucketName)" \
    --query "Rules[?ID=='expire-noncurrent-30d'] | [0].NoncurrentVersionExpiration.NoncurrentDays" --output text
```

- Read-only: only `get-*`, `describe-*`, `list-*`, `head-*`, `simulate-*`,
  `lookup-*`, `search-*`, `filter-*`, `batch-get-*`, `query`, `scan` and `ls`
  operations, written as `aws <service> <operation> [options]`. The validator
  rejects anything else, because the grader runs in the learner's account on
  every check.
- Read state with the AWS CLI; filter with `--query` (JMESPath) down to one
  scalar compared by exact match. For a boolean condition, make the query
  return `true`/`false` (e.g. `length(...) > \`0\``).
- Grade the **resulting configuration**, not the path taken. Accept every
  valid solution the exam would accept (e.g. check the effective permission
  with `aws iam simulate-principal-policy` instead of a specific policy name).
- Every check must fail against the freshly deployed template.

## Cleanup (`cleanup.sh`)

Replace `{{CHALLENGE_CLEANUP}}` with idempotent deletes (`|| true`) of every
resource the learner creates outside the stack (by the exact names the
challenges required), or with `# The challenges only change stack resources.`

## Solution (`solution/README.md` + `solution/solve.sh`)

- Per challenge: Console steps, the CLI equivalent (same commands as
  `solve.sh`), and **why** this is what the exam wants.
- Per source question: the question (summarized), the learner's answer, the
  correct answer, why each wrong option is wrong, and the doc link that proves
  it. Mark the answer `⚠️ unverified` when no official doc confirms it.
