# audit-pack

> **Contained audit workers for AI coding agents.**
>
> Deep specialist review from subagents that can't write past their brief — and hostile-content evaluation by an agent that can't act at all.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-0.1.0-green.svg)](CHANGELOG.md)
[![validate](https://github.com/balaianu/audit-pack/actions/workflows/validate.yml/badge.svg)](https://github.com/balaianu/audit-pack/actions/workflows/validate.yml)
[![Buy Me A Coffee](https://img.shields.io/badge/☕-Buy%20Me%20A%20Coffee-yellow)](https://buymeacoffee.com/balaianu)

---

## The problem

Two recurring jobs need an agent you can *constrain*, not just instruct:

- **Auditing your own code** in the session that wrote it — the reviewer inherits your assumptions and misses what you missed. You want fresh eyes with no memory of the writing process.
- **Evaluating third-party code** (repos, tools, skills) before adopting it — the content itself may be hostile, carrying prompt-injection in its docs, and the evaluating agent shouldn't be able to execute what it reads.

Prompt-level "please don't write anything" is a request, not a boundary.

## The solution

Subagent profiles whose **tool lists are the boundary** — unlisted tools don't exist for the worker, not denied by rule, scoped to the subagent's lifetime only:

| Profile | Tools | Lane |
|---|---|---|
| `code-auditor` | read, grep, glob, exec — no write/edit | first-party audits; can run tests and builds |
| `repo-evaluator` | read, grep, glob, webfetch, web_search — **no exec, no write** | third-party content; writes are impossible by construction |

Two skills drive them:

- **`triple-audit`** — three parallel `code-auditor` workers on separate axes (security & trust boundaries, logic & state, data accuracy & compatibility), cross-checked and merged by the coordinator. Fresh context per axis: the session that wrote the code can't contaminate the review.
- **`repo-eval`** — stage the target locally (clone + metadata file, nothing executed), then hand the tree to `repo-evaluator`, which reports structure, health, risk surfaces, and injection attempts in a fixed EVAL block.

## What it looks like

Real output after install:

```
$ devin plugins info audit-pack

Skills
  /audit-pack:triple-audit — Three-axis parallel audit …
  /audit-pack:repo-eval    — Evaluate a third-party repo …

Agents
  audit-pack:code-auditor    — Bounded-axis code auditor …
  audit-pack:repo-evaluator  — Read-only evaluator for third-party …
```

And a live dispatch:

```
run_subagent(profile="audit-pack:code-auditor",
             task="…bounded task…")
→ subagent runs with read/grep/glob/exec only; write/edit unavailable
```

## Install

### Devin

```bash
# local / linked checkout
devin plugins install --local /path/to/audit-pack

# from a git host
devin plugins install owner/repo#path/to/audit-pack
```

Requires `subagents_enabled: true` in `~/.config/devin/config.json` — a
user-level flag the plugin can't set for you. Skills and agents register
namespaced (`/audit-pack:<skill>`, `audit-pack:<agent>`), so they can't
collide with your own profiles.

### Claude Code — manual install

**No `.claude-plugin/` manifest is shipped, deliberately.** Claude
auto-discovers `agents/`, and the Devin-dialect files there would register
*unrestricted* (Claude's format needs `tools:`; absent means all tools).
Install the pieces by hand instead:

```bash
cp -r skills/* ~/.claude/skills/       # or symlink
cp agents-claude/*.md ~/.claude/agents/
```

Then dispatch by name via the Task tool (`subagent_type: code-auditor` /
`repo-evaluator`).

### Other hosts

The spec `plugin.json` exposes the skills layer (Agent Plugins spec 1.0.0
has no agent concept yet). On hosts without subagent dispatch, each skill
falls back to running its axes inline and sequentially — and says so.

## Model policy

Shipped profiles carry **no `model:` pin** — by design. Dispatch resolves
through your own config (`agent.subagent_model`, then `agent.model`), so you
choose the tier audit workers run on. Policy is machine-local; it doesn't
ship in the bundle.

## Safety notes

- `code-auditor` has `exec`/`Bash` by necessity — shell redirection can
  still write. For hard containment, audit a clean checkout/worktree.
- `repo-evaluator` cannot execute or write: hostile content it reads cannot
  act on itself.
- No hooks, no MCP, no secrets, no absolute paths — the bundle is pure text.
- Plugin agents load in **local** Devin sessions (CLI/Desktop), not cloud.

## Layout

```
audit-pack/
├── .devin-plugin/plugin.json   # Devin manifest (full plugin)
├── plugin.json                 # Agent Plugins spec manifest (skills)
├── agents/                     # Devin dialect (allowed-tools)
├── agents-claude/              # Claude dialect (tools:) — manual install
├── skills/
│   ├── triple-audit/SKILL.md
│   └── repo-eval/SKILL.md
├── scripts/validate.sh         # bundle integrity checks
└── CHANGELOG.md
```

Why two agent dirs: `tools` is a Devin *alias* for `allowed-tools`, so a
file carrying both dialects breaks Devin's parser — and shipping only
Devin-dialect files would register them unrestricted on Claude.

## Revert

```bash
devin plugins uninstall audit-pack        # Devin
# or delete the copied files under ~/.claude/   (Claude)
```

Nothing outside those locations is touched.

## License

[MIT](LICENSE)
