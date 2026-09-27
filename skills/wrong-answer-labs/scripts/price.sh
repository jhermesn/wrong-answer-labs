#!/usr/bin/env bash
# Prints on-demand prices from the AWS Price List API. Needs AWS credentials
# (the API is free). Pricing web pages fill prices in with JavaScript, so a
# plain fetch of them often shows no numbers; use this instead.
#
# Usage: bash price.sh <service-code> [Field=Value ...]
#   bash price.sh AWSQueueService queueType=Standard
#   bash price.sh AmazonEC2 instanceType=t3.micro operatingSystem=Linux tenancy=Shared preInstalledSw=NA capacitystatus=Used
# regionCode defaults to us-east-1. Service codes are not guessable (SQS is
# AWSQueueService); list them, then a service's filterable fields, with:
#   aws pricing describe-services --region us-east-1 --query 'Services[].ServiceCode'
#   aws pricing describe-services --region us-east-1 --service-code <service-code>
set -euo pipefail

usage="usage: bash price.sh <service-code> [Field=Value ...]"
service_code="${1:?$usage}"
shift

filters=()
has_region=0
for pair in "$@"; do
  [[ "$pair" == *=* ]] || { echo "invalid filter '$pair' (expected Field=Value)" >&2; exit 64; }
  [[ "${pair%%=*}" == "regionCode" ]] && has_region=1
  filters+=("Type=TERM_MATCH,Field=${pair%%=*},Value=${pair#*=}")
done
[[ "$has_region" -eq 1 ]] || filters+=("Type=TERM_MATCH,Field=regionCode,Value=us-east-1")

# The Price List API is served from us-east-1 whatever region is being priced.
prices="$(aws pricing get-products --region us-east-1 --service-code "$service_code" \
  --filters "${filters[@]}" --output json \
  | jq -r '.PriceList[] | fromjson | .terms.OnDemand // {} | .[].priceDimensions[]
      | select((.pricePerUnit.USD | tonumber) > 0)
      | "USD \(.pricePerUnit.USD) per \(.unit) | \(.description)"' \
  | sort -u)"

if [[ -z "$prices" ]]; then
  echo "no on-demand prices matched; loosen the filters or check field names with describe-services" >&2
  exit 1
fi
echo "$prices"
