# Solution — Recover reports after an accidental delete

> Spoilers. Open only after attempting the challenges.

<!-- section:solutions -->
## Challenge solutions

<!-- solution:1 -->
### Challenge 1

Console: S3 → bucket → **Properties** → **Bucket Versioning** → Edit → Enable.
CLI: `aws s3api put-bucket-versioning --bucket <bucket> --versioning-configuration Status=Enabled`.

Why: with versioning, a DELETE only adds a delete marker; removing the marker (or copying an older version) restores the object. That is the recovery mechanism the exam expects.

<!-- solution:2 -->
### Challenge 2

Console: S3 → bucket → **Management** → **Create lifecycle rule** → name `expire-noncurrent-30d`, scope *all objects*, action *Permanently delete noncurrent versions of objects*, 30 days.
CLI: see `solution/solve.sh`.

Why: versioning alone keeps every old copy forever and you pay for all of them. `NoncurrentVersionExpiration` bounds the cost.

Apply the reference solution through the CLI (useful to double-check the grader):

```bash
bash solution/solve.sh lab-saa-c03-s3-accidental-delete
bash check.sh lab-saa-c03-s3-accidental-delete
```

<!-- section:answers -->
## Answer key

<!-- question:Q1 -->
### Q1 — Protect S3 objects from accidental deletion at low cost

**Question (summary):** a company must be able to recover objects accidentally deleted from S3, keeping costs low and operations simple. Which solution?

- **Your answer:** enable MFA Delete on the bucket.
- **Correct answer:** enable S3 Versioning and add a lifecycle rule that expires noncurrent versions.

**Why MFA Delete is wrong here:** it only blocks *permanent* version deletion and versioning changes, it can only be enabled by the root user through the CLI/API, and it does not restore anything by itself; it also requires versioning. **Why Object Lock / Cross-Region Replication are wrong:** they add retention or a second copy (and cost) when the requirement is only recoverability.

Docs: [S3 Versioning](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html), [MFA delete](https://docs.aws.amazon.com/AmazonS3/latest/userguide/MultiFactorAuthenticationDelete.html).
