#!/usr/bin/env bash
# Automated grader for this lab.
# Usage: bash check.sh <stack-name> [region]
# DEBUG=1 bash check.sh ... prints expected vs actual value for every check.
set -uo pipefail

STACK="${1:?usage: bash check.sh <stack-name> [region]}"
export AWS_REGION="${2:-${AWS_REGION:-us-east-1}}"
PASS=0
TOTAL=0

stack_output() {
  aws cloudformation describe-stacks --stack-name "$STACK" \
    --query "Stacks[0].Outputs[?OutputKey=='$1'].OutputValue | [0]" --output text
}

stack_resource() {
  aws cloudformation describe-stack-resource --stack-name "$STACK" --logical-resource-id "$1" \
    --query 'StackResourceDetail.PhysicalResourceId' --output text
}

# check <challenge-number> "<description>" "<expected output>" <command...>
# Passes when the command's stdout equals the expected output exactly.
check() {
  local challenge="$1" description="$2" expected="$3" actual
  shift 3
  actual="$("$@" 2>/dev/null)" || actual="<error>"
  TOTAL=$((TOTAL + 1))
  if [[ "$actual" == "$expected" ]]; then
    PASS=$((PASS + 1))
    printf '  ✅ [%s] %s\n' "$challenge" "$description"
  else
    printf '  ❌ [%s] %s\n' "$challenge" "$description"
  fi
  if [[ "${DEBUG:-0}" == "1" ]]; then
    printf '     expected: %s | actual: %s\n' "$expected" "$actual"
  fi
}

aws cloudformation describe-stacks --stack-name "$STACK" >/dev/null \
  || { echo "Stack '$STACK' not found in $AWS_REGION."; exit 2; }

check 1 "Deleted or overwritten reports can be restored" "Enabled" \
  aws s3api get-bucket-versioning --bucket "$(stack_output ReportsBucketName)" \
    --query Status --output text

check 2 "Rule expire-noncurrent-30d is enabled" "Enabled" \
  aws s3api get-bucket-lifecycle-configuration --bucket "$(stack_output ReportsBucketName)" \
    --query "Rules[?ID=='expire-noncurrent-30d'] | [0].Status" --output text

check 2 "Old versions are permanently deleted after 30 days" "30" \
  aws s3api get-bucket-lifecycle-configuration --bucket "$(stack_output ReportsBucketName)" \
    --query "Rules[?ID=='expire-noncurrent-30d'] | [0].NoncurrentVersionExpiration.NoncurrentDays" --output text

printf '\nScore: %d/%d\n' "$PASS" "$TOTAL"
[[ "$TOTAL" -gt 0 && "$PASS" -eq "$TOTAL" ]]
