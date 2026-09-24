# Lab format (AWS Microcredential style)

AWS Microcredentials ("... Demonstrated") are timed (~90 min), performance-based
assessments: the learner is dropped into a live AWS environment with a business
scenario and a set of challenges, solves them in the Console with **no hints and
no step-by-step**, and is graded automatically on the resulting configuration.
Every lab this skill produces follows that shape.

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
- Versioning is enabled on the reports bucket.
- A lifecycle rule named `expire-noncurrent-30d` permanently deletes noncurrent versions after 30 days.
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
- Sizes are literals (no parameters) and within `rules/lab-cost.guard`.
- Security baseline from `rules/lab-security.guard`. A rule is suppressed only
  when the insecure setting is itself the challenge, via
  `Metadata.guard.SuppressedRules` on that one resource.
- EC2 access goes through SSM Session Manager (instance profile with
  `AmazonSSMManagedInstanceCore`), never SSH open to the internet.
- Every resource must be deletable by `delete-stack`: `DeletionPolicy: Delete`,
  no deletion protection, `EmptyOnDelete: true` on ECR repositories.
- Target deploy time ≤ 15 min; state it in the README.

## Grader (`check.sh`)

One `check` line per acceptance criterion:

```bash
# check <challenge-number> "<description>" "<expected stdout>" <command...>
check 1 "Versioning enabled on the reports bucket" "Enabled" \
  aws s3api get-bucket-versioning --bucket "$(stack_output ReportsBucketName)" \
    --query Status --output text

check 1 "Lifecycle expires noncurrent versions after 30 days" "30" \
  aws s3api get-bucket-lifecycle-configuration --bucket "$(stack_output ReportsBucketName)" \
    --query "Rules[?ID=='expire-noncurrent-30d'] | [0].NoncurrentVersionExpiration.NoncurrentDays" --output text
```

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
