#!/usr/bin/env bash
# Creates a lab skeleton from the skill assets.
# Usage: bash new_lab.sh <CERT-CODE> <slug> [--docs-only] [--root <labs-dir>]
#   CERT-CODE: exam code as in the exam guide, e.g. SAA-C03, SOA-C03, DVA-C02
#   slug:      kebab-case topic, e.g. s3-replicacao-versionamento
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
usage="usage: bash new_lab.sh <CERT-CODE> <slug> [--docs-only] [--root <labs-dir>]"

cert="${1:?$usage}"
slug="${2:?$usage}"
shift 2
kind="lab"
root="labs"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --docs-only) kind="docs-only"; shift ;;
    --root) root="${2:?$usage}"; shift 2 ;;
    *) echo "$usage" >&2; exit 64 ;;
  esac
done

[[ "$cert" =~ ^[A-Z]{3}-C[0-9]{2}$ ]] || { echo "invalid CERT-CODE '$cert' (expected e.g. SAA-C03)" >&2; exit 64; }
[[ "$slug" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || { echo "invalid slug '$slug' (expected kebab-case)" >&2; exit 64; }

lab_dir="$root/$cert/$slug"
[[ -e "$lab_dir" ]] && { echo "$lab_dir already exists; pick another slug" >&2; exit 73; }

mkdir -p "$lab_dir"
cp -R "$SKILL_DIR/assets/$kind/." "$lab_dir/"

stack_name="lab-$(tr '[:upper:]' '[:lower:]' <<<"$cert")-$slug"
stack_name="${stack_name:0:128}"
find "$lab_dir" -type f -exec sed -i.bak \
  -e "s|{{CERT}}|$cert|g" \
  -e "s|{{STACK_NAME}}|$stack_name|g" {} +
find "$lab_dir" -name '*.bak' -delete

echo "$lab_dir"
