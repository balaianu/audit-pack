#!/usr/bin/env bash
# Bundle integrity checks — run from the plugin root or CI.
# Fails on: invalid JSON, broken frontmatter, model pins, absolute paths,
# secret-looking strings, agent files that mix Devin and Claude tool dialects.
set -euo pipefail
cd "$(dirname "$0")/.."
fail() { echo "FAIL: $1" >&2; exit 1; }

echo "== manifest JSON"
for f in .devin-plugin/plugin.json plugin.json; do
  python3 -m json.tool "$f" >/dev/null || fail "invalid JSON: $f"
done

echo "== frontmatter parses"
for f in agents/*.md agents-claude/*.md skills/*/SKILL.md; do
  head -1 "$f" | grep -q '^---$' || fail "missing frontmatter fence: $f"
  python3 - "$f" <<'PY' || fail "frontmatter YAML broken: $f"
import sys
try:
    import yaml
except ImportError:
    sys.exit(0)  # no yaml module → structural check only
with open(sys.argv[1]) as fh:
    parts = fh.read().split('---', 2)
    assert len(parts) >= 3, "no frontmatter block"
    yaml.safe_load(parts[1])
PY
done

echo "== no model pins (policy stays machine-local)"
! grep -rnE '^\s*model:' agents/ agents-claude/ skills/ || fail "model pin found"

echo "== no absolute paths outside docs"
! grep -rnE '/home/|/Users/|C:\\\\' agents/ agents-claude/ skills/ .devin-plugin/ plugin.json || fail "absolute path found"

echo "== no secret-looking strings"
# assignment patterns and key formats, not the words — 'Secrets handling' is audit vocabulary
! grep -rniE '(api[_-]?key|secret|token|password)[[:space:]]*[:=]|sk-[a-z0-9]{20}' agents/ agents-claude/ skills/ *.json .devin-plugin/ || fail "secret-like string found"

echo "== no forbidden files"
[ ! -d .claude-plugin ] || fail ".claude-plugin/ must not ship (see README)"
[ ! -d hooks ] || fail "no hooks allowed in the bundle"

echo "== dialect separation"
# anchored: 'tools:' alone would substring-match 'allowed-tools:'
! grep -lE '^\s*tools:' agents/*.md >/dev/null 2>&1 || fail "Claude 'tools:' key inside agents/ breaks Devin's parser"
grep -lE '^\s*allowed-tools:' agents-claude/*.md >/dev/null 2>&1 && fail "Devin 'allowed-tools' key inside agents-claude/ is ignored by Claude (unrestricted agent)"

echo "OK — all checks passed"
