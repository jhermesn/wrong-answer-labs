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

# {{SOLUTION_COMMANDS}}
