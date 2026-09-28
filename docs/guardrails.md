# Guardrails

Every lab is written by a model and runs in a learner's account. `validate_lab.sh`
is the static gate between the two: it needs no AWS credentials and must print
`PASS` before a lab is reported or self-tested.

## Validator stages

| Stage | Applies to | Fails when |
|---|---|---|
| Files and sections | Both | A required file is missing/empty, a `section:*` anchor is missing, any `{{PLACEHOLDER}}` remains, or there is no `question:Qn` block |
| Challenges vs grader vs solution | Lab | Not 1–5 `challenge:N` anchors, a numbering gap, a challenge with no `check N` line or no `solution:N`, or a `check N` for a challenge that does not exist |
| Grader is read-only | Lab | `check.sh` calls an AWS operation outside the read-only set |
| AWS CLI commands exist | Lab | Any `aws <service> <operation>` (or `aws <service> wait <waiter>`) in the scripts has no `help` page. Skipped when the AWS CLI is not installed |
| cfn-lint | Lab | Any error or warning (`--non-zero-exit-code warning`) |
| cfn-guard | Lab | Any rule in `rules/*.guard` fails |
| checkov | Lab | Never — advisory only, skipped if not installed |
| shellcheck | Lab | Any finding at severity `warning` or above |
| Links | Both | Any `https://` URL in `*.md` is not 2xx, or is a docs.aws.amazon.com soft 404 (200 with a meta refresh). Skipped with `--offline` |

A missing required tool (`cfn-lint`, `cfn-guard`, `shellcheck`) exits 69 with
the install command, so the agent can tell the learner what to install.

### Grader is read-only

`check.sh` runs in the learner's account every time they check their score, so
it may only read. Allowed operations, matched as `aws <service> <operation>`:

`get-*`, `describe-*`, `list-*`, `head-*`, `simulate-*`, `lookup-*`,
`search-*`, `filter-*`, `batch-get-*`, `query`, `scan`, `ls`.

Global options must come **after** the operation. `aws --region x s3api ...`
is parsed as service `--region`, operation `x` and rejected, which fails
closed rather than open.

## Cost rules (`rules/lab-cost.guard`)

Not suppressible. If a lab needs something these rules deny, it becomes a
docs-only entry ([ADR 0001](decisions/0001-default-deny-cost-gate.md)).

### Allowlist

`COST_ALLOWED_RESOURCE_TYPES` is **default deny**: 176 reviewed resource types
pass, everything else fails, including `Custom::*` and
`AWS::CloudFormation::CustomResource` (their Lambda could create anything
outside the gate). Explicitly not allowed today (docs-only until someone adds
them with a size rule): Network Firewall, GuardDuty, Security Hub, Inspector,
Macie, Config recorder, MemoryDB, DAX, MSK, Redshift provisioned, FSx, EMR,
Elastic Beanstalk, WorkSpaces, MWAA.

### Size and lifecycle rules

Sizes must be literals (no `Ref` to parameters), so a learner cannot deploy a
bigger size than the one validated.

| Rule | Limit |
|---|---|
| `COST_EC2_INSTANCE_TYPE` | EC2 instance: `t3`/`t4g` `nano`/`micro`/`small` |
| `COST_LAUNCH_TEMPLATE_INSTANCE_TYPE` | Same, for launch templates that set an instance type |
| `COST_ASG_MAX_SIZE` | Auto Scaling group `MaxSize` 1–3 |
| `COST_ASG_INSTANCE_OVERRIDES` | Mixed-instances overrides: literal small `t3`/`t4g`; no `InstanceRequirements` |
| `COST_EKS_NODEGROUP` | `t3`/`t4g` `small`/`medium`, `ScalingConfig.MaxSize` ≤ 2 |
| `COST_EBS_VOLUME` | ≤ 30 GiB, not `io1`/`io2` |
| `COST_BLOCK_DEVICE_VOLUMES` | Same, for instance and launch-template block devices |
| `COST_SINGLE_NAT_GATEWAY` | At most 1 NAT Gateway |
| `COST_TGW_ATTACHMENTS` | At most 3 Transit Gateway attachments |
| `COST_RDS_INSTANCE` | `db.t3`/`db.t4g` `micro`/`small`/`medium` or `db.serverless`; no provisioned IOPS; `DeletionPolicy: Delete`; no deletion protection |
| `COST_RDS_STORAGE` | `AllocatedStorage` = 20 GiB when set |
| `COST_AURORA_CLUSTER` | `DeletionPolicy: Delete`, no deletion protection, no Multi-AZ DB cluster (`DBClusterInstanceClass`) |
| `COST_AURORA_SERVERLESS_CAPACITY` | Serverless v2 `MaxCapacity` ≤ 2 ACU |
| `COST_DOCDB_NEPTUNE_INSTANCE` | `db.t3.medium` or `db.t4g.medium` |
| `COST_DOCDB_NEPTUNE_CLUSTER` | `DeletionPolicy: Delete` |
| `COST_ELASTICACHE_NODE` | `cache.t3`/`t4g.micro`, ≤ 2 nodes |
| `COST_ELASTICACHE_REPLICATION_GROUP` | `cache.t3`/`t4g.micro`, ≤ 2 nodes total |
| `COST_OPENSEARCH_DOMAIN` | Single `t3.small.search`, no dedicated master, EBS ≤ 10 GiB |
| `COST_DYNAMODB_PROVISIONED` | ≤ 5 RCU/WCU (or on-demand) |
| `COST_DYNAMODB_INDEX_THROUGHPUT` | GSI ≤ 5 RCU/WCU |
| `COST_KINESIS_SHARDS` | ≤ 2 shards |
| `COST_REDSHIFT_SERVERLESS` | Base and max capacity pinned to 8 RPU |
| `COST_SAGEMAKER_NOTEBOOK` | `ml.t3.medium` |
| `COST_SAGEMAKER_ENDPOINT` | Serverless, or `ml.t2.medium`/`ml.m5.large` |
| `COST_LAMBDA_NO_PROVISIONED_CONCURRENCY` | No provisioned concurrency on versions/aliases |
| `COST_APIGATEWAY_CACHE_SIZE` | REST API cache only at 0.5 GB, set explicitly |
| `COST_ECS_SERVICE_COUNT` | `DesiredCount` ≤ 2 |
| `COST_ECS_TASK_SIZE` | ≤ 1 vCPU, ≤ 2 GiB |
| `COST_EFS_NO_PROVISIONED_THROUGHPUT` | Bursting or elastic throughput only |
| `COST_NO_RETAINED_RESOURCES` | Any `DeletionPolicy` must be `Delete` |
| `COST_NO_RETAINED_ON_REPLACE` | Any `UpdateReplacePolicy` must be `Delete` |
| `COST_ECR_EMPTY_ON_DELETE` | ECR repositories need `EmptyOnDelete: true` |

