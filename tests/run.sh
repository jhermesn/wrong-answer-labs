#!/usr/bin/env bash
# Test suite for the skill tooling. CI runs it on every pull request.
#   1. every resource type named in the guard rules exists in CloudFormation
#   2. guard rule unit tests (tests/rules/<rules>.test.yaml) and their coverage
#   3. validate_lab.sh accepts the examples and rejects broken labs
#   4. new_lab.sh scaffolds labs and rejects bad input
#   5. price.sh and image_digest.sh reject bad input
#   6. selftest.sh refuses to deploy unvalidated labs or adopt existing stacks
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_DIR="$REPO_DIR/skills/wrong-answer-labs"
RULES_DIR="$SKILL_DIR/rules"
RULE_TESTS_DIR="$REPO_DIR/tests/rules"
VALIDATE="$SKILL_DIR/scripts/validate_lab.sh"
NEW_LAB="$SKILL_DIR/scripts/new_lab.sh"
EXAMPLE_LAB="$SKILL_DIR/examples/SAA-C03/s3-accidental-delete"
EXAMPLE_DOCS="$SKILL_DIR/examples/SAA-C03/direct-connect-resiliency"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
failures=0

pass() { echo "  PASS $*"; }
fail() { echo "  FAIL $*"; failures=$((failures + 1)); }
suite() { printf '\n== %s ==\n' "$1"; }

# --- 1. resource types ------------------------------------------------------

