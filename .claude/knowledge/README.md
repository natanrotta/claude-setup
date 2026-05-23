# knowledge/

This directory holds **per-agent / per-module accumulated wisdom**. It starts empty after bootstrap and grows as agents accumulate insights from real tasks.

## Files (will appear over time)

| File | Owned by | Captures |
|---|---|---|
| `brainstorm.md` | `/brainstorm` | Effective design approaches, question patterns, scope insights |
| `architect.md` | `/architect` | Field-research patterns, decision-round heuristics, estimation calibration |
| `triage.md` | `/triage` | Question patterns that revealed gotchas, perspective disagreements, common escalations |
| `code-review.md` | `code-reviewer` | Common violations, safe patterns, module-specific rules, false positives |
| `<specialist>.md` (e.g. `backend.md`, `frontend.md`) | implementing specialists | Stack-specific gotchas, reuse-first catalog hints, module conventions |
| `<module>.md` (e.g. `patients.md`, `payments.md`) | every specialist that touches that module | Domain rules, edge cases, integrations, business invariants |

## Section conventions

Each `.md` follows roughly the same shape:

```markdown
# Knowledge: <topic>

## Consolidated Principles
- [High] / [Medium] / [Low] confidence rules, dated.

## Common Violations / Safe Patterns / Dead Ends
- Specific entries tied to file paths and codes.

## Module-Specific Rules
- One subsection per module touched.
```

Confidence labels:
- `[High]` — confirmed across multiple tasks
- `[Medium]` — observed once, plausible
- `[Low]` — speculative, kept for future signal
- `[STALE]` — older than 60 days and no longer activated — candidate for removal

## How entries are created

Agents follow the protocol in `.claude/learning/protocol.md` (created on first use, if missing). After a task, they reflect:

1. **Did I discover something genuinely new?** Not duplicated, not trivially derivable from the code.
2. **Is it actionable?** Future-me can use it in 30 seconds.
3. **Is it project-specific?** Generic clean-code wisdom doesn't belong here.

If all three are yes, the agent writes a short entry (3-8 lines) under the right section.

## How entries decay

`/evolve-claude` periodically scans for stale entries (entries not activated in ≥60 days). It proposes archiving them. The user approves before deletion.

## Why this directory matters

Without accumulated knowledge, every task starts from zero. With it, the second task in a module gets the gotchas the first task discovered. By task ten, the specialist is operating with the wisdom of every prior pass through that surface.
