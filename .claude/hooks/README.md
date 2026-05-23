# hooks/

This directory holds the project's executable hooks. They run automatically based on the wiring in `.claude/settings.json`.

## Template files (`.tpl`)

The `.tpl` files in this directory are **not** runtime hooks — they are templates the bootstrap renders into concrete scripts:

| Template | Rendered to (typical) | Purpose |
|---|---|---|
| `post-edit.sh.tpl` | `post-edit-backend.sh`, `post-edit-frontend.sh`, etc. | Advisory anti-pattern checks at write time |
| `check-test-coverage.sh.tpl` | `check-test-coverage.sh` (only if coverage is enabled in BASELINE) | Blocking gate at `/finish-task` |

After bootstrap, the `.tpl` files are removed from the project (they live only in the source template).

## How hooks are wired

`settings.json` registers them:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          { "type": "command", "command": "bash $CLAUDE_PROJECT_DIR/.claude/hooks/post-edit-<layer>.sh" }
        ]
      }
    ]
  }
}
```

The matcher targets `Edit`, `Write`, and `MultiEdit` tool calls. Each script reads the tool payload from stdin (JSON), filters by the file's layer (backend / frontend / etc.), and writes warnings to **stderr** (advisory, non-blocking).

## Design principles

1. **Advisory by default.** Hooks write to stderr; they never block writes. The implementer reads the warning and corrects mid-task.
2. **Fast.** Pure bash + grep. Anything slower belongs in `/check` or `/code-review`, not a write-time hook.
3. **Project-specific over generic.** Hooks cite anti-pattern codes from `code-review-checklist.md`. Generic clean-code warnings are noise.
4. **Promotion path.** When a finding from `code-reviewer` recurs ≥5× in `learning/violations.md`, it gets promoted into a hook regex via `/evolve-claude --promote-hook <code>`.

## Adding a new check

1. Open the relevant `post-edit-*.sh` script.
2. Add a block following the existing shape:
   ```bash
   # B-C99: short description of what to catch
   if grep -nE 'YOUR_REGEX' "$file" >/dev/null; then
     lines="$(grep -nE 'YOUR_REGEX' "$file" | head -3)"
     warn "B-C99: explanation. See patterns/<doc>.md § <section>. Lines: $lines"
   fi
   ```
3. Add the corresponding code to `code-review-checklist.md` so the auditor and reviewer cite it too.
