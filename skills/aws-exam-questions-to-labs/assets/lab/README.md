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

- A study AWS account (never production), AWS CLI v2 configured, `jq` installed.
- Region: `us-east-1` (use the same one in every command).
- Environment creation time: ~{{DEPLOY_MINUTES}} min.

<!-- section:cost -->
### Estimated cost

| Resource | Price (us-east-1) | Cost for this lab ({{MINUTES}} min) | Source |
|---|---|---|---|
{{COST_ROWS}}

> ⚠️ The cost only stays at this value if you run **Cleanup** at the end.

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
Use the exact **names** requested — the grader looks for them.

{{CHALLENGES}}

<!-- section:verify -->
## Verify

```bash
bash check.sh {{STACK_NAME}}
```

Each ✅ is a completed requirement. Maximum score: {{CHECK_COUNT}}/{{CHECK_COUNT}}.

<!-- section:cleanup -->
## Cleanup

```bash
bash cleanup.sh {{STACK_NAME}}
```

<!-- section:references -->
## References

{{REFERENCES}}

---

Stuck? The annotated solution and the answer key for the source questions are in [`solution/README.md`](solution/README.md). Try first.
