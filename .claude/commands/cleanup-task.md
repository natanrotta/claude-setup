---
description: Removes a worktree and its local branch after the PR has been merged. Use after /finish-task once the PR is merged on the base branch. Safe — confirms PR status before deleting.
---

# Cleanup Task — Orchestrator

You clean up a finished task: remove the git worktree, delete the local branch, and prune refs. This is **Phase 8** of the task lifecycle.

Arguments: `$ARGUMENTS` — optional branch name. If empty, target the current branch (if inside a worktree) or ask the user.

---

## Safety first

This command **deletes** a worktree and its branch. Be careful.

**Hard rules:**
- Never remove a worktree that has uncommitted changes or unpushed commits — abort and report.
- Never remove a worktree whose PR is still open and unmerged, unless the user explicitly confirms abandon.
- Never run `git branch -D` (force delete). Only `git branch -d` (safe delete).
- Never operate on the base branch (`develop` / `main` / whichever is configured in BASELINE).

---

## Steps

### 1. Determine the target branch and worktree

1. Run `git worktree list --porcelain` to get all worktrees.
2. If `$ARGUMENTS` contains a branch name, use it as the target.
3. If `$ARGUMENTS` is empty:
   - Run `git rev-parse --show-toplevel` and `git rev-parse --git-common-dir`.
   - If inside a worktree (toplevel ≠ main checkout), assume "the current worktree". Confirm with `AskUserQuestion`.
   - If in the main checkout with no argument: list all non-main worktrees via `AskUserQuestion` and let the user pick.
4. Resolve the worktree path and branch name from the worktree list.
5. **Abort if** the target branch is the base branch or the main checkout itself.

### 2. Verify the worktree is clean

```bash
git -C <wt> status --porcelain
git -C <wt> log @{u}.. --oneline 2>/dev/null
```

- If `status --porcelain` is non-empty: **abort** with "Worktree has uncommitted changes."
- If there are unpushed commits: warn via `AskUserQuestion` — proceed (lose commits) or abort.

### 3. Check PR status

If `gh` is available:

```bash
gh pr list --head <branch> --state all --json number,state,mergedAt,url
```

- **If no PR**: warn and ask — abandoned (proceed) or not finished (abort)?
- **If `OPEN`**: ask:
  - "PR is still open — abandon branch and close PR manually"
  - "Abort cleanup"
- **If `MERGED`**: proceed silently — happy path.
- **If `CLOSED` (not merged)**: ask — proceed or abort.

If `gh` is not available, just ask the user to confirm the PR is merged.

### 4. Exit the worktree if we're inside it

If the cwd is inside the worktree being removed, change to the main checkout first.

### 5. Remove the worktree

```bash
git worktree remove <worktree-path>
```

If this fails due to leftover files, fall back to:

```bash
git worktree remove --force <worktree-path>
```

Only after step 2 passed cleanly.

### 6. Delete the local branch

```bash
git branch -d <branch>
```

If it fails (branch not fully merged because PR was merged via squash/rebase), verify with `gh pr view <branch> --json state` that it's MERGED, and only then:

```bash
git branch -D <branch>
```

Do **not** force-delete without that verification.

### 7. Prune

```bash
git worktree prune
git fetch origin --prune
```

### 8. Report

```
Task cleaned up.

  Branch:    <branch>           (deleted)
  Worktree:  <path>              (removed)
  PR:        <url> (<state>)
  Remaining worktrees:
    <list>
```

---

## Error handling

- If any git command fails unexpectedly, stop, print the error, and do **not** attempt destructive fallbacks.
- Never silently ignore errors.

$ARGUMENTS
