---
description: Read-only normalization audit. Scans an existing module / file / PR for drift against the project patterns and returns a severity-graded report (uses the code-auditor subagent in an isolated context). Use when the user wants to know "what should we clean up here" without implementing anything.
---

# Normalize

You orchestrate a **read-only normalization audit** by dispatching the `code-auditor` subagent with a clear scope, then presenting the report and offering a focused fix path.

This skill **does not modify files**. Its only deliverable is a report. After the report, the user decides which findings to fix and which specialist to invoke for the implementation.

---

## Inputs

`$ARGUMENTS` may be empty, a path, a module, or a free-form description. Resolve as follows:

| Input | Resolution |
|---|---|
| Empty | Ask the user **one** question: "Which scope? (a) the changed files in this branch vs the base branch, (b) a specific module or file, (c) the most recent PR. Pick one." |
| A concrete path | Use as-is. |
| Module name | Resolve to the project's modules root (defined in BASELINE) + the module name. Inspect both backend and frontend trees if both exist. |
| `pr` / `branch` / `diff` | Run `git diff --name-only origin/<base>...HEAD` and pass the file list as the scope. |
| Anything else | Ask one batched clarifying question. |

If the resolved scope expands to **>40 files**, refuse and propose a narrower target.

---

## Workflow

### Step 1 — Resolve scope

1. If `$ARGUMENTS` is unclear, ask one batched question and wait.
2. If `pr` / `branch` / `diff`: `git fetch origin <base> --prune` then `git diff --name-only origin/<base>...HEAD`. If empty → abort with "Nothing to normalize — branch matches base."
3. Print the resolved scope:
   > Auditing N files in `<scope>`. Mode: `full` (Critical + High + Medium + Low + Coverage).

### Step 2 — Dispatch the auditor

Invoke the `code-auditor` subagent (via the `Agent` tool with `subagent_type: code-auditor`). Pass:

- The exact list of files (or the module path) as the scope.
- The mode (default `full`; if `>20 files`, suggest `quick`).

The subagent runs in an isolated context. It does its own reading. You don't pre-read the files yourself.

### Step 3 — Relay the report

Print the auditor's report verbatim. Append:

```markdown
### Suggested next steps
- Critical first (`N` items). Each one would block PR merge per `code-review-checklist.md`.
- For Critical/High items concentrated in a single layer, hand off to the matching specialist.
- For coverage gaps, hand off to the project's test specialist.
```

### Step 4 — Offer to dispatch the fix

Ask one batched question via `AskUserQuestion` (only when there's at least one Critical/High finding):

> "Which findings should I fix now?"
> Options: `All Critical`, `All Critical + High`, `Pick specific items`, `None — I'll handle manually`.

If the user picks a fix mode, hand off to the right specialist via the `Skill` tool. The specialist applies the fixes and ends with `/finish-task` per the standard lifecycle.

If `None`, stop.

---

## Hard rules

1. **Read-only.** This skill **never** edits files itself.
2. **No `/finish-task` from this skill** unless a downstream specialist was dispatched.
3. **Don't echo files into the conversation.** The auditor reads them in its own context.
4. **Severity matches the checklist.** Relay verbatim — don't paraphrase severities.

$ARGUMENTS
