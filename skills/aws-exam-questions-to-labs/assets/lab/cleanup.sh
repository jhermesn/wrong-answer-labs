#!/usr/bin/env bash
# Deletes everything this lab created, including resources made during the challenges.
# Usage: bash cleanup.sh <stack-name> [region]
set -euo pipefail

STACK="${1:?usage: bash cleanup.sh <stack-name> [region]}"
export AWS_REGION="${2:-${AWS_REGION:-us-east-1}}"

empty_bucket() {
  local bucket="$1" batch
  echo "Emptying s3://$bucket (all object versions)..."
  while :; do
    batch="$(aws s3api list-object-versions --bucket "$bucket" --max-items 1000 --output json \
      | jq '{Objects: [(.Versions // [])[], (.DeleteMarkers // [])[] | {Key, VersionId}], Quiet: true}')"
    [[ "$(jq '.Objects | length' <<<"$batch")" -eq 0 ]] && break
    aws s3api delete-objects --bucket "$bucket" --delete "$batch" >/dev/null
  done
}

# {{CHALLENGE_CLEANUP}}

for bucket in $(aws cloudformation list-stack-resources --stack-name "$STACK" \
  --query "StackResourceSummaries[?ResourceType=='AWS::S3::Bucket'].PhysicalResourceId" --output text); do
  empty_bucket "$bucket"
done

echo "Deleting stack $STACK..."
aws cloudformation delete-stack --stack-name "$STACK"
aws cloudformation wait stack-delete-complete --stack-name "$STACK"
echo "Done. Nothing from this lab is billing anymore."
