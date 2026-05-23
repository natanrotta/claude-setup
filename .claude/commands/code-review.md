---
description: Code review skill. Thin wrapper that delegates to the `code-reviewer` subagent so the review runs in an isolated context and never pollutes the orchestrator's window. Anchored on the project anti-pattern checklist; produces a structured severity-grouped report with actionable suggestions.
---

# /code-review

This skill is a **thin orchestrator**. The actual review is performed by the `code-reviewer` subagent (`.claude/agents/code-reviewer.md`), which loads the patterns docs once in an isolated context window. Your job here is to (1) figure out the scope, (2) invoke the subagent with that scope, (3) relay its report back, and (4) ensure telemetry is written.

The heavy lifting — checklist walks, severity rubric, design-observations, proposed-checklist-additions — lives in the subagent. Do not duplicate it here.

---

## Workflow

### Phase 1 — Determine the scope

Look in `$ARGUMENTS` first. If absent, infer:

1. **In a babysit loop?** Use the in-progress diff: `git diff --name-only origin/<base>...HEAD`. Default.
2. **`/finish-task` Phase 5?** Same as above.
3. **User asked to review something specific?** Use that scope.

If genuinely ambiguous, ask **one** batched question:

> "Review what? (a) current task diff vs base, (b) a specific file or module, (c) a PR range."

### Phase 2 — Invoke the subagent

Spawn the `code-reviewer` subagent via the `Agent` tool:

```
Scope: <diff list OR file path OR module path OR range>
Mode: <full | quick — default full>
Context: <one sentence on what the implementer was trying to do>
```

Capture the full report.

### Phase 3 — Relay the report

Print the subagent's report **verbatim**. Do not paraphrase or re-score severity.

### Phase 4 — Telemetry verification

The subagent appends Critical/High findings to `.claude/learning/violations.md` itself. Verify with `Bash` `git diff --name-only` that the file was updated. If not, append the missing lines yourself:

```
| YYYY-MM-DD | <code> | code-reviewer | <one-sentence context> |
```

### Phase 5 — Follow-up

If the user asks for a fix, **do not patch the code yourself**. Either:
- Recommend invoking the implementing specialist; or
- Exit this skill and hand the fix off.

`/code-review` stays read-only.

---

## Hard rules

1. **Always delegate to the subagent.** Do not run the checklist walk inline.
2. **Do not re-score severity.**
3. **Telemetry is non-negotiable.**
4. **One subagent invocation per call.**

$ARGUMENTS
