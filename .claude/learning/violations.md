# Violations Ledger

This file accumulates **every Critical/High anti-pattern finding** that the auditor, reviewer, duck-challenger, or quality gates produce — even ones fixed in the same task. The append-only ledger is how the setup evolves: when the same code recurs ≥5 times in 30 days, `/evolve-claude` proposes promoting it into a hook regex or into BASELINE.

## Format

One line per finding:

```
| YYYY-MM-DD | CODE | source-agent | one-sentence context (no PII) |
```

Example:

```
| 2026-05-23 | B-C1     | code-auditor     | createPatient.use-case.ts:34 missing account_id in findFirst where |
| 2026-05-23 | F-C2     | code-auditor     | PatientCard.tsx:12 hardcoded #ffd700 in badge color |
| 2026-05-24 | X-C3     | code-reviewer    | new field added to schema.prisma but _first/migration.sql not regenerated |
| 2026-05-25 | (proposed) | duck-challenger | side-effect on no-op input in PhoneReplacementService.replace() |
```

## Append rules

- **Never edit existing lines.** This is an append-only log.
- **No PII in the context column.** Use file paths, code identifiers, and behavior descriptions only.
- **One line per finding, even if fixed immediately.** The signal of recurrence matters more than whether it was fixed.
- **Use `(proposed)` in the CODE column** when the finding doesn't match any existing checklist code yet. Recurring `(proposed)` entries are the queue for new codes.

## How `/evolve-claude` uses this file

The skill counts occurrences per code within the last 30 days. Codes with ≥5 hits become **promotion candidates** in the next `/evolve-claude` run.

---

<!-- Findings below. Most recent first. -->

| Date | Code | Source | Context |
|------|------|--------|---------|
| _(empty — fill as findings accumulate)_ | | | |
