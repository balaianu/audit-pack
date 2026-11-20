# Security Policy

audit-pack ships markdown, YAML, and JSON only — no executable code, no hooks,
no MCP servers, no network calls, no telemetry.

## Containment model

- Agent tool lists are **true restrictions**: unlisted tools are unavailable
  to the subagent, not denied by rule.
- `code-auditor` carries `exec`/`Bash` to run tests and builds — shell
  redirection can still write files. For hard containment, point audits at a
  clean checkout or worktree.
- `repo-evaluator` has no exec and no write — it cannot act on the hostile
  content it reads.

## What deliberately isn't here

- **No model pins** — model policy resolves through your local
  `subagent_model`/`model` config.
- **No hooks** — plugin hooks are fail-open; shipping one would be security
  theatre.

## Reporting

Open an issue at the repository this was installed from. For sensitive
findings, contact the maintainer directly — don't file exploit details in a
public issue.
