# 0006. Release pull requests use a GitHub App token

- Status: Accepted
- Date: 2026-11-23
- Supersedes: the `workflow_dispatch` part of [0005](0005-automated-releases.md)

## Context

ADR 0005 started CI on the release branch with `workflow_dispatch`, because
pull requests opened with `GITHUB_TOKEN` do not start workflows. GitHub now
creates the `pull_request` run for such a pull request but holds it in
`action_required` until a maintainer approves it. The dispatched run passed,
yet the pull request still showed no checks and stayed blocked, so every
release needed a manual approval.

## Decision

- `release.yml` creates a short-lived token from a GitHub App installed on the
  repository and passes it to release-please. `GITHUB_TOKEN` gets no
  permissions in that workflow.
- `ci.yml` drops the `workflow_dispatch` trigger it kept for release branches.

## Consequences

- The release pull request gets its `test` check from a normal
  `pull_request` run, with no manual step.
- The repository depends on the App's client ID (variable
  `AUTOMATION_APP_CLIENT_ID`) and private key (secret
  `AUTOMATION_APP_PRIVATE_KEY`). Rotating the key means generating a new one in
  the App settings and replacing the secret.
- Tags and releases created by the App can trigger workflows, which
  `GITHUB_TOKEN` events could not.
