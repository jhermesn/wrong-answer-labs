# 0004. Container images from Amazon ECR Public, pinned by digest

- Status: Accepted
- Date: 2026-09-27 (commit `5ebbec6`)

## Context

A Fargate lab in the first real run pinned its image by tag. Tags can be
moved to different content, so the image a learner runs could differ from the
one that passed review. Templates also cannot build or push images, and
handwritten apps add maintenance and risk.

## Decision

- Order of preference when a scenario needs something running: no app →
  OS packages in `UserData` → official Amazon ECR Public image → inline glue
  under ~30 lines.
- `SEC_CONTAINER_IMAGE_PINNED` requires `@sha256:<digest>` on every ECS
  container image.
- `image_digest.sh` resolves an ECR Public tag to a digest anonymously.
  Only `public.ecr.aws` is supported: it hosts the Docker official images and
  AWS images without the pull rate limits of other public registries.

## Consequences

- Deployed images are immutable and reproducible.
- Pinned digests go stale and will not receive security fixes; labs are
  short-lived, so this is accepted.
- Images outside ECR Public need a different resolution path before they can
  be used.
