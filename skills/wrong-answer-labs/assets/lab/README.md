# {{TITLE}}

| Certification | Exam guide domain(s) | Duration | Source questions |
|---|---|---|---|
| {{CERT}} | {{DOMAINS}} | {{MINUTES}} min | {{QUESTION_IDS}} |

<!-- section:scenario -->
## Scenario

{{SCENARIO}}

<!-- section:objectives -->
## What you will demonstrate

{{LEARNING_OBJECTIVES}}

<!-- section:before-you-start -->
## Before you start

- **This lab creates billable resources in your AWS account, and you pay for them until you run [Cleanup](#cleanup).**
- A study AWS account (never production), with an [AWS Budget](https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html) alert.
- Run every command in [AWS CloudShell](https://console.aws.amazon.com/cloudshell/home?region=us-east-1): bash, AWS CLI v2, `jq` and `git` come preinstalled and it is already signed in. Get the lab files there with `git clone` or **Actions → Upload file**. Running locally also works with bash, AWS CLI v2 and `jq`.
- Region: `us-east-1` (use the same one in every command).
- Environment creation time: ~{{DEPLOY_MINUTES}} min.

<!-- section:cost -->
### Estimated cost

| Resource | Price (us-east-1) | Cost for this lab ({{MINUTES}} min) | Source |
|---|---|---|---|
{{COST_ROWS}}

> ⚠️ These are estimates from on-demand prices. Resources keep billing until you run **Cleanup**, including anything you create during the challenges.

<!-- section:deploy -->
### Deploy the environment

```bash
aws cloudformation deploy \
  --template-file template.yaml \
  --stack-name {{STACK_NAME}} \
  --capabilities CAPABILITY_NAMED_IAM \
  --tags project=exam-labs cert={{CERT}} lab={{STACK_NAME}} \
  --region us-east-1
```

<!-- section:challenges -->
## Challenges

Use the AWS Management Console. There is no step-by-step: read the requirement, investigate the environment and solve it.
Use the exact names requested, because the grader looks for them.

{{CHALLENGES}}

<!-- section:verify -->
## Verify

```bash
bash check.sh {{STACK_NAME}}
```

Each ✅ is a completed requirement. Maximum score: {{CHECK_COUNT}}/{{CHECK_COUNT}}.

<!-- section:cleanup -->
## Cleanup

Run it even if you did not finish. Until it runs, the lab keeps billing your account.

```bash
bash cleanup.sh {{STACK_NAME}}
```

<!-- section:references -->
## References

{{REFERENCES}}

---

Stuck? The annotated solution and the answer key for the source questions are in [`solution/README.md`](solution/README.md). Try first.
