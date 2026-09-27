# Stop double-charging customers

| Certification | Exam guide domain(s) | Duration | Source questions |
|---|---|---|---|
| DVA-C02 | 1 — Development with AWS Services; 4 — Troubleshooting and Optimization | 45 min | Q1, Q2, Q3 |

<!-- section:scenario -->
## Scenario

ShopFlow sells concert tickets. Each order lands in an SQS queue and a Lambda function charges the customer's card. Since the last sale, support has three complaints: some customers were charged twice, a handful of broken orders are retried over and over and nobody can look at them, and the nightly reconciliation worker that reads a second queue is running up a bill for requests that come back empty. The team wants each fixed with configuration only, without changing the function's code.

<!-- section:objectives -->
## What you will demonstrate

- Keep an SQS message from being processed twice while a Lambda function is still working on it.
- Set aside messages that keep failing so they stop being retried and can be inspected.
- Cut the number of empty receives a polling consumer pays for.

<!-- section:before-you-start -->
## Before you start

- A study AWS account (never production).
- Run every command in [AWS CloudShell](https://console.aws.amazon.com/cloudshell/home?region=us-east-1): bash, AWS CLI v2, `jq` and `git` come preinstalled and it is already signed in. Get the lab files there with `git clone` or **Actions → Upload file**. Running locally also works with bash, AWS CLI v2 and `jq`.
- Region: `us-east-1` (use the same one in every command).
- Environment creation time: ~2 min.

<!-- section:cost -->
### Estimated cost

| Resource | Price (us-east-1) | Cost for this lab (45 min) | Source |
|---|---|---|---|
| SQS standard requests (3 queues; Lambda polls the orders queue ~15 times a minute, about 2,000 requests in total) | US$0.40 per million | < US$0.01 | https://aws.amazon.com/sqs/pricing/ |
| Lambda requests and duration (128 MB; only runs when you send test orders) | US$0.20 per million requests + US$0.0000166667 per GB-second | < US$0.01 | https://aws.amazon.com/lambda/pricing/ |
| CloudWatch Logs ingestion (function logs, 1-day retention) | US$0.50 per GB | < US$0.01 | https://aws.amazon.com/cloudwatch/pricing/ |

> ⚠️ The cost only stays at this value if you run **Cleanup** at the end.

<!-- section:deploy -->
### Deploy the environment

```bash
aws cloudformation deploy \
  --template-file template.yaml \
  --stack-name lab-dva-c02-sqs-lambda-retries \
  --capabilities CAPABILITY_NAMED_IAM \
  --tags project=exam-labs cert=DVA-C02 lab=lab-dva-c02-sqs-lambda-retries \
  --region us-east-1
```

<!-- section:challenges -->
## Challenges

Use the AWS Management Console. There is no step-by-step: read the requirement, investigate the environment and solve it.
Use the exact **names** requested — the grader looks for them.

<!-- challenge:1 -->
### Challenge 1 — Charge each order once

Orders are sometimes charged twice: another invocation picks up an order while the first one is still charging it. Fix the orders queue (stack output `OrdersQueueUrl`) following AWS's recommendation for queues that trigger Lambda functions. The function (stack output `OrderProcessorName`) must keep working as it does today.

**Acceptance criteria**
- While an order is being processed, no other invocation receives it, with the margin AWS recommends for Lambda event sources.

<!-- challenge:2 -->
### Challenge 2 — Set broken orders aside

A few orders can never be processed and are retried forever. After their fifth failed attempt they must stop being retried and wait in the failed-orders queue (stack output `FailedOrdersQueueUrl`) for the team to inspect.

**Acceptance criteria**
- Orders that keep failing end up in the failed-orders queue.
- An order is set aside after exactly five failed attempts.

<!-- challenge:3 -->
### Challenge 3 — Stop paying for empty answers

The reconciliation worker reads the queue in stack output `ReconciliationQueueUrl` and most of its requests return no messages. Reduce those empty responses without changing the worker's code.

**Acceptance criteria**
- Every request the worker makes waits the longest time the queue allows for a message to arrive.

<!-- section:verify -->
## Verify

```bash
bash check.sh lab-dva-c02-sqs-lambda-retries
```

Each ✅ is a completed requirement. Maximum score: 4/4.

<!-- section:cleanup -->
## Cleanup

```bash
bash cleanup.sh lab-dva-c02-sqs-lambda-retries
```

<!-- section:references -->
## References

- [Using Lambda with Amazon SQS: configuring a queue](https://docs.aws.amazon.com/lambda/latest/dg/services-sqs-configure.html)
- [Handling errors for an SQS event source in Lambda](https://docs.aws.amazon.com/lambda/latest/dg/services-sqs-errorhandling.html)
- [Amazon SQS visibility timeout](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html)
- [Using dead-letter queues in Amazon SQS](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html)
- [Amazon SQS short and long polling](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-short-and-long-polling.html)

---

Stuck? The annotated solution and the answer key for the source questions are in [`solution/README.md`](solution/README.md). Try first.
