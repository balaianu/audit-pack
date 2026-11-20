# Changelog

All notable changes to audit-pack. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
versioning follows [SemVer](https://semver.org/).

## [0.1.0] — 2026-11-20

Initial release.

### Added

- `triple-audit` skill — three-axis parallel audit (security & trust boundaries,
  logic & state, data accuracy & compatibility) with host-aware dispatch and an
  inline sequential fallback for hosts without subagents.
- `repo-eval` skill — staged, read-only evaluation of third-party repos, tools,
  and skills for adoption value and safety.
- `code-auditor` agent profile — read/grep/glob/exec tool set; runs tests and
  builds but carries no file-mutation tools.
- `repo-evaluator` agent profile — read/grep/glob/web only; no exec, no write,
  no subagents. Writes are impossible by construction.
- Devin manifest (`.devin-plugin/plugin.json`) — full plugin: namespaced
  skills + agents install via `devin plugins install`.
- Agent Plugins spec manifest (`plugin.json`) — skills layer for spec hosts.
- `agents-claude/` — Claude-dialect agent profiles for manual install into
  `~/.claude/agents/` (no `.claude-plugin/` manifest shipped — Claude would
  auto-register the Devin-dialect `agents/` files without tool restrictions).
- `scripts/validate.sh` — bundle integrity checks (JSON, frontmatter, no
  model pins, no absolute paths, no secret-looking strings).

### Design decisions

- No `model:` pins in shipped profiles — model policy resolves through each
  installer's local `subagent_model` → `model` config and stays machine-local.
- No hooks shipped — plugin hooks are best-effort/fail-open and cannot serve
  as a security boundary, so policy is deliberately absent from the bundle.
