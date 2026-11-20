---
name: triple-audit
description: "Three-axis parallel audit (security and trust boundaries, logic and state, data accuracy and compatibility) for any project requiring expert review: code, scripts, config, infrastructure, data pipelines, docs. Fresh-context subagents keep the main session's assumptions out of the audit. Use when the user wants a deep specialist audit: triple audit, three-way review, independent audit."
argument-hint: "[scope: repo path, subsystem, or diff range]"
triggers:
  - user
  - model
---

# Triple-Audit Workflow

## When to use
Any codebase, script, configuration, or system requiring expert-level security/quality review, especially when the main session wrote or modified the code under audit. The subagents start with no session context, so assumptions made while writing the code do not carry into the review.

## Workflow

### 1. Launch 3 parallel audit subagents (background)

Dispatch one `code-auditor` subagent per axis — background, parallel. The bundled profile (`../../agents/code-auditor.md` relative to this file) has read/grep/glob/exec — can run tests and builds but cannot write or edit (true restriction = mechanical read-only). Each subagent gets a self-contained task: scope, its axis checklist, and the required output. Specialists never see each other's findings.

**How to dispatch, by host:**
- **Devin** (`run_subagent`): profile name is plugin-namespaced — `run_subagent` with profile `<plugin>:code-auditor` (e.g. `audit-pack:code-auditor`; check the installed plugin's prefix with `devin plugins list`).
- **Claude Code** (`Task`): dispatch a Task subagent with `subagent_type` matching the bundled agent's registered name.
- **No subagent support**: run the three axes yourself, sequentially, and note in the report that the audit was single-context — the fresh-eyes guarantee is lost, everything else holds.

Each subagent gets a DIFFERENT focus area to maximize coverage and minimize duplicate findings:

**Subagent A - Security & Trust Boundaries:**
- Authentication/authorization bypasses, privilege escalation, confused-deputy cases
- Injection of any kind: shell, SQL, path traversal, template, config/format injection
- Untrusted input reaching a sink without validation or escaping
- Secrets handling: hardcoded, logged, leaked through errors, artifacts, or process lists
- Resource exhaustion and DoS: unbounded input, loops, queues, storage growth
- Unsafe external interaction: subprocesses, network, deserialization, callbacks, TOCTOU
- Supply chain and install paths: unpinned dependencies, download-and-run, CI permissions
- Safe defaults: fresh install, upgrade from an older version, initial state

**Subagent B - Logic & State Consistency:**
- State machine correctness: lifecycle, transitions, double execution, idempotency (is re-running safe?)
- Partial failure and rollback: what is left behind when step N of M fails
- Cursor/index/pagination management: skip, stuck, boundary conditions
- Invariants: counters, caches, indexes, and records match the real state
- Loop termination and bounding
- Ordering and concurrency: races, locking, last-writer-wins
- Logs, events, and messages vs the state changes they describe
- Edge cases: first/last/single/max/empty/duplicate/concurrent

**Subagent C - Data Accuracy, Compatibility & Docs:**
- Data integrity: round-trips, truncation, encoding, escaping, precision
- Type/width sufficiency, overflow, sentinel values that collide with valid data
- Parsing fidelity: does the code read a format the way the real tool or spec does (verify against the real tool)
- Platform and version compatibility: OS, shell, runtime, tool versions
- External integration correctness: consumer-side checks, API contracts
- Docs, changelog, version strings, and tests vs actual behavior (drift)
- Domain-specific correctness: units, time, money, locale, whatever the project is about

### 2. Cross-check all findings

For EACH finding from all 3 auditors:
1. Read the exact lines cited
2. Trace the code path claimed
3. Verify the attack scenario is actually possible
4. Check if the auditor self-retracted or expressed uncertainty
5. Classify as: CONFIRMED, FALSE POSITIVE, or NEEDS INVESTIGATION

Common false positive patterns to watch for:
- **Defense already present upstream**: the input is validated, escaped, or locked earlier on every path to the sink
- **Preconditions that already imply the access being "gained"**: e.g. the attack needs write access to the very file or directory it would compromise
- **Hypothetical scenarios requiring impossible preconditions**: e.g., "if the runtime or filesystem is corrupted" — not a real vulnerability
- **Known limitations or design choices presented as vulnerabilities**: documented behavior, by design
- **Platform guarantees misunderstood**: the runtime serializes this, the OS makes this atomic, the library already escapes this — check before accepting a race or injection claim
- **Off-by-one on inclusive vs exclusive bounds**: recount against the intended semantics before accepting
- **Sentinel conflicts that cannot occur in practice**: the colliding value is not reachable from valid input
- **Claims about external tools not verified against the real tool**: run the tool and compare; do not accept either side from memory
- **Auditor self-retractions**: Some auditors flag CRITICAL then say "actually correct" in the description — read the full text

### 3. Produce structured report

Format:
```
## Audit Report: [project name]

### Methodology
3 parallel expert auditors (Security, Logic, Data Accuracy) + cross-check

### Findings Summary
| # | Severity | Title | Status |
|---|----------|-------|--------|

### Confirmed Findings
[Only findings verified against actual code]

### False Positives Rejected
[Brief list with rejection reason — prevents re-investigation]

### Verdict
[Production ready / needs fixes / critical issues]
```

### 4. Quality bar

- Every CONFIRMED finding must cite exact line numbers
- Every FALSE POSITIVE must state the specific reason it's wrong
- No finding should be accepted without tracing the actual code path
- If 2+ auditors flag the same issue independently, weight it higher
- If an auditor's own description contradicts their severity rating, trust the description
