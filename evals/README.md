# Evaluations

Scenarios for checking that an agent uses the skill well, in the format from
Anthropic's [skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices).
`tests/run.sh` covers the tooling; these cover the agent's behavior, which only
a real run can show.

| File | What it exercises |
|---|---|
| `01-single-lab.json` | One question becomes one lab without giving the answer away |
| `02-docs-only.json` | A topic that cannot be reproduced becomes a docs-only entry |
| `03-grouped-batch.json` | Grouping, deriving a missing answer, documented values, real prices |

## Running one

1. Start a fresh agent session with the skill installed, in an empty directory.
2. Send the `query` as the first message.
3. Score each line of `expected_behavior` as met or not met, and note what went
   wrong for anything not met.

Run them after any change to `SKILL.md` or `references/`, and on each model you
support. Record results in the pull request.
