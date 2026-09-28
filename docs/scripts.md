# Scripts reference

All scripts are bash, live in `skills/wrong-answer-labs/scripts/` (skill
tooling) or inside each lab (learner tooling), and pass `shellcheck -S warning`.

## Skill tooling

| Script | Needs AWS credentials | Network | Writes to AWS |
|---|---|---|---|
| `new_lab.sh` | No | No | No |
| `validate_lab.sh` | No | Yes, unless `--offline` | No |
| `selftest.sh` | Yes | Yes | **Yes** (creates and deletes the lab stack) |
| `price.sh` | Yes | Yes | No (Price List API, free) |
| `image_digest.sh` | No (anonymous token) | Yes | No |

A missing required argument exits 1 with the usage line; exit 64 means a
malformed argument.

### `new_lab.sh`

```bash
bash new_lab.sh <CERT-CODE> <slug> [--docs-only] [--root <labs-dir>]
```

Copies `assets/lab/` (or `assets/docs-only/`) to `<root>/<CERT>/<slug>/`
(default root `labs`), replaces `{{CERT}}` and `{{STACK_NAME}}`, and prints
the lab directory. All other placeholders are left for the agent.

| Input | Constraint |
|---|---|
| `CERT-CODE` | `^[A-Z]{3}-C[0-9]{2}$`, e.g. `SAA-C03` |
| `slug` | kebab-case, `^[a-z0-9]+(-[a-z0-9]+)*$` |
| Stack name | `lab-<cert-lowercase>-<slug>`, truncated to 128 chars |

| Exit | Meaning |
|---|---|
| 0 | Created |
| 1 | Missing `CERT-CODE` or `slug` |
| 64 | Unknown option, invalid cert code or slug |
| 73 | Target directory already exists |

### `validate_lab.sh`

```bash
bash validate_lab.sh <lab-dir> [--offline]
```

Runs the static gate described in [guardrails.md](guardrails.md). Detects a lab
by `template.yaml`; otherwise treats the directory as docs-only. Prints `✓`/`✗`
per check and ends with `PASS` or `FAIL (<n> problem(s))`.

Requires `cfn-lint`, `cfn-guard`, `shellcheck`, `curl` (links) and optionally
`aws` (command existence) and `checkov` (advisory).

| Exit | Meaning |
|---|---|
| 0 | `PASS` |
| 1 | One or more problems, or missing `<lab-dir>` |
| 66 | Not a directory |
| 69 | Required tool missing (message includes the install command) |

### `selftest.sh`

```bash
bash selftest.sh <lab-dir> [region]
```

Region defaults to `AWS_REGION`, then `us-east-1`. Reads the stack name from
the README deploy command. Steps: offline validation → refuse an existing
stack → deploy (`CAPABILITY_NAMED_IAM`, standard tags) → baseline must be
`Score: 0/N` → `solution/solve.sh` → `check.sh` must pass (with `DEBUG=1`) →
`cleanup.sh` via `EXIT` trap, always.

| Exit / output | Meaning |
|---|---|
| 0, `SELFTEST PASS` | Lab works end to end |
| 1, `SELFTEST ABORTED: validate_lab.sh fails` | No AWS call was made |
| 1, `SELFTEST ABORTED: stack ... already exists` | Only `describe-stacks` was called |
| 1, `SELFTEST FAIL: a check passes before ...` | Template pre-solves a challenge |
| 1, `SELFTEST FAIL: the reference solution ...` | `solve.sh` does not satisfy the grader |
| 65 | Stack name not found in README |
| `CLEANUP FAILED: delete stack ... manually` | Teardown failed; delete the stack by hand |

### `price.sh`

```bash
bash price.sh <service-code> [Field=Value ...]
bash price.sh AWSQueueService queueType=Standard
bash price.sh AmazonEC2 instanceType=t3.micro operatingSystem=Linux tenancy=Shared preInstalledSw=NA capacitystatus=Used
```

Queries `aws pricing get-products` (always in `us-east-1`, where the API is
served) with `TERM_MATCH` filters and prints non-zero on-demand price
dimensions as `USD <price> per <unit> | <description>`. Adds
`regionCode=us-east-1` unless a `regionCode` filter is given. Exists because
pricing web pages render prices with JavaScript, so fetching them yields no
numbers.

Service codes are not guessable; discover them with
`aws pricing describe-services --region us-east-1`.

| Exit | Meaning |
|---|---|
| 0 | Prices printed |
| 1 | Missing service code, or no prices matched |
| 64 | Filter not in `Field=Value` form |

### `image_digest.sh`

```bash
bash image_digest.sh public.ecr.aws/<repository>:<tag>
# -> public.ecr.aws/<repository>@sha256:<64 hex>
```

Gets an anonymous token from `public.ecr.aws`, sends a `HEAD` for the manifest
(OCI index, Docker manifest list, or single manifest), and prints the
digest-pinned reference required by `SEC_CONTAINER_IMAGE_PINNED`. Only Amazon
ECR Public is supported ([ADR 0004](decisions/0004-digest-pinned-ecr-public-images.md)).

| Exit | Meaning |
|---|---|
| 0 | Reference printed |
| 1 | Missing argument, or token/manifest lookup failed |
| 64 | Not a `public.ecr.aws/<repo>:<tag>` reference |

## Lab tooling

Every lab ships these, generated from `assets/lab/`. All accept
`<stack-name> [region]` (region: argument, then `AWS_REGION`, then `us-east-1`).

| Script | Does | Exit |
|---|---|---|
| `check.sh` | Grades each acceptance criterion; prints ✅/❌ and `Score: P/T`. `DEBUG=1` prints expected vs actual | 0 all pass, 1 otherwise, 2 stack not found |
| `cleanup.sh` | Deletes challenge-created resources, empties stack buckets (all versions), deletes the stack and waits | non-zero on failure (`set -e`) |
| `solution/solve.sh` | Applies the reference solution via the CLI | non-zero on failure (`set -e`) |

Both `check.sh` and `solve.sh` define `stack_output <OutputKey>` and
`stack_resource <LogicalId>` helpers.
