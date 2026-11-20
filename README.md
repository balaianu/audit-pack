# audit-pack

Contained audit workers for agent hosts: deep specialist review that can't write, execute, or reach beyond its brief.

**Skills**

| Skill | What it does |
|---|---|
| `triple-audit` | Three-axis parallel audit (security / logic & state / data accuracy) of first-party code — dispatches three `code-auditor` subagents so the session that wrote the code can't contaminate the review |
| `repo-eval` | Adoption/safety eval of third-party repos, tools, and skills — dispatches a `repo-evaluator` subagent with no exec and no write, so hostile content can't act on itself |

**Agents**

| Profile | Tools | Lane |
|---|---|---|
| `code-auditor` | read, grep, glob, exec — no write/edit | first-party audits; runs tests and builds |
| `repo-evaluator` | read, grep, glob, webfetch, web_search — no exec, no write | hostile third-party content |

The tool lists are *true restrictions* — unlisted tools are unavailable to the subagent, not denied by rule — scoped to the subagent's lifetime only.

## Install

```bash
# Devin (local/linked install, this machine only)
devin plugins install --local /path/to/audit-pack

# Devin (from a git host — for yourself or others)
devin plugins install owner/repo#path/to/audit-pack
```

Other hosts read the spec `plugin.json` (skills layer only — spec 1.0.0 has no agents yet).

## Prerequisites

- **Devin**: `subagents_enabled: true` in `~/.config/devin/config.json` (a user-level flag the plugin cannot set). Agents register automatically on install — skills invoke as `/audit-pack:<skill>`, profiles as `audit-pack:<agent>`.
- **Claude Code** (manual install — deliberately no `.claude-plugin/` manifest): Claude auto-discovers `agents/` and would register the Devin-dialect files *unrestricted* (its format needs `tools:`; missing means all tools). Don't install this via Claude's plugin manager — copy the pieces instead:
  ```bash
  cp -r skills/* ~/.claude/skills/     # or symlink
  cp agents-claude/*.md ~/.claude/agents/
  ```
  Then dispatch by name via the Task tool (`subagent_type: code-auditor` / `repo-evaluator`). The two agent dirs exist because `tools` is a Devin *alias* for `allowed-tools` — a file carrying both dialects breaks Devin's agent parser.
- Any other host: the skills degrade to inline sequential runs (see each skill's fallback section).

## Model policy

The shipped profiles carry **no `model:` pin** — by design. Dispatch resolves to your local `agent.subagent_model`, then `agent.model`. Set `subagent_model` to whatever tier you want audit workers on (a free/cheap tier is the intended use). Policy is machine-local; it does not ship in the bundle.

## Notes

- `code-auditor` has `exec`/`Bash` by necessity (tests, builds) — its restriction removes file tools, not all side effects; shell redirection can still write. For hard containment, point it at a clean checkout/worktree.
- Namespacing: plugin subagents register as `<plugin>:<name>` (e.g. `audit-pack:code-auditor`), so they cannot collide with same-named profiles you already have.
- Devin plugin subagents currently load in local agents only (CLI + Devin Desktop), not cloud sessions — skills load everywhere; dispatches fail where the agent isn't registered.
- No hooks, no MCP, no secrets, no absolute paths — the bundle is pure text.
- Revert: `devin plugins uninstall audit-pack` (Devin) or delete the copied files under `~/.claude/` (Claude) — nothing else was touched.
