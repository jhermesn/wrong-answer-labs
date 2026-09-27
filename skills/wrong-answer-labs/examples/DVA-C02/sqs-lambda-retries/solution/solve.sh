#!/usr/bin/env bash
# Reference solution: applies through the CLI what the learner does in the Console.
# Usage: bash solution/solve.sh <stack-name> [region]
set -euo pipefail

STACK="${1:?usage: bash solution/solve.sh <stack-name> [region]}"
export AWS_REGION="${2:-${AWS_REGION:-us-east-1}}"

stack_output() {
  aws cloudformation describe-stacks --stack-name "$STACK" \
    --query "Stacks[0].Outputs[?OutputKey=='$1'].OutputValue | [0]" --output text
}

stack_resource() {
  aws cloudformation describe-stack-resource --stack-name "$STACK" --logical-resource-id "$1" \
    --query 'StackResourceDetail.PhysicalResourceId' --output text
}

orders_queue="$(stack_output OrdersQueueUrl)"

# Challenge 1: six times the 30-second function timeout
aws sqs set-queue-attributes --queue-url "$orders_queue" --attributes VisibilityTimeout=180

# Challenge 2: move an order to the failed-orders queue after 5 failed receives
redrive_policy="$(jq -cn --arg arn "$(stack_output FailedOrdersQueueArn)" \
  '{deadLetterTargetArn: $arn, maxReceiveCount: 5}')"
aws sqs set-queue-attributes --queue-url "$orders_queue" \
  --attributes "$(jq -cn --arg policy "$redrive_policy" '{RedrivePolicy: $policy}')"

# Challenge 3: long polling with the maximum wait
aws sqs set-queue-attributes --queue-url "$(stack_output ReconciliationQueueUrl)" \
  --attributes ReceiveMessageWaitTimeSeconds=20
