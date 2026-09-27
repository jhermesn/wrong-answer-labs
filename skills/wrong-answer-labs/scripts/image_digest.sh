#!/usr/bin/env bash
# Resolves a container image tag on Amazon ECR Public to an immutable digest
# reference, for templates that must pin images (tags can be moved).
# No AWS credentials needed.
#
# Usage: bash image_digest.sh public.ecr.aws/<repository>:<tag>
#   bash image_digest.sh public.ecr.aws/docker/library/nginx:1.27-alpine
#   -> public.ecr.aws/docker/library/nginx@sha256:...
#
# Only Amazon ECR Public is supported: it hosts the official Docker images
# (public.ecr.aws/docker/library/...) and AWS's own images without the pull
# rate limits of other public registries.
set -euo pipefail

usage="usage: bash image_digest.sh public.ecr.aws/<repository>:<tag>"
image="${1:?$usage}"

[[ "$image" =~ ^public\.ecr\.aws/([a-z0-9._/-]+):([A-Za-z0-9._-]+)$ ]] \
  || { echo "expected public.ecr.aws/<repository>:<tag>, got '$image'" >&2; exit 64; }
repository="${BASH_REMATCH[1]}"
tag="${BASH_REMATCH[2]}"

token="$(curl -sf --max-time 20 https://public.ecr.aws/token/ | jq -r .token)" \
  || { echo "could not get an anonymous token from public.ecr.aws" >&2; exit 1; }
headers="$(curl -sI --max-time 20 -H "Authorization: Bearer $token" \
  -H "Accept: application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.list.v2+json, application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json" \
  "https://public.ecr.aws/v2/$repository/manifests/$tag")"

status="$(head -1 <<<"$headers" | awk '{ print $2 }')"
digest="$(grep -i '^docker-content-digest:' <<<"$headers" | awk '{ print $2 }' | tr -d '\r' || true)"
if [[ "$status" != "200" || ! "$digest" =~ ^sha256:[0-9a-f]{64}$ ]]; then
  echo "could not resolve $image (HTTP $status); check the repository and tag on https://gallery.ecr.aws" >&2
  exit 1
fi
echo "public.ecr.aws/$repository@$digest"
