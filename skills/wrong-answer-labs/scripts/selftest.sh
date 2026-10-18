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
# Set WAL_RUN_LOG=<file> to append one JSON line per run (needs jq).
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
lab_dir="$(cd "${1:?usage: bash selftest.sh <lab-dir> [region]}" && pwd)"
export AWS_REGION="${2:-${AWS_REGION:-us-east-1}}"
stack="$(sed -n 's/.*--stack-name \(lab-[a-z0-9-]*\).*/\1/p' "$lab_dir/README.md" | head -1)"
[[ -n "$stack" ]] || { echo "could not read the stack name from README.md"; exit 65; }
cert="$(basename "$(dirname "$lab_dir")")"
if [[ -n "${WAL_RUN_LOG:-}" ]] && ! command -v jq >/dev/null; then
  echo "missing tool: jq (install: brew install jq)"
  exit 69
fi

# Run record for WAL_RUN_LOG. `result` stays ERROR when a command fails under
# `set -e` (for example the deploy); the logged `phase` says where it stopped.
started_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
result="ERROR"
phase="validate"
deployed=0
cleanup_ok=null
baseline_score=""
solved_score=""
phase_seconds=""

# Appends "<phase>=<seconds>" for the phase that just ended and starts the next one.
start_phase() {
  phase_seconds+="$phase=$((SECONDS - phase_started)) "
  phase="$1"
  phase_started=$SECONDS
}
phase_started=$SECONDS

score_of() { sed -n 's/^Score: \([0-9]*\/[0-9]*\).*/\1/p' <<<"$1" | tail -1; }

write_run_log() {
  [[ -n "${WAL_RUN_LOG:-}" ]] || return 0
  jq -nc --arg lab "$lab_dir" --arg stack "$stack" --arg region "$AWS_REGION" \
    --arg started_at "$started_at" --arg result "$result" --arg phase "$stopped_in" \
    --arg baseline "$baseline_score" --arg solved "$solved_score" \
    --arg phases "$phase_seconds" --argjson cleanup_ok "$cleanup_ok" --argjson duration_s "$SECONDS" '
    {tool: "selftest", lab: $lab, stack: $stack, region: $region, started_at: $started_at,
     duration_s: $duration_s, result: $result, phase: $phase,
     baseline_score: ($baseline | select(. != "") // null),
     solved_score: ($solved | select(. != "") // null),
     cleanup_ok: $cleanup_ok,
     phase_seconds: ([$phases | splits(" ") | select(. != "") | split("=") | {(.[0]): (.[1] | tonumber)}] | add)}' \
    >>"$WAL_RUN_LOG"
}

on_exit() {
  stopped_in="$phase"
  if [[ "$deployed" -eq 1 ]]; then
    start_phase cleanup
    echo "--- cleanup"
    if bash cleanup.sh "$stack"; then
      cleanup_ok=true
    else
      cleanup_ok=false
      echo "CLEANUP FAILED: delete stack $stack manually"
    fi
  fi
  start_phase end
  write_run_log
}
trap on_exit EXIT

echo "--- validate"
bash "$SKILL_DIR/scripts/validate_lab.sh" "$lab_dir" --offline >/dev/null || {
  result="ABORTED_INVALID_LAB"
  echo "SELFTEST ABORTED: validate_lab.sh fails; run it on $lab_dir and fix the lab first"
  exit 1
}

# The cleanup trap deletes the stack, so never adopt one that was already there
# (for example a learner's own copy of this lab).
if aws cloudformation describe-stacks --stack-name "$stack" >/dev/null 2>&1; then
  result="ABORTED_STACK_EXISTS"
  echo "SELFTEST ABORTED: stack $stack already exists in $AWS_REGION; delete it or use another region"
  exit 1
fi

cd "$lab_dir"
deployed=1

start_phase deploy
echo "--- deploy $stack ($AWS_REGION)"
aws cloudformation deploy --template-file template.yaml --stack-name "$stack" \
  --capabilities CAPABILITY_NAMED_IAM --tags project=exam-labs cert="$cert" lab="$stack"

start_phase baseline
echo "--- baseline: every check must fail"
baseline="$(bash check.sh "$stack" || true)"
echo "$baseline"
baseline_score="$(score_of "$baseline")"
grep -q '^Score: 0/' <<<"$baseline" || {
  result="FAIL_BASELINE"
  echo "SELFTEST FAIL: a check passes before any challenge is solved"
  exit 1
}

start_phase solve
echo "--- apply reference solution"
bash solution/solve.sh "$stack"

start_phase solved
echo "--- solved: every check must pass"
solved_ok=1
solved="$(DEBUG=1 bash check.sh "$stack")" || solved_ok=0
echo "$solved"
solved_score="$(score_of "$solved")"
[[ "$solved_ok" -eq 1 ]] || {
  result="FAIL_SOLVED"
  echo "SELFTEST FAIL: the reference solution does not satisfy the grader"
  exit 1
}

result="PASS"
echo "SELFTEST PASS"
