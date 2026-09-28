# 0005. Automated releases with release-please

- Status: Accepted
- Date: 2026-09-27 (commit `6a05f95`)

## Context

Installed Claude Code plugins update when `.claude-plugin/plugin.json`
changes version. A validator fix once needed a manual bump (0.2.1) to reach
users; manual bumps are easy to forget or get wrong.

## Decision

- release-please on every push to `main` maintains a release PR with the next
  semver version derived from Conventional Commits, the changelog, and the
  `plugin.json` version.
- Merging the release PR tags and publishes the release.
- Nobody edits the version by hand.
- Because PRs opened with `GITHUB_TOKEN` do not trigger workflows, the release
  workflow starts CI on the release branch with `workflow_dispatch`.

## Consequences

- Commit messages are release inputs; a wrong type produces a wrong version.
- `docs:`, `test:`, `ci:` and `chore:` do not ship a release on their own, so
  a fix that must reach users needs a `fix:` or `feat:` commit.
- While below 1.0, breaking changes bump the minor version.
