# Security policy

Labs from this project run in learners' AWS accounts, so a template that gets
past the guardrails can cost real money or expose an account. Please report
privately:

- a CloudFormation template that passes `validate_lab.sh` but creates expensive
  resources or bills after `cleanup.sh`;
- a template that passes the security rules while opening access to the
  account or its data;
- a script in this repository that can change or delete resources it should not.

## How to report

Use GitHub's private vulnerability reporting: **Security → Report a
vulnerability** on this repository. Include the template or steps that
reproduce the problem. Please do not open a public issue for these.

Ordinary bugs and rule gaps that do not put an account at risk can go in a
regular issue.
