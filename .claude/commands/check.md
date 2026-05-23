---
description: Run all project quality validations and automatically fix any issues found.
---

# Quality Check

Run all project quality validations and automatically fix any issues found.

This skill is invoked by `/finish-task` after `/code-review` to confirm the code passes type, lint, format, and test gates before opening the PR.

**Loop philosophy.** This skill enforces the "loop until clean" half of the BABYSIT contract. Combined with the per-specialist self-audit loop and `/finish-task` Phase 6, it guarantees no code reaches PR review without a green local validation. The contract is: *fix the code, not the gate*.

---

## Commands to run

Read `.claude/patterns/BASELINE.md` § Commands for the project's actual commands. The bootstrap fills these in. The general shape is:

| Step | Typical command | Notes |
|---|---|---|
| 1. Type check | (project-specific) | E.g. `yarn type-check`, `npm run typecheck`, `tsc --noEmit` |
| 2. Lint | (project-specific) | E.g. `yarn lint`, `npm run lint`, `eslint .` |
| 3. Format | (project-specific) | E.g. `yarn format:check` → `yarn format` if it fails |
| 4. Unit tests | (project-specific) | E.g. `yarn test`, `vitest run`, `jest` |
| 5. E2E tests (conditional) | (project-specific) | Only if frontend files changed AND e2e is configured |

If a step is not configured in BASELINE, skip it silently.

---

## Steps

Execute sequentially. If a step fails:
1. Analyze the errors.
2. Fix the underlying code.
3. Re-run.

Up to **3 retry attempts per step**. If still failing, surface the failure via `AskUserQuestion`.

**Never** disable a rule, weaken an assertion, or comment out a test to make a step pass — fix the underlying code.

### Rules

- **Never** use `any` to fix a type error. Use `unknown` and narrow.
- **Never** disable an ESLint rule without explicit user approval.
- **Never** `waitForTimeout` to "fix" a flaky e2e test — fix the real selector / wait condition.
- If a test is genuinely outdated (the spec changed), update it and mention it in the PR body.

---

## Final Summary

Present:

| Check | Status | Attempts | Fixes applied |
|-------|--------|----------|---------------|

If everything passes on the first try: "All checks passed without issues."

If there were fixes, briefly list what was changed in each file (file:line + nature of fix).

---

## Telemetry

If you applied a fix during the loop that maps to a BASELINE rule or a code-review checklist code, append a line to `.claude/learning/violations.md`:

```
| YYYY-MM-DD | <code> | check | <one-sentence context> |
```

This drives BASELINE evolution: codes that recur get promoted into hooks or BASELINE itself via `/evolve-claude`.

$ARGUMENTS
