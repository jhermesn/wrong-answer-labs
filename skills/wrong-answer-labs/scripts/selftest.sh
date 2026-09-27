#!/usr/bin/env bash
# End-to-end test of a lab in a real AWS account. Creates billable resources
# for a few minutes and always deletes them at the end.
#   0. validate_lab.sh must pass  -> nothing unvalidated reaches the account
#   1. deploy template.yaml       -> refuses to touch a stack that already exists
#   2. check.sh must score 0/N    -> challenges are not pre-solved by the template
#   3. run solution/solve.sh
#   4. check.sh must score N/N    -> the reference solution satisfies the grader
#   5. cleanup.sh (always, through an EXIT trap)
# Usage: bash selftest.sh <lab-dir> [region]
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
lab_dir="$(cd "${1:?usage: bash selftest.sh <lab-dir> [region]}" && pwd)"
export AWS_REGION="${2:-${AWS_REGION:-us-east-1}}"
stack="$(sed -n 's/.*--stack-name \(lab-[a-z0-9-]*\).*/\1/p' "$lab_dir/README.md" | head -1)"
[[ -n "$stack" ]] || { echo "could not read the stack name from README.md"; exit 65; }
cert="$(basename "$(dirname "$lab_dir")")"

echo "--- validate"
bash "$SKILL_DIR/scripts/validate_lab.sh" "$lab_dir" --offline >/dev/null \
  || { echo "SELFTEST ABORTED: validate_lab.sh fails; run it on $lab_dir and fix the lab first"; exit 1; }

# The cleanup trap deletes the stack, so never adopt one that was already there
# (for example a learner's own copy of this lab).
if aws cloudformation describe-stacks --stack-name "$stack" >/dev/null 2>&1; then
  echo "SELFTEST ABORTED: stack $stack already exists in $AWS_REGION; delete it or use another region"
  exit 1
fi

cd "$lab_dir"
trap 'echo "--- cleanup"; bash cleanup.sh "$stack" || echo "CLEANUP FAILED: delete stack $stack manually"' EXIT

echo "--- deploy $stack ($AWS_REGION)"
aws cloudformation deploy --template-file template.yaml --stack-name "$stack" \
  --capabilities CAPABILITY_NAMED_IAM --tags project=exam-labs cert="$cert" lab="$stack"

echo "--- baseline: every check must fail"
baseline="$(bash check.sh "$stack" || true)"
echo "$baseline"
grep -q '^Score: 0/' <<<"$baseline" || { echo "SELFTEST FAIL: a check passes before any challenge is solved"; exit 1; }

echo "--- apply reference solution"
bash solution/solve.sh "$stack"

echo "--- solved: every check must pass"
DEBUG=1 bash check.sh "$stack" || { echo "SELFTEST FAIL: the reference solution does not satisfy the grader"; exit 1; }

echo "SELFTEST PASS"
