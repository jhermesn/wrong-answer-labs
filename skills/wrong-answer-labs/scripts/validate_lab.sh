#!/usr/bin/env bash
# Static quality gate for a generated lab. Needs no AWS credentials.
# Usage: bash validate_lab.sh <lab-dir> [--offline]
#   --offline  skip the HTTP check of documentation links
#
# Structure is checked through HTML comment anchors (<!-- section:... -->,
# <!-- challenge:N -->, <!-- solution:N -->, <!-- question:QN -->) so headings
# can be written in any language.
set -uo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
lab_dir="${1:?usage: bash validate_lab.sh <lab-dir> [--offline]}"
offline="${2:-}"
errors=0

fail() { echo "  ✗ $*"; errors=$((errors + 1)); }
ok() { echo "  ✓ $*"; }
section() { printf '\n== %s ==\n' "$1"; }

require_tool() {
  command -v "$1" >/dev/null || { echo "missing tool: $1 (install: $2)"; exit 69; }
}

has_anchor() { grep -qF "<!-- $2 -->" "$1" 2>/dev/null; }

count_anchors() { grep -cE "^<!-- $2:[A-Za-z0-9]+ -->$" "$1" 2>/dev/null; }

[[ -d "$lab_dir" ]] || { echo "not a directory: $lab_dir"; exit 66; }
if [[ -f "$lab_dir/template.yaml" ]]; then kind="lab"; else kind="docs-only"; fi
echo "Validating $kind: $lab_dir"

section "Files and sections"
if [[ "$kind" == "lab" ]]; then
  required_files=(README.md template.yaml check.sh cleanup.sh solution/README.md solution/solve.sh)
  required_sections=(scenario objectives before-you-start cost deploy challenges verify cleanup references)
  answers_file="$lab_dir/solution/README.md"
else
  required_files=(README.md)
  required_sections=(why-no-lab concepts references cheap-practice answers)
  answers_file="$lab_dir/README.md"
fi
for file in "${required_files[@]}"; do
  if [[ -s "$lab_dir/$file" ]]; then ok "$file"; else fail "$file missing or empty"; fi
done
for anchor in "${required_sections[@]}"; do
  has_anchor "$lab_dir/README.md" "section:$anchor" || fail "README.md lacks <!-- section:$anchor -->"
done

leftovers="$(grep -rnE '\{\{[A-Z_]+\}\}' "$lab_dir" 2>/dev/null)"
if [[ -z "$leftovers" ]]; then
  ok "no template placeholders left"
else
  fail "unfilled placeholders:"
  echo "$leftovers" | sed 's/^/      /'
fi

question_count="$(count_anchors "$answers_file" question)"
if [[ "${question_count:-0}" -ge 1 ]]; then
  ok "$question_count source question(s) explained"
else
  fail "no <!-- question:Q<n> --> blocks in ${answers_file#"$lab_dir"/}"
fi

if [[ "$kind" == "lab" ]]; then
  section "Challenges vs grader vs solution"
  challenge_count="$(count_anchors "$lab_dir/README.md" challenge)"
  challenge_count="${challenge_count:-0}"
  if [[ "$challenge_count" -lt 1 || "$challenge_count" -gt 5 ]]; then
    fail "README.md must have 1-5 <!-- challenge:<n> --> blocks (found $challenge_count)"
  fi
  for ((n = 1; n <= challenge_count; n++)); do
    has_anchor "$lab_dir/README.md" "challenge:$n" || fail "challenge numbering has a gap at $n"
    if grep -qE "^check $n " "$lab_dir/check.sh"; then
      ok "challenge $n is graded"
    else
      fail "challenge $n has no 'check $n ...' line in check.sh"
    fi
    has_anchor "$lab_dir/solution/README.md" "solution:$n" || fail "challenge $n has no <!-- solution:$n --> in solution/README.md"
  done
  for graded in $(sed -n 's/^check \([0-9]*\) .*/\1/p' "$lab_dir/check.sh" | sort -un); do
    if [[ "$graded" -lt 1 || "$graded" -gt "$challenge_count" ]]; then
      fail "check.sh grades challenge $graded but README.md has no <!-- challenge:$graded -->"
    fi
  done

  section "Grader is read-only"
  # The grader runs in the learner's account every time they check their score,
  # so it may only read state. Options must come after the operation name.
  write_calls="$(grep -vE '^[[:space:]]*#' "$lab_dir/check.sh" \
    | grep -oE 'aws[[:space:]]+[a-z0-9-]+[[:space:]]+[a-z0-9-]+' | awk '{ print $2 " " $3 }' \
    | grep -vE ' (ls|query|scan|(get|describe|list|head|simulate|lookup|search|filter|batch-get)-[a-z0-9-]+)$' \
    | sort -u)"
  if [[ -z "$write_calls" ]]; then
    ok "check.sh only reads AWS state"
  else
    fail "check.sh calls AWS operations that are not read-only:"
    echo "$write_calls" | sed 's/^/      /'
  fi

  section "cfn-lint"
  require_tool cfn-lint "pipx install cfn-lint"
  if cfn-lint --non-zero-exit-code warning "$lab_dir/template.yaml"; then ok "cfn-lint clean"; else fail "cfn-lint findings above"; fi

  section "cfn-guard (cost + security rules)"
  require_tool cfn-guard "brew install cloudformation-guard"
  if cfn-guard validate -d "$lab_dir/template.yaml" -r "$SKILL_DIR/rules" --show-summary fail; then
    ok "guard rules pass"
  else
    fail "guard violations above"
  fi

  section "checkov (advisory, does not fail the gate)"
  if command -v checkov >/dev/null; then
    checkov -f "$lab_dir/template.yaml" --framework cloudformation --compact --quiet --soft-fail
  else
    echo "  - checkov not installed, skipped (pipx install checkov)"
  fi

  section "shellcheck"
  require_tool shellcheck "brew install shellcheck"
  if shellcheck -S warning "$lab_dir"/*.sh "$lab_dir"/solution/*.sh; then ok "scripts clean"; else fail "shellcheck findings above"; fi
fi

section "Links"
if [[ "$offline" == "--offline" ]]; then
  echo "  - skipped (--offline)"
else
  urls="$(grep -rhoE 'https://[^] )>"`]+' "$lab_dir" --include='*.md' | sed 's/[.,;]$//' | sort -u)"
  [[ -n "$urls" ]] || fail "no documentation links found"
  body_file="$(mktemp)"
  trap 'rm -f "$body_file"' EXIT
  for url in $urls; do
    status="$(curl -s -o "$body_file" -L --max-time 20 -w '%{http_code}' "$url")"
    if [[ ! "$status" =~ ^2 ]]; then
      fail "$status $url"
    # docs.aws.amazon.com answers unknown pages with 200 + a meta refresh to the guide's index.
    elif grep -qi 'http-equiv="refresh"' "$body_file"; then
      fail "soft 404 (meta refresh) $url"
    else
      ok "$status $url"
    fi
  done
fi

section "Result"
if [[ "$errors" -eq 0 ]]; then echo "PASS"; else echo "FAIL ($errors problem(s))"; fi
exit $((errors > 0))
