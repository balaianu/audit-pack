# Contributing

The bundle is text — contributions are edits to skills, agent prompts, docs,
or manifests.

## Ground rules

- **No `model:` pins.** Model policy is machine-local by design.
- **No hooks, no MCP, no secrets, no absolute paths.**
- **Keep the dialect split.** `agents/` is Devin format (`allowed-tools`);
  `agents-claude/` is Claude format (`tools:`). Never put both keys in one
  file — `tools` is a Devin alias for `allowed-tools`, so a mixed file breaks
  Devin's parser. Never ship `.claude-plugin/` — Claude auto-discovers
  `agents/` and would register the Devin files without restrictions.
- Skills stay host-agnostic: dispatch sections name each host's mechanism and
  every skill keeps an inline-sequential fallback.

## Checks

```bash
bash scripts/validate.sh
```

Run it before committing — CI runs the same script on push and PR.

## Style

- Markdown: no manual line wrapping inside paragraphs.
- Comments/docs say *why*, not *what*.
