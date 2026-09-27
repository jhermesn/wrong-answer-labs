# Direct Connect resiliency

| Certification | Exam guide domain(s) | Source questions |
|---|---|---|
| SAA-C03 | 2 — Design Resilient Architectures | Q2 |

<!-- section:why-no-lab -->
## Why there is no hands-on lab

Criterion 1 of the cost policy: Direct Connect needs a physical cross-connect at a Direct Connect location through a partner or carrier, billed per port-hour plus data transfer out. It cannot be reproduced in a study account.

<!-- section:concepts -->
## What the exam expects you to know

- Maximum resiliency = two connections at each of two separate Direct Connect locations.
- A Site-to-Site VPN over the internet is the low-cost backup for a single Direct Connect connection.

<!-- section:references -->
## Official documentation

- [What is Direct Connect?](https://docs.aws.amazon.com/directconnect/latest/UserGuide/Welcome.html)
- [Resiliency Toolkit](https://docs.aws.amazon.com/directconnect/latest/UserGuide/resiliency_toolkit.html)
- [Direct Connect pricing](https://aws.amazon.com/directconnect/pricing/)

<!-- section:cheap-practice -->
## Low-cost practice you can still do

Create a Transit Gateway with a Site-to-Site VPN attachment (no tunnel needs to come up) and inspect its route tables; delete it within the hour.

<!-- section:answers -->
## Answer key

<!-- question:Q2 -->
### Q2 — Highly available hybrid connectivity

- **Your answer:** one Direct Connect connection with a second virtual interface.
- **Correct answer:** two Direct Connect connections terminating at separate Direct Connect locations.

A second virtual interface shares the same physical port and location, so it is not a failure-domain boundary.