### Allowed, but flagged in the cost table

Cheap only if deleted on time: NAT Gateway, Transit Gateway attachments,
Client VPN, Site-to-Site VPN, EKS control plane, Global Accelerator, Aurora
Serverless v2. The lab README must call these out.

## Security rules (`rules/lab-security.guard`)

| Rule | Requirement | Suppressible |
|---|---|---|
| `SEC_S3_BLOCK_PUBLIC_ACCESS` | All four `PublicAccessBlockConfiguration` flags `true` | Yes |
| `SEC_NO_PUBLIC_ADMIN_PORTS` | Security group ingress from `0.0.0.0/0` or `::/0` must not include 22, 3389 or all traffic | Yes |
| `SEC_NO_PUBLIC_ADMIN_PORTS_STANDALONE` | Same, for `AWS::EC2::SecurityGroupIngress` | No |
| `SEC_EC2_IMDSV2` | `MetadataOptions.HttpTokens: required` | Yes |
| `SEC_IAM_NO_ADMIN_INLINE` | Inline policies on roles/users/groups: no `Action: "*"` (list or single-object `Statement`) | No |
| `SEC_IAM_NO_ADMIN_POLICY` | Same, for `AWS::IAM::ManagedPolicy` / `AWS::IAM::Policy` | No |
| `SEC_IAM_NO_ADMINISTRATOR_ACCESS` | No `AdministratorAccess` or `PowerUserAccess` ARN, literal or `Fn::Sub` | No |
| `SEC_NO_IAM_ACCESS_KEYS` | No `AWS::IAM::AccessKey` | No |
| `SEC_RDS_NO_PLAINTEXT_PASSWORD` | No `MasterUserPassword`; use `ManageMasterUserPassword: true` | No |
| `SEC_RDS_NOT_PUBLIC` | RDS instance not `PubliclyAccessible` | Yes |
| `SEC_SECRET_PARAMETERS_NOECHO` | Parameters named like password/secret/token/apikey set `NoEcho: true` | No |
| `SEC_CONTAINER_IMAGE_PINNED` | ECS container images pinned by `@sha256:` digest ([ADR 0004](decisions/0004-digest-pinned-ecr-public-images.md)) | No |

### Suppressions

A suppression is allowed only when the insecure setting **is** the challenge
(for example, "Challenge 2: block public access"). It is declared on that one
resource, and only the rules marked suppressible above read it:

```yaml
PublicReports:
  Type: AWS::S3::Bucket
  Metadata:
    guard:
      SuppressedRules:
        - SEC_S3_BLOCK_PUBLIC_ACCESS   # Challenge 2
```

## Other controls outside the validator

| Control | Where |
|---|---|
| Validate before any AWS call; never adopt an existing stack | `selftest.sh` |
| Baseline 0/N and solved N/N in a real account | `selftest.sh` |
| No AWS writes while authoring | `SKILL.md` red flags |
| Prices from the Price List API, not memory | `price.sh`, `cost-policy.md` |
| Tool and action versions pinned (SHA / commit / exact version) | [ci-cd.md](ci-cd.md) |
| Private vulnerability reporting | [`SECURITY.md`](../SECURITY.md) |

## Known limits

The gate covers the lab **as written**. It does not cover:

- **What the learner does in the Console.** A challenge could lead to creating
  something larger than the template. `cleanup.sh` deletes what challenges
  create by name, but the learner should set an AWS Budget.
- **What code inside a lab does at runtime** (UserData, inline Lambda code).
  `lab-format.md` limits such code to short glue without dependencies, but the
  guard does not inspect it.
- **The self-test in CI.** CI has no AWS account; a real-account result is only
  as good as the output pasted into the pull request.
- **Offline runs.** `--offline` (used by `selftest.sh` and `tests/run.sh`) skips
  the link check.
- **Missing AWS CLI.** The command-existence check is skipped when `aws` is not
  installed.
- **Pattern-based checks.** The read-only and command-existence checks parse
  literal `aws <service> <operation>` text. Commands assembled indirectly (for
  example from variables) are not seen.

Report a template that gets past these rules and still costs money or opens
access through [`SECURITY.md`](../SECURITY.md), not a public issue.
