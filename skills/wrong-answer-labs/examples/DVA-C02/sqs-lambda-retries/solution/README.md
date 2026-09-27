# Solution — Stop double-charging customers

> Spoilers. Open only after attempting the challenges.

<!-- section:solutions -->
## Challenge solutions

<!-- solution:1 -->
### Challenge 1

Console: SQS → the orders queue → **Edit** → **Visibility timeout** = 3 minutes (180 seconds) → Save.
CLI: `aws sqs set-queue-attributes --queue-url <orders-queue-url> --attributes VisibilityTimeout=180`.

Why: while Lambda works on a batch the messages are only hidden for the visibility timeout. With 30 seconds for a 30-second function, a slow or throttled invocation lets the message reappear and a second invocation charges it again. AWS recommends a visibility timeout of at least six times the function timeout for SQS event sources.

<!-- solution:2 -->
### Challenge 2

Console: SQS → the orders queue → **Edit** → **Dead-letter queue** → Enabled, choose the failed-orders queue, **Maximum receives** = 5 → Save.
CLI: see `solution/solve.sh` (sets `RedrivePolicy` with `deadLetterTargetArn` and `maxReceiveCount: 5`).

Why: the redrive policy lives on the source queue. After `maxReceiveCount` receives without a delete, SQS moves the message to the dead-letter queue. AWS recommends at least 5 for Lambda so throttling does not send healthy messages away too early.

<!-- solution:3 -->
### Challenge 3

Console: SQS → the reconciliation queue → **Edit** → **Receive message wait time** = 20 seconds → Save.
CLI: `aws sqs set-queue-attributes --queue-url <reconciliation-queue-url> --attributes ReceiveMessageWaitTimeSeconds=20`.

Why: a wait time above 0 turns on long polling for every ReceiveMessage call that does not set its own wait. SQS then waits for messages to arrive instead of answering empty, which removes empty and false-empty responses. 20 seconds is the maximum.

Apply the reference solution through the CLI (useful to double-check the grader):

```bash
bash solution/solve.sh lab-dva-c02-sqs-lambda-retries
bash check.sh lab-dva-c02-sqs-lambda-retries
```

<!-- section:answers -->
## Answer key

<!-- question:Q1 -->
### Q1 — Orders processed twice by a Lambda function reading SQS

- **Your answer:** C) switch to a FIFO queue.
- **Correct answer:** B) set the queue visibility timeout to at least six times the function timeout.

A FIFO queue removes duplicate *sends* within its deduplication window, but the duplicates here come from the same message becoming visible again while the first invocation still has it. Only the visibility timeout controls that. More memory (A) may speed the function up but leaves no margin for throttling or retries. Long polling (D) changes how empty receives behave, not how long a received message stays hidden.

Docs: [Configuring a queue to use with Lambda](https://docs.aws.amazon.com/lambda/latest/dg/services-sqs-configure.html).

<!-- question:Q2 -->
### Q2 — Messages that fail every time

- **Your answer:** D) configure a Lambda on-failure destination.
- **Correct answer:** A) configure a dead-letter queue with a redrive policy on the source queue.

On-failure destinations cover asynchronous invocations and the Kinesis, DynamoDB and Kafka event source mappings. An SQS trigger is not one of them: Lambda leaves failed messages on the queue, so the redrive policy of the queue decides where they go. A longer retention period (B) only keeps retrying for longer, and a delay queue (C) postpones the first delivery.

Docs: [Retaining records of Lambda invocations](https://docs.aws.amazon.com/lambda/latest/dg/invocation-async-retain-records.html), [Using dead-letter queues in Amazon SQS](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html).

<!-- question:Q3 -->
### Q3 — Too many empty receives

- **Your answer:** A) short polling with MaxNumberOfMessages set to 10.
- **Correct answer:** B) enable long polling by setting ReceiveMessageWaitTimeSeconds greater than 0. You did not have the answer key; this was confirmed in the SQS documentation below.

MaxNumberOfMessages only raises how many messages a non-empty response can carry; short polling still answers immediately, empty or not. The visibility timeout (C) and FIFO queues (D) do not affect empty responses.

Docs: [Amazon SQS short and long polling](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-short-and-long-polling.html).
