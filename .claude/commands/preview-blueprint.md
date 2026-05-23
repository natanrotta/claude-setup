---
description: Renders the bootstrap blueprint HTML from `.claude/.bootstrap-state.json` and opens it in the user's browser for visual confirmation. Invoked by /bootstrap-claude after the interview completes; can be invoked again standalone to re-render after refinements.
---

# /preview-blueprint — HTML Generator

You are the **blueprint renderer**. You read the structured payload that `/bootstrap-claude` wrote to `.claude/.bootstrap-state.json` and produce a single self-contained HTML page that shows the user exactly what will be written into `.claude/`.

The HTML is the **visual contract** — the user reads it in 30 seconds and either approves or asks for adjustments before any real `.claude/` files are touched.

---

## Inputs

You read:

1. `.claude/.bootstrap-state.json` — the interview answers + derived data
2. `blueprint-template/blueprint.html.tpl` — the HTML template with `{{PLACEHOLDERS}}`

You produce:

- `.claude/.preview/blueprint.html` — the rendered, self-contained HTML

---

## Workflow

### Step 1 — Load and validate

1. Read `.claude/.bootstrap-state.json`. If missing or malformed → abort with "Run `/bootstrap-claude` first."
2. Check `status` field:
   - `in-progress` → abort with "Bootstrap interview not finished yet."
   - `ready-for-blueprint` → proceed.
   - `confirmed` → ask via `AskUserQuestion` whether the user wants to re-render the already-confirmed blueprint (useful for sharing screenshots).
3. Read `blueprint-template/blueprint.html.tpl`.

### Step 2 — Render

Replace every `{{PLACEHOLDER}}` in the template with the matching value from the state JSON. Placeholders the template supports:

| Placeholder | Source | Notes |
|---|---|---|
| `{{PROJECT_NAME}}` | `project_name` | Hero title |
| `{{PRODUCT_ONELINER}}` | `stages.produto.answers.one_liner` | Hero subtitle |
| `{{PRIMARY_PERSONA}}` | `stages.produto.answers.persona` | Hero meta |
| `{{DOMAIN}}` | `stages.produto.answers.domain` | Hero meta |
| `{{DEFAULT_LANGUAGE}}` | `stages.produto.answers.language` | Hero meta |
| `{{MVP_FEATURES_LIST}}` | `stages.produto.answers.features` (array) | Bullet list |
| `{{STACK_BADGES}}` | `derived.stack_table_rows` | Rendered as `<span class="badge">` per row |
| `{{ARCHITECTURE_DIAGRAM}}` | `derived.architecture_ascii` | Pre-rendered ASCII art |
| `{{ANTI_PATTERN_TABLE}}` | `derived.anti_pattern_codes` | HTML table |
| `{{HOOKS_TABLE}}` | `derived.hooks_to_wire` | HTML table |
| `{{SPECIALISTS_CARDS}}` | `derived.specialists_list` | One card per specialist |
| `{{PIPELINE_DIAGRAM}}` | Static — pipeline always: triage → babysit → finish-task | ASCII/SVG |
| `{{FILE_TREE}}` | `derived.file_tree_preview` | `<pre>` block |
| `{{NEXT_STEPS}}` | Static — instructions for first task | Markdown rendered |
| `{{BOOTSTRAP_DATE}}` | `bootstrap_date` | Footer |
| `{{BASE_BRANCH}}` | `stages.qualidade.answers.base_branch` | Used in commands |

For arrays (lists, tables, cards), iterate and emit one HTML node per item. The template uses simple `{{#each LIST}}...{{/each}}` blocks (mustache-style) — substitute manually since this is markdown-driven, not a runtime template engine.

### Step 3 — Write

1. Create `.claude/.preview/` if it doesn't exist.
2. Write the rendered HTML to `.claude/.preview/blueprint.html`.
3. The HTML must be **fully self-contained** — no external CSS, no external fonts, no external images. Inline everything. The user must be able to open the file with no internet and see the same thing.

### Step 4 — Open in browser

Detect the platform and open the file:

```bash
# macOS
open .claude/.preview/blueprint.html

# Linux
xdg-open .claude/.preview/blueprint.html

# Windows (Git Bash / WSL)
start .claude/.preview/blueprint.html
```

If the open command fails (e.g. headless environment), just print the absolute path and tell the user to open it manually.

### Step 5 — Return to caller

Print a one-line summary:

```
Blueprint rendered: file:///absolute/path/to/.claude/.preview/blueprint.html
```

If invoked by `/bootstrap-claude`, return control immediately — `/bootstrap-claude` will then prompt for approval.

If invoked standalone, end the skill here. The user can decide what to do next.

---

## Hard rules

1. **Read-only on `.claude/` outside `.preview/`.** This skill only writes to `.claude/.preview/`. It does not touch patterns, hooks, agents, or commands.
2. **Self-contained HTML.** Inline all assets. No CDN, no font links, no external images.
3. **Dark theme by default.** The template ships dark; do not invert.
4. **Do not modify the state JSON.** That belongs to `/bootstrap-claude` (and `/evolve-claude`).
5. **Idempotent.** Re-running this skill on the same state produces byte-identical HTML.

$ARGUMENTS
