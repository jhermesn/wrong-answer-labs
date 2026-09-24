#!/usr/bin/env bash
# Regression tests for the skill tooling:
# - each guard fixture must fail exactly the rules listed in its .expected file
#   (empty file = must pass everything)
# - every example lab must pass validate_lab.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_DIR="$REPO_DIR/skills/aws-exam-questions-to-labs"
FIXTURES="$REPO_DIR/tests/fixtures"
failures=0

for template in "$FIXTURES"/*.yaml; do
  name="$(basename "$template" .yaml)"
  actual="$({ cfn-guard validate -d "$template" -r "$SKILL_DIR/rules" --show-summary fail 2>&1 || true; } \
    | sed -n 's|^lab-[a-z]*\.guard/\([A-Z0-9_]*\) .*FAIL$|\1|p' | sort -u)"
  expected="$(sort -u "$FIXTURES/$name.expected")"
  if [[ "$actual" == "$expected" ]]; then
    echo "PASS $name"
  else
    echo "FAIL $name"
    diff <(echo "$expected") <(echo "$actual") | sed 's/^/    /' || true
    failures=$((failures + 1))
  fi
done

cfn-lint --non-zero-exit-code warning "$FIXTURES/good.yaml" && echo "PASS good.yaml cfn-lint"

for example in "$SKILL_DIR"/examples/*/*/; do
  if bash "$SKILL_DIR/scripts/validate_lab.sh" "$example" --offline >/dev/null; then
    echo "PASS example ${example#"$SKILL_DIR"/}"
  else
    echo "FAIL example ${example#"$SKILL_DIR"/} (run validate_lab.sh on it)"
    failures=$((failures + 1))
  fi
done

exit "$failures"
