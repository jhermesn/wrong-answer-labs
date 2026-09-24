# Cost policy: lab or docs-only?

A topic becomes a **docs-only** entry when ANY row applies. Otherwise build a lab.

| # | Criterion | Examples |
|---|---|---|
| 1 | Needs physical hardware, on-premises gear or a partner/carrier | Direct Connect, Outposts, Snow Family, Storage Gateway hardware appliance, Private 5G, Ground Station |
| 2 | Has a commitment, subscription, upfront or non-prorated monthly fee | Shield Advanced, Reserved Instances / Savings Plans purchase, Business/Enterprise Support, Marketplace subscriptions, Route 53 domain registration, AWS Private CA, QuickSight subscription, Dedicated Hosts, Bedrock provisioned throughput |
| 3 | Stack costs > US$0.50/hour, or > US$1.00 for the whole lab (deploy + solve + delete) | Redshift provisioned, MSK, FSx, OpenSearch Serverless, Kendra, EMR on EC2, CloudHSM, non-burstable RDS/Aurora classes |
| 4 | Needs an Organizations management account, root user, or an account-wide change that is hard to undo | Control Tower landing zone, SCPs, IAM Identity Center organization instance, support plan changes, service quota increases |
| 5 | Deploy + delete takes > 30 min | Managed Microsoft AD, large Aurora global databases |

`rules/lab-cost.guard` enforces rows 2-3 mechanically on the template
(denied types, size allowlists, `DeletionPolicy: Delete`). If a lab only passes
the guard by dropping the concept the questions test, it is docs-only.

## Allowed, but call it out in the README cost table

Hourly resources that are cheap only if deleted on time: NAT Gateway, Transit
Gateway attachments, Network Firewall endpoints, Client VPN, Site-to-Site VPN
connection, EKS control plane, Global Accelerator, Aurora Serverless v2.

Account-wide detectors (GuardDuty, Security Hub, Inspector, Macie, Config
recorder) fail to create if already enabled and keep billing after the lab:
create them in the stack only when the challenge is about them, and say so.

## Filling the cost table

One row per billable resource: unit price in us-east-1, cost for the lab
duration, and the **official pricing page URL** as source
(`https://aws.amazon.com/<service>/pricing/`). Read prices from that page (or
`aws pricing get-products` when credentials are available); never from memory.
The validator checks every URL resolves.

## Docs-only entry

- `why-no-lab`: which criterion (1-5) applies, with the price or constraint.
- `concepts`: what the exam expects, framed by the wrong answers.
- `references`: official AWS docs found with the AWS Documentation MCP server
  (`search_documentation` → `read_documentation`), or docs.aws.amazon.com
  fetched directly. Prefer User Guide pages plus the relevant FAQ.
- `cheap-practice`: the nearest affordable hands-on (e.g. Direct Connect →
  build a Site-to-Site VPN attachment on a Transit Gateway and compare routing),
  or "none" when nothing honest exists.