check_rule_resource_types_exist() {
  local template="$WORK_DIR/rule-types.yaml" unknown
  {
    echo "Resources:"
    grep -ohE "'AWS::[A-Za-z0-9]+::[A-Za-z0-9]+'" "$RULES_DIR"/*.guard | tr -d "'" | sort -u \
      | awk '{ printf "  R%d:\n    Type: %s\n", NR, $0 }'
  } >"$template"
  # Only E3006 (unknown type) matters; the resources have no properties on purpose.
  unknown="$(cfn-lint "$template" 2>&1 | grep E3006)"
  if [[ -z "$unknown" ]]; then
    pass "every resource type in the rules exists"
  else
    fail "unknown resource types in the rules:"
    echo "$unknown" | sed 's/^/      /'
  fi
}

# --- 2. guard rules ---------------------------------------------------------

check_rule_tests() {
  local rules="$1" name tests output
  name="$(basename "$rules" .guard)"
  tests="$RULE_TESTS_DIR/$name.test.yaml"
  if [[ ! -f "$tests" ]]; then
    fail "$name has no test file at tests/rules/$name.test.yaml"
    return
  fi
  if output="$(cfn-guard test -r "$rules" -t "$tests" 2>&1)"; then
    pass "$name: $(grep -c '^Test Case' <<<"$output") cases"
  else
    fail "$name:"
    grep -v 'No Test expectation' <<<"$output" | grep -B3 -A1 'FAIL Rules' | sed 's/^/      /'
  fi
}

# Every rule needs a case that makes it fail and one where it does not, so a
# rule whose filter never matches anything cannot pass unnoticed.
check_rule_coverage() {
  local rules="$1" name tests rule
  name="$(basename "$rules" .guard)"
  tests="$RULE_TESTS_DIR/$name.test.yaml"
  [[ -f "$tests" ]] || return
  for rule in $(sed -n 's/^rule \([A-Z0-9_]*\).*/\1/p' "$rules"); do
    grep -q "$rule: FAIL" "$tests" || fail "$rule has no FAIL case"
    grep -qE "$rule: (PASS|SKIP)" "$tests" || fail "$rule has no PASS or SKIP case"
  done
}

# --- 3. validate_lab.sh -----------------------------------------------------

expect_valid() {
  local lab="$1"
  if bash "$VALIDATE" "$lab" --offline >/dev/null 2>&1; then
    pass "accepts ${lab#"$SKILL_DIR"/}"
  else
    fail "rejects ${lab#"$SKILL_DIR"/} (run validate_lab.sh on it)"
  fi
}

# expect_rejected <case name> <source lab> <expected message> <shell code that breaks the copy>
expect_rejected() {
  local case_name="$1" source="$2" message="$3" breakage="$4"
  local lab="$WORK_DIR/$case_name" output
  cp -R "$source" "$lab"
  (cd "$lab" && eval "$breakage")
  if output="$(bash "$VALIDATE" "$lab" --offline 2>&1)"; then
    fail "$case_name: lab was accepted"
  elif grep -qF -- "$message" <<<"$output"; then
    pass "rejects $case_name"
  else
    fail "$case_name: rejected without '$message'"
  fi
}

# --- 4. new_lab.sh ----------------------------------------------------------

expect_exit() {
  local description="$1" expected="$2" actual
  shift 2
  "$@" >/dev/null 2>&1
  actual=$?
  if [[ "$actual" -eq "$expected" ]]; then
    pass "$description"
  else
    fail "$description (exit $actual, expected $expected)"
  fi
}

# --- 6. selftest.sh safeguards ----------------------------------------------

# A fake `aws` that records every call. describe-stacks succeeds only when
# STACK_EXISTS=1, so the "stack already exists" guard can be exercised.
install_fake_aws() {
  mkdir -p "$WORK_DIR/bin"
  cat >"$WORK_DIR/bin/aws" <<'EOF'
#!/usr/bin/env bash
# `aws ... help` makes no API call; validate_lab.sh uses it to check commands exist.
[[ "${!#}" == "help" ]] && exit 0
echo "$*" >>"$AWS_CALLS"
[[ "$1 $2" == "cloudformation describe-stacks" && "${STACK_EXISTS:-0}" == "1" ]] && exit 0
exit 1
EOF
  chmod +x "$WORK_DIR/bin/aws"
}

# expect_selftest_aborts <description> <lab> <expected message> <stack exists: 0|1> <allowed aws calls regex>
expect_selftest_aborts() {
  local description="$1" lab="$2" message="$3" stack_exists="$4" allowed_calls="$5" output
  export AWS_CALLS="$WORK_DIR/aws-calls-$RANDOM"
  : >"$AWS_CALLS"
  if output="$(PATH="$WORK_DIR/bin:$PATH" STACK_EXISTS="$stack_exists" bash "$SKILL_DIR/scripts/selftest.sh" "$lab" 2>&1)"; then
    fail "$description: self-test ran to completion"
  elif ! grep -qF -- "$message" <<<"$output"; then
    fail "$description: aborted without '$message'"
  elif grep -vqE "$allowed_calls" "$AWS_CALLS"; then
    fail "$description: unexpected AWS calls: $(tr '\n' ';' <"$AWS_CALLS")"
  else
    pass "$description"
  fi
}

# --- run --------------------------------------------------------------------

suite "Resource types"
check_rule_resource_types_exist

suite "Guard rules"
for rules in "$RULES_DIR"/*.guard; do
  check_rule_tests "$rules"
  check_rule_coverage "$rules"
done

suite "validate_lab.sh"
for example in "$SKILL_DIR"/examples/*/*/; do
  expect_valid "${example%/}"
done
expect_rejected leftover-placeholder "$EXAMPLE_LAB" "unfilled placeholders" \
  "echo '{{TITLE}}' >> README.md"
expect_rejected missing-section "$EXAMPLE_LAB" "README.md lacks <!-- section:cleanup -->" \
  "sed -i.bak '/<!-- section:cleanup -->/d' README.md"
expect_rejected ungraded-challenge "$EXAMPLE_LAB" "challenge 2 has no 'check 2 ...' line" \
  "sed -i.bak '/^check 2 /,/^$/d' check.sh"
expect_rejected check-for-unknown-challenge "$EXAMPLE_LAB" "check.sh grades challenge 3" \
  "printf 'check 3 \"extra\" \"x\" echo x\n' >> check.sh"
expect_rejected challenge-numbering-gap "$EXAMPLE_LAB" "challenge numbering has a gap at 2" \
  "sed -i.bak 's/<!-- challenge:2 -->/<!-- challenge:3 -->/' README.md"
expect_rejected challenge-without-solution "$EXAMPLE_LAB" "no <!-- solution:2 -->" \
  "sed -i.bak '/<!-- solution:2 -->/d' solution/README.md"
expect_rejected lab-without-questions "$EXAMPLE_LAB" "no <!-- question:Q<n> --> blocks" \
  "sed -i.bak '/<!-- question:/d' solution/README.md"
expect_rejected retained-resource "$EXAMPLE_LAB" "guard violations" \
  "sed -i.bak 's/DeletionPolicy: Delete/DeletionPolicy: Retain/' template.yaml"
expect_rejected invalid-template "$EXAMPLE_LAB" "cfn-lint findings" \
  "sed -i.bak 's/BucketEncryption:/BucketEncryptionTypo:/' template.yaml"
expect_rejected mutating-grader "$EXAMPLE_LAB" "check.sh calls AWS operations that are not read-only" \
  "printf 'check 1 \"x\" \"y\" aws s3api put-bucket-versioning --bucket b\n' >> check.sh"
if command -v aws >/dev/null; then
  expect_rejected invented-cli-command "$EXAMPLE_LAB" "AWS CLI commands that do not exist" \
    "echo 'aws autoscaling wait group-not-exists --auto-scaling-group-names web-asg || true' >> cleanup.sh"
else
  echo "  SKIP invented-cli-command (AWS CLI not installed)"
fi
expect_rejected unsafe-script "$EXAMPLE_LAB" "shellcheck findings" \
  "echo 'unused_variable=1' >> cleanup.sh"
expect_rejected docs-without-questions "$EXAMPLE_DOCS" "no <!-- question:Q<n> --> blocks" \
  "sed -i.bak '/<!-- question:/d' README.md"

suite "new_lab.sh"
expect_exit "scaffolds a lab" 0 bash "$NEW_LAB" SAA-C03 fresh-lab --root "$WORK_DIR/labs"
expect_rejected fresh-scaffold "$WORK_DIR/labs/SAA-C03/fresh-lab" "unfilled placeholders" ":"
expect_exit "scaffolds a docs-only entry" 0 bash "$NEW_LAB" SAA-C03 fresh-docs --docs-only --root "$WORK_DIR/labs"
if [[ -f "$WORK_DIR/labs/SAA-C03/fresh-docs/README.md" && ! -e "$WORK_DIR/labs/SAA-C03/fresh-docs/template.yaml" ]]; then
  pass "docs-only entry has a README and no template"
else
  fail "docs-only entry layout is wrong"
fi
expect_exit "rejects an existing lab directory" 73 bash "$NEW_LAB" SAA-C03 fresh-lab --root "$WORK_DIR/labs"
expect_exit "rejects a lowercase certification code" 64 bash "$NEW_LAB" saa-c03 x --root "$WORK_DIR/labs"
expect_exit "rejects a slug that is not kebab-case" 64 bash "$NEW_LAB" SAA-C03 Not_Kebab --root "$WORK_DIR/labs"

suite "price.sh"
expect_exit "rejects a missing service code" 1 bash "$SKILL_DIR/scripts/price.sh"
expect_exit "rejects a malformed filter" 64 bash "$SKILL_DIR/scripts/price.sh" AWSQueueService queueType

suite "image_digest.sh"
expect_exit "rejects an image outside Amazon ECR Public" 64 \
  bash "$SKILL_DIR/scripts/image_digest.sh" docker.io/library/nginx:latest
expect_exit "rejects an image without a tag" 64 \
  bash "$SKILL_DIR/scripts/image_digest.sh" public.ecr.aws/docker/library/nginx

suite "selftest.sh (fake AWS CLI)"
install_fake_aws
expect_selftest_aborts "does not touch AWS when the lab fails validation" \
  "$WORK_DIR/retained-resource" "SELFTEST ABORTED: validate_lab.sh fails" 0 '^$'
expect_selftest_aborts "refuses to adopt a stack that already exists" \
  "$EXAMPLE_LAB" "SELFTEST ABORTED: stack" 1 '^cloudformation describe-stacks '

suite "Result"
if [[ "$failures" -eq 0 ]]; then
  echo "PASS"
else
  echo "FAIL ($failures)"
fi
[[ "$failures" -eq 0 ]]
