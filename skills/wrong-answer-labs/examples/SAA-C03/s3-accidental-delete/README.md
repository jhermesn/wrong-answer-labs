# Recover reports after an accidental delete

| Certification | Exam guide domain(s) | Duration | Source questions |
|---|---|---|---|
| SAA-C03 | 2 — Design Resilient Architectures; 4 — Design Cost-Optimized Architectures | 30 min | Q1 |

<!-- section:scenario -->
## Scenario

Contoso Finance publishes monthly reports to an S3 bucket. Last week an analyst ran a cleanup script against the wrong prefix and three months of reports were lost for good. Auditors now require that any deleted or overwritten report can be restored, but finance does not want to pay to keep old copies forever, and nobody wants a process that depends on the root user.

<!-- section:objectives -->
## What you will demonstrate

- Protect S3 objects against accidental deletion and overwrite.
- Control the storage cost of that protection automatically.

<!-- section:before-you-start -->
## Before you start

- A study AWS account (never production).
- Run every command in [AWS CloudShell](https://console.aws.amazon.com/cloudshell/home?region=us-east-1): bash, AWS CLI v2, `jq` and `git` come preinstalled and it is already signed in. Get the lab files there with `git clone` or **Actions → Upload file**. Running locally also works with bash, AWS CLI v2 and `jq`.
- Region: `us-east-1` (use the same one in every command).
- Environment creation time: ~1 min.

<!-- section:cost -->
### Estimated cost

| Resource | Price (us-east-1) | Cost for this lab (30 min) | Source |
|---|---|---|---|
| S3 Standard storage (a few KB) | US$0.023 per GB-month | < US$0.01 | https://aws.amazon.com/s3/pricing/ |

> ⚠️ The cost only stays at this value if you run **Cleanup** at the end.

<!-- section:deploy -->
### Deploy the environment

```bash
aws cloudformation deploy \
  --template-file template.yaml \
  --stack-name lab-saa-c03-s3-accidental-delete \
  --capabilities CAPABILITY_NAMED_IAM \
  --tags project=exam-labs cert=SAA-C03 lab=lab-saa-c03-s3-accidental-delete \
  --region us-east-1
```

<!-- section:challenges -->
## Challenges

Use the AWS Management Console. There is no step-by-step: read the requirement, investigate the environment and solve it.
Use the exact **names** requested — the grader looks for them.

<!-- challenge:1 -->
### Challenge 1 — Nothing is lost for good

Make sure that a report deleted or overwritten in the reports bucket (stack output `ReportsBucketName`) can be restored by any administrator, without involving the root user.

**Acceptance criteria**
- A deleted report can be brought back from the bucket itself.

<!-- challenge:2 -->
### Challenge 2 — Pay only for 30 days of history

Finance agrees to keep previous copies of a report for 30 days only.

**Acceptance criteria**
- An enabled rule named `expire-noncurrent-30d` applies to the whole bucket.
- Copies that stopped being the current one are permanently removed 30 days later.

<!-- section:verify -->
## Verify

```bash
bash check.sh lab-saa-c03-s3-accidental-delete
```

Each ✅ is a completed requirement. Maximum score: 3/3.

<!-- section:cleanup -->
## Cleanup

```bash
bash cleanup.sh lab-saa-c03-s3-accidental-delete
```

<!-- section:references -->
## References

- [Retaining multiple versions of objects with S3 Versioning](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html)
- [Lifecycle configuration elements](https://docs.aws.amazon.com/AmazonS3/latest/userguide/intro-lifecycle-rules.html)
- [Configuring MFA delete](https://docs.aws.amazon.com/AmazonS3/latest/userguide/MultiFactorAuthenticationDelete.html)

---

Stuck? The annotated solution and the answer key for the source questions are in [`solution/README.md`](solution/README.md). Try first.
