---
description: Post-bootstrap refinement skill. Reads `.claude/learning/violations.md` to promote recurring violations into hooks or BASELINE rules, detects new modules from recent commits, can re-run focused stages of the bootstrap interview when the stack drifts, and on `--reset` does a full re-bootstrap. Use periodically (e.g. monthly) and after significant project growth.
---

# /evolve-claude — Setup Evolution

You are the **setup evolution skill**. Your job is to keep `.claude/` alive as the project grows — promote recurring violations into hooks, add knowledge entries for new modules, detect stack drift, and offer to refine the setup without losing the user's customizations.

This is the only skill (besides `/bootstrap-claude`) that is allowed to modify `.claude/patterns/`, `.claude/hooks/`, and `.claude/agents/` after the initial bootstrap. Even so, it asks before each write.

---

## Modes

The skill picks the mode from `$ARGUMENTS`:

| Mode | Trigger | Effect |
|---|---|---|
| **Default** (no args) | `/evolve-claude` | Run all surveys (violations, modules, drift) and present a single batched proposal |
| `--promote-hook <CODE>` | User wants a specific code wired into the hooks | Promote that code's regex into the matching `post-edit-*.sh` |
| `--add-knowledge <module>` | User wants a knowledge file for a specific module | Bootstrap a `knowledge/<module>.md` from the module's code |
| `--refine-stage <stage>` | One stage of bootstrap needs to be re-asked | Re-run that stage's questions and re-render only the affected files |
| `--reset` | User wants to wipe and re-bootstrap | Confirm catastrophically, then delete rendered files and run `/bootstrap-claude` from scratch |

---

## Default mode workflow

### Phase 1 — Surveys (silent reads)

Run three checks in parallel where possible:

**Survey A — Recurring violations.**

1. Read `.claude/learning/violations.md`.
2. Group lines by code. Count occurrences within the last 30 days.
3. Any code with ≥ 5 hits in 30 days is a **promotion candidate**.
4. For each candidate, check whether the code is already covered by a hook regex (`grep` the `post-edit-*.sh` files). If yes, skip. If no, mark for promotion.

**Survey B — New modules.**

1. Read BASELINE § Module layout for the project's modules root.
2. Run `git log --since="30 days ago" --diff-filter=A --name-only -- <modules_root>` to find newly-added module directories.
3. For each new module, check whether `knowledge/<module>.md` exists. If not, mark for proposal.

**Survey C — Stack drift.**

1. Read the current `package.json` / `Cargo.toml` / etc.
2. Compare against the stack recorded in `.claude/.bootstrap-state.json` § `stages.stack.answers`.
3. Flag any new top-level dependency that touches the architecture: new ORM, new framework, new state library, new test runner, new deploy target.

### Phase 2 — Batched proposal

If the surveys produced **zero findings**, print `No evolution needed — setup is healthy.` and exit.

Otherwise, present a single `AskUserQuestion` with one entry per finding type:

1. **Promote N violation codes into hooks?** — `Yes, all` / `Yes, pick which` / `No — skip` (Recommended depends on count)
2. **Create N module knowledge files?** — `Yes` / `Pick which` / `No`
3. **Refine stack stage (stage 2)?** — only present if drift was detected. `Yes — re-ask stage 2 questions` / `No`
4. **Other refinements?** — free-text follow-up

### Phase 3 — Execute approved changes

For **hook promotions**:
1. For each approved code, read the code's regex / pattern from `code-review-checklist.md` (the entry should include enough detail).
2. Add a new `if grep ...` block to the matching `post-edit-*.sh` script.
3. Re-render the file (preserving the user's customizations — only append the new block).

For **knowledge files**:
1. For each approved module, read the module's source files (top-level files, README if present).
2. Generate a starter `knowledge/<module>.md` with sections: `Purpose`, `Key entities`, `Key flows`, `Edge cases`, `Recent learnings (auto-populated)`.

For **stack refinement**:
1. Re-run Stage 2 of `/bootstrap-claude` (single batched `AskUserQuestion`).
2. Re-render only the affected files: `BASELINE.md`, `code-review-checklist.md`, the relevant `post-edit-*.sh`, `CLAUDE.md` routing section.
3. **Preserve user customizations** — read the existing file, diff against the regenerated template, ask before overwriting any line the user changed manually.

After all writes:

1. Update `.claude/.bootstrap-state.json` with the evolution timestamp.
2. Print a summary of what changed.

---

## `--promote-hook <CODE>` mode

1. Find the code's entry in `code-review-checklist.md`.
2. If it has a clear regex/string indicator → append the corresponding `if grep ...` block to the matching `post-edit-*.sh`.
3. If the code is semantic-only (no clear regex) → refuse with "This code is semantic — keep it in the reviewer's purview. Promotion into a hook would produce false positives."
4. Update the checklist to mark the code as `(hooked)`.

---

## `--add-knowledge <module>` mode

1. Verify the module path exists.
2. Read the module's top 5 most-edited files (`git log --pretty=format: --name-only | grep <module> | sort | uniq -c | sort -rn | head -5`).
3. Read their content.
4. Generate `knowledge/<module>.md` with the standard sections.
5. Ask via `AskUserQuestion` whether to add more sections (custom).

---

## `--refine-stage <stage>` mode

Stage values: `produto`, `stack`, `padroes`, `estilos`, `qualidade`.

1. Re-run that stage's `AskUserQuestion` from `bootstrap-claude.md`.
2. Update `.bootstrap-state.json` § `stages.<stage>`.
3. Re-derive the affected `derived` fields.
4. Re-render only the affected files.
5. Diff each rewrite against the current file; ask before overwriting manual customizations.

---

## `--reset` mode

**Destructive.** Confirm explicitly:

```
This will:
1. Delete .claude/.bootstrap-state.json
2. Delete the rendered patterns/BASELINE.md, patterns/code-review-checklist.md
3. Delete the rendered hooks/post-edit-*.sh
4. Delete the rendered specialist agents (NOT the portable ones — those are kept)
5. Re-copy the .tpl files from the upstream template (if available)
6. Run /bootstrap-claude from scratch

Your knowledge/, learning/, and any manual customizations to portable agents WILL BE PRESERVED.

Confirm? (type "yes, reset")
```

If confirmed, execute the steps above. The portable agents and the bootstrap/preview/evolve skills are untouched.

If the upstream template (`claude-setup`) is reachable (via `git submodule`, or via a `degit` re-fetch), restore the `.tpl` files. Otherwise instruct the user to `degit natanrotta/claude-setup/.claude .claude --force` (it skips files that aren't templates).

---

## Hard rules

1. **Never delete `knowledge/` or `learning/`.** Those represent accumulated wisdom — they survive resets.
2. **Never overwrite manual customizations without asking.** Always diff and confirm.
3. **Update `.bootstrap-state.json` after every evolution.** Record what changed and when.
4. **Idempotent.** Running `/evolve-claude` twice in a row should find no changes the second time (unless new violations accumulated between runs).
5. **One batched proposal in default mode.** Never chain `AskUserQuestion` calls.

$ARGUMENTS
