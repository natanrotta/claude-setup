---
description: Starts a new task by creating a git worktree + branch from the configured base branch (develop or main), then immediately continues the work in the SAME Claude Code session. Invoked ONLY when the user explicitly asks for a worktree.
---

# Start Task — Orchestrator

You start a new task in **worktree mode**. Your job is **Phase 0** of the task lifecycle: create an isolated git worktree + branch from the configured base branch (typically `develop` or `main`), prepare it for work (env files + deps), and then **continue the entire task in the current Claude Code session** with the worktree as the working directory.

Do NOT open a new editor window. Do NOT write a handoff file. There is no handoff — it's the same conversation from `/start-task` all the way to the PR.

**Important:** this command should only run when the user explicitly asked for a new worktree/branch. If the user just described a change without asking for a worktree, the orchestrator stays in inline mode (current branch, no PR) and does NOT call `/start-task`.

Arguments: `$ARGUMENTS` — can be:
- A full task description in natural language (preferred, zero-friction path)
- A ticket ID alone (e.g. `JIRA-1234`)
- A ticket ID + short description
- Empty — ask the user

The bootstrap-generated `.claude/patterns/BASELINE.md` § Project layout documents:
- **Main checkout path** (where the user clones the project)
- **Worktrees parent path** (where new worktrees are created)
- **Base branch** for new task branches (`develop` or `main`)
- **Package manager** for the dependency install step (`yarn`, `npm`, `pnpm`, `bun`, or `none`)

Read those values from BASELINE before running the steps below.

---

## Steps

### 1. Confirm we are on the main checkout, not inside a worktree

Run `git rev-parse --show-toplevel` and `git rev-parse --git-common-dir`.

- If `show-toplevel` is NOT the main checkout: the user is already inside a worktree. Abort with a clear message telling them to run from the main checkout.

### 2. Fetch latest base branch

```bash
git fetch origin <base-branch> --prune
```

Do **not** check out the base branch — we will branch from `origin/<base-branch>` directly, which leaves the user's current branch alone.

### 3. Resolve branch name

Parse `$ARGUMENTS`. Keep the **full original text** as the `TASK_BRIEF` variable.

- **If it contains a ticket ID** (regex: `[A-Z]+-\d+`):
  - Extract the ticket ID.
  - Use the rest of the text (if any) as the short description. If empty, derive a 3–6 word English summary from the `TASK_BRIEF`.
  - Branch name: `feature/<ticket-id>-<slug>` where `<slug>` = description lowercased, spaces → hyphens, stripped of non-alphanumerics.

- **If there is no ticket ID in `$ARGUMENTS`**:
  - **Do not ask.** Derive a 3–6 word English slug from the `TASK_BRIEF` and use branch = `<prefix>/<slug>` (no ticket ID).

- **If `$ARGUMENTS` is empty entirely**:
  - Only in this case, ask the user for a one-sentence description of the task.

**Prefix inference (decide, don't ask):**
- "bug", "fix", "regressão", "quebrado", "não funciona", "erro" → `fix/`
- "refactor", "limpar", "simplificar" → `refactor/`
- "chore", "upgrade", "dependência", "configurar" → `chore/`
- Otherwise default to `feature/`
- **Never ask the user to disambiguate the prefix.**

### 4. Create the worktree

Worktree path (from BASELINE):
```
<worktrees-parent>/<branch-name-sanitized>
```

Where `<branch-name-sanitized>` replaces `/` with `+`.

```bash
mkdir -p <worktrees-parent>
git worktree add <worktrees-parent>/<sanitized> -b <branch> origin/<base-branch>
```

If `git worktree add` fails because the branch already exists, ask the user:
- Reuse the existing branch (use `git worktree add <path> <branch>` without `-b`), or
- Abort.

### 5. Copy environment files (if any are listed in BASELINE § Local files to seed)

```bash
MAIN=<main-checkout-path>
WT=<worktree-path>
for f in <files listed in BASELINE>; do
  if [ -f "$MAIN/$f" ]; then mkdir -p "$(dirname "$WT/$f")"; cp "$MAIN/$f" "$WT/$f"; fi
done
```

Skip silently any file that doesn't exist.

### 6. Install dependencies in the worktree

If BASELINE specifies a package manager, run its install command:

```bash
cd <worktree-path> && <install-command>
```

Examples: `yarn install --frozen-lockfile`, `npm ci`, `pnpm install --frozen-lockfile`, `bun install --frozen-lockfile`.

If no package manager is configured, skip this step.

### 7. Announce the handoff — to YOURSELF, in the same session

Print a short summary:

```
Worktree ready:
  Branch:    <branch-name>
  Path:      <worktree-path>
  Based on:  origin/<base-branch> @ <short-sha>

Continuing in this session. All subsequent file reads, edits, and commands
will target the worktree path above. After implementation I'll run /finish-task,
and after the PR is merged you can run /cleanup-task.
```

### 8. Proceed with the task IN THIS SESSION

**Critical:** Do NOT stop. Do NOT open a new editor window.

Immediately continue with the task lifecycle in the current conversation:

1. **Invoke `/triage`** with the `TASK_BRIEF` as arguments. Triage runs three perspectives in parallel and produces the pre-dev brief.
2. **The triage hands off to the recommended specialist.** All tool calls from this point on must target the worktree path:
   - Absolute paths rooted at the worktree for `Read`, `Edit`, `Write`, `Glob`, `Grep`.
   - `cd <worktree-path> && …` for `Bash` commands that must run with the worktree as cwd.
   - Never edit files in the main checkout from a worktree task.
3. After implementation, invoke `/finish-task` from the worktree directory.
4. After the PR is merged, the user runs `/cleanup-task` from anywhere.

---

## Notes

- Worktrees share `.git` but NOT `node_modules`. The install step in #6 is non-optional unless the project is dependency-free.
- **Forbidden commands in this skill:** `code <path>`, `cursor <path>`, any editor-launch command.

$ARGUMENTS
