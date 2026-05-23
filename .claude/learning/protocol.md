# Learning Protocol

The contract every agent follows for accumulating wisdom and logging telemetry.

## Two activities

| Activity | Where the output goes | When |
|---|---|---|
| **Telemetry** — every Critical/High finding | `.claude/learning/violations.md` | At the moment the finding is reported (even if it's fixed right after) |
| **Knowledge** — genuinely new insights | `.claude/knowledge/<topic>.md` | At the end of the task, after reflection |

## Telemetry rules

1. **Mandatory.** Every Critical/High finding from `code-auditor`, `code-reviewer`, `duck-challenger`, or `/check`'s auto-fixes is appended to `violations.md`.
2. **Append-only.** Never edit past lines.
3. **No PII.** Use paths and behavior descriptions.
4. **Format:**
   ```
   | YYYY-MM-DD | CODE | source-agent | one-sentence context |
   ```

The `/evolve-claude` skill reads this file to propose promotions (codes recurring ≥5× in 30 days become hook candidates).

## Knowledge rules

1. **Selective.** Most tasks teach nothing new — don't manufacture insights to fill the file.
2. **Three gates before writing:**
   - Is it **new**? (Not duplicated, not derivable from the code itself in under a minute.)
   - Is it **actionable**? (Future-me uses it in 30 seconds.)
   - Is it **project-specific**? (Generic clean-code wisdom doesn't belong here.)
3. **Format per entry:**
   ```markdown
   ### [High] / [Medium] / [Low] — short title
   _Dated YYYY-MM-DD._
   
   One paragraph describing the rule, the trigger, and the action.
   ```
4. **Decay.** Entries not activated in 60+ days get flagged `[STALE]` by `/evolve-claude` and are removed (with user approval) when they pile up.

## Step N-1 of each specialist's workflow

Right before handoff, the specialist reflects:

1. Did I discover something during this task that future-me would want to know?
2. If yes → write it into the right knowledge file under the right section.
3. Did `code-auditor` / `code-reviewer` flag any Critical/High codes? → ensure they appended to `violations.md`. If they forgot, write the missing lines.

## Loading knowledge at task start

Every specialist's Step 0 is:

```
1. Read .claude/patterns/BASELINE.md
2. Read .claude/patterns/<per-layer-doc>.md
3. Read .claude/knowledge/<specialist-name>.md if it exists
4. Tail .claude/learning/violations.md (last 10 entries) for recent recurring codes
5. Print a one-line "Knowledge activated" statement so the user can see what's in scope
```

The mandatory print enforces the discipline. An agent that loads but doesn't activate is just as bad as one that didn't load at all.
