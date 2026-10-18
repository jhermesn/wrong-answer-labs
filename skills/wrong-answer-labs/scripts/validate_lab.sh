#!/usr/bin/env bash
# Static quality gate for a generated lab. Needs no AWS credentials.
# Usage: bash validate_lab.sh <lab-dir> [--offline]
#   --offline  skip the HTTP check of documentation links
# Set WAL_RUN_LOG=<file> to append one JSON line per run (needs jq).
#
# Structure is checked through HTML comment anchors (<!-- section:... -->,
# <!-- challenge:N -->, <!-- solution:N -->, <!-- question:QN -->) so headings
# can be written in any language.
set -uo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
lab_dir="${1:?usage: bash validate_lab.sh <lab-dir> [--offline]}"
offline="${2:-}"
errors=0
started_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
stage=""
# One "<stage>\t<event>\t<message>" line per stage, failure or skip, for WAL_RUN_LOG.
events=""

record() { events+="$stage"$'\t'"$1"$'\t'"$2"$'\n'; }
fail() { echo "  ✗ $*"; errors=$((errors + 1)); record fail "$*"; }
ok() { echo "  ✓ $*"; }
skip() { echo "  - $*"; record skip "$*"; }
section() { stage="$1"; record start "$2"; printf '\n== %s ==\n' "$2"; }

write_run_log() {
  [[ -n "${WAL_RUN_LOG:-}" ]] && command -v jq >/dev/null || return 0
  printf '%s' "$events" | jq -Rsc \
    --arg lab "$lab_path" --arg kind "$kind" --arg started_at "$started_at" \
    --arg result "$1" --argjson problems "$errors" --argjson duration_s "$SECONDS" '
    [split("\n")[] | select(length > 0) | split("\t") | {stage: .[0], event: .[1], message: .[2]}] as $events
    | {tool: "validate_lab", lab: $lab, kind: $kind, started_at: $started_at,
       duration_s: $duration_s, result: $result, problems: $problems,
       stages: [$events[] | select(.event == "start") | .stage as $name
         | [$events[] | select(.stage == $name)] as $own
         | {stage: $name,
            status: (if any($own[]; .event == "fail") then "fail"
                     elif any($own[]; .event == "skip") then "skipped" else "pass" end),
            findings: [$own[] | select(.event == "fail") | .message]}]}' >>"$WAL_RUN_LOG"
}

require_tool() {
  command -v "$1" >/dev/null || { echo "missing tool: $1 (install: $2)"; write_run_log ERROR; exit 69; }
}

has_anchor() { grep -qF "<!-- $2 -->" "$1" 2>/dev/null; }

count_anchors() { grep -cE "^<!-- $2:[A-Za-z0-9]+ -->$" "$1" 2>/dev/null; }

[[ -d "$lab_dir" ]] || { echo "not a directory: $lab_dir"; exit 66; }
lab_path="$(cd "$lab_dir" && pwd)"
if [[ -f "$lab_dir/template.yaml" ]]; then kind="lab"; else kind="docs-only"; fi
[[ -z "${WAL_RUN_LOG:-}" ]] || require_tool jq "brew install jq"
echo "Validating $kind: $lab_dir"

section files "Files and sections"
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
  section challenges "Challenges vs grader vs solution"
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
  # With --output text the AWS CLI prints booleans as True/False, so a check
  # expecting "true" can never pass. Continuation lines are joined first.
  lowercase_booleans="$(awk '{ if (sub(/\\$/, "")) { line = line $0 " "; next } print line $0; line = "" }' "$lab_dir/check.sh" \
    | grep -E '^check [0-9]+ "[^"]*" "(true|false)" .*--output[ =]+text' | cut -d'"' -f2)"
  if [[ -n "$lowercase_booleans" ]]; then
    fail "checks expect lowercase true/false but --output text prints True/False:"
    echo "$lowercase_booleans" | sed 's/^/      /'
  fi

  section grader-read-only "Grader is read-only"
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

  section cli-commands "AWS CLI commands exist"
  # Catches invented operations and waiters (e.g. `aws autoscaling wait ...`,
  # which does not exist) before they fail in a real account.
  if command -v aws >/dev/null; then
    unknown_commands=""
    while read -r service operation waiter; do
      if [[ "$operation" == "wait" ]]; then
        command_words=("$service" wait "$waiter")
      else
        command_words=("$service" "$operation")
      fi
      aws "${command_words[@]}" help >/dev/null 2>&1 || unknown_commands+="aws ${command_words[*]}"$'\n'
    done < <(cat "$lab_dir"/*.sh "$lab_dir"/solution/*.sh | grep -vE '^[[:space:]]*#' \
      | grep -oE 'aws[[:space:]]+[a-z0-9-]+[[:space:]]+[a-z0-9-]+([[:space:]]+[a-z0-9-]+)?' \
      | awk '{ print $2, $3, ($3 == "wait" ? $4 : "") }' | sort -u)
    if [[ -z "$unknown_commands" ]]; then
      ok "every AWS CLI command in the scripts exists"
    else
      fail "AWS CLI commands that do not exist:"
      printf '%s' "$unknown_commands" | sed 's/^/      /'
    fi
  else
    skip "AWS CLI not installed, skipped"
  fi

  section cfn-lint "cfn-lint"
  require_tool cfn-lint "pipx install cfn-lint"
  if cfn-lint --non-zero-exit-code warning "$lab_dir/template.yaml"; then ok "cfn-lint clean"; else fail "cfn-lint findings above"; fi

  section cfn-guard "cfn-guard (cost + security rules)"
  require_tool cfn-guard "brew install cloudformation-guard"
  if cfn-guard validate -d "$lab_dir/template.yaml" -r "$SKILL_DIR/rules" --show-summary fail; then
    ok "guard rules pass"
  else
    fail "guard violations above"
  fi

  section checkov "checkov (advisory, does not fail the gate)"
  if command -v checkov >/dev/null; then
    checkov -f "$lab_dir/template.yaml" --framework cloudformation --compact --quiet --soft-fail
  else
    skip "checkov not installed, skipped (pipx install checkov)"
  fi

  section shellcheck "shellcheck"
  require_tool shellcheck "brew install shellcheck"
  if shellcheck -S warning "$lab_dir"/*.sh "$lab_dir"/solution/*.sh; then ok "scripts clean"; else fail "shellcheck findings above"; fi
fi

section links "Links"
if [[ "$offline" == "--offline" ]]; then
  skip "skipped (--offline)"
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

printf '\n== Result ==\n'
if [[ "$errors" -eq 0 ]]; then
  echo "PASS"
  write_run_log PASS
else
  echo "FAIL ($errors problem(s))"
  write_run_log FAIL
fi
exit $((errors > 0))
