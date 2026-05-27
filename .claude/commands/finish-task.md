---
description: Finalizes a task by running test coverage gate, code review, validating all tests (with auto-fix retry loop), and opening a PR to the base branch. Invoke at the END of every worktree-mode implementation task.
---

# Finish Task — Orchestrator

You are the **task finisher**. You run the last phases of the task lifecycle:

- **Phase 4.5** — Test coverage gate (if mandatory specs are defined in BASELINE)
- **Phase 5** — Code review (`/code-review`)
- **Phase 6** — Test validation loop with auto-fix (`/check`)
- **Phase 7** — PR to the base branch (`/finish`)

Your job is to make sure no task ships without specs + review + green tests. You are the last gate before a PR opens.

The bootstrap-generated `.claude/patterns/BASELINE.md` defines:
- The **base branch** (typically `develop` or `main`) — the PR target.
- Whether **test coverage** is mandatory and which file suffixes require co-located specs.
- Which **test commands** to run for the project.
- Whether **e2e tests** exist and which path triggers them.

Read those values from BASELINE before running.

---

## Preflight

1. Run `git status` and `git diff --stat` to confirm there are uncommitted changes.
   - If clean: abort with **"Nothing to finish — no changes in the working tree."**
2. Run `git branch --show-current` to confirm you are on a feature branch (not the base branch).
   - If on the base branch: abort with **"Refusing to finish — not on a feature branch."**
3. Run `git diff --name-only origin/<base>...HEAD` and cache the list of changed files. You will use it to decide whether e2e tests are needed.
4. Create a task list so the user sees progress:
   - "Verify test coverage"
   - "Run code review"
   - "Validate tests (type-check, lint, unit, e2e)"
   - "Open PR to base branch"

---

## Phase 4.5 — Test coverage gate (blocking, if enabled)

If `.claude/hooks/check-test-coverage.sh` exists (configured by the bootstrap):

1. Mark the first task as `in_progress`.
2. Run:
   ```bash
   bash "$CLAUDE_PROJECT_DIR/.claude/hooks/check-test-coverage.sh"
   ```
3. Decision:
   - **Exit 0** → mark `completed`, proceed.
   - **Exit 2** → the script printed the missing specs to stderr. Stop and:
     - Invoke the project's test specialist (`/test` if present, otherwise the relevant implementing specialist) with the list of files. **Never** disable the gate or weaken the spec to make it pass.
     - If a missing test is genuinely out of scope, use `AskUserQuestion` to confirm a documented skip (PR body must list the skipped files with reason).

If the script doesn't exist, skip this phase silently.

---

## Phase 5 — Code review (final independent gate)

This is the **third independent eye** on the change. The implementer already ran levels 1 (`code-auditor`) and 2 (`code-reviewer`) inside the BABYSIT loop, and possibly level 3 (`/duck-debug`). Running `/code-review` here means re-running the **semantic reviewer subagent in a fresh isolated context** — pure adversarial review.

1. Mark the second task as `in_progress`.
2. Invoke `/code-review` via the `Skill` tool.
3. Parse findings by severity: **critical**, **high**, **medium**, **low**, **nitpick**.
4. Decision rules:
   - **No critical/high findings** → proceed to phase 6.
   - **Critical or high findings that you can safely auto-fix** (typos, obvious bugs, missing null checks, forgotten awaits): apply the fixes, then re-run `/code-review` **once**.
   - **Critical or high findings that require judgment**: present them verbatim and use `AskUserQuestion` to decide:
     - "Auto-fix and continue"
     - "Address manually then continue"
     - "Accept and proceed" — document in PR body
5. Mark the second task as `completed`.

**Telemetry note.** Every Critical/High finding the reviewer reports — even ones auto-fixed — must be appended to `.claude/learning/violations.md`. The reviewer subagent appends these itself; verify the file was updated.

---

## Phase 6 — Test validation loop (max 3 attempts)

This is the most important gate. Tests MUST pass before the PR is opened.

1. Mark the third task as `in_progress`.
2. Decide which test suites to run based on the cached `git diff --name-only` and the BASELINE-documented test commands:
   - **Always**: the project's `type-check`, `lint`, and `test` commands (from BASELINE § Commands).
   - **If frontend files changed and e2e is configured**: also the e2e command.
3. **Attempt loop** (up to 3 attempts):

   ```
   attempt = 1
   while attempt <= 3:
     run the selected commands in sequence
     if all pass: break
     else:
       - read the failure output
       - identify the failing file(s) and the root cause
       - apply a focused fix (fix the code, NOT the test, unless the test is genuinely outdated)
       - attempt += 1
   ```

4. **On success**: mark `completed`. Proceed to phase 7.
5. **On 3 failed attempts**: stop the loop. Use `AskUserQuestion`:
   - "Retry with more context"
   - "Hand back to me" — abort `/finish-task`
   - "Skip gate and PR anyway" — requires explicit confirmation, document in PR body

### Rules for the test loop
- **Never** disable or skip a test to make it green. Fix the code.
- **Never** weaken an assertion to make it pass.
- If a test is genuinely outdated, update it and mention it in the PR body.

---

## Phase 7 — PR to base branch

1. Mark the fourth task as `in_progress`.
2. **Resolve the spec.** Look for `.claude/specs/<slug>/spec.md` (or `brief.md`) using the branch name's slug, the ticket ID, or a `spec_path=` hint passed from the specialist. If found, capture the path — it goes in the PR body. If not found and BASELINE § Spec discipline = `required`, abort with *"Sem spec em `.claude/specs/`. Rode `/spec <slug>` antes do PR (ou ajuste a policy)."*
3. Invoke the existing `/finish` skill using the `Skill` tool, passing `spec_path` so it can include the spec link + scope/behavior summary in the PR body. `/finish` handles:
   - Staging and committing changes with a conventional-commit message
   - Pushing to origin
   - Creating the PR against the configured base branch — the body MUST include a `**Spec:** [.claude/specs/<slug>/spec.md](relative-link) (Status: implementing)` line at the top
   - (If the project integrates with a tracker) commenting the PR link on the ticket and transitioning status
4. After PR opens, **update the spec's status** from `approved`/`implementing` to `implementing` (or `shipped` once `/cleanup-task` runs after merge). Append `PR: <url>` under § 10 Links.
5. Capture the PR URL returned by `/finish`.
6. Mark the fourth task as `completed`.

---

## Final report

```
Task finished.

  Coverage:     <ok | bypassed (N files, reason) | not configured>
  Code review:  <N findings addressed, M accepted>
  Tests:        type-check ✓  lint ✓  unit ✓  e2e <✓|skipped|not configured>
  PR:           <url>
  Ticket:      <id> → <new status if configured>
```

If any phase was skipped with user consent, mention it explicitly.

---

## Error handling

- If a phase fails catastrophically (tool crash, network error, git conflict), stop and report the error. Do **not** continue.
- If `/finish` fails at PR creation, report the existing PR URL (if any) and stop.
- Never leave the working tree in a partially-staged state.
