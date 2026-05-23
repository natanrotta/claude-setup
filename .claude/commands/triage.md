---
description: Tri-perspective intake gate. Runs Architect + Engineer + Product subagents in parallel against the codebase, batches every open question into ONE AskUserQuestion, and produces a unified pre-dev brief. Use BEFORE invoking an implementing specialist on any non-trivial task in worktree mode (and optionally in inline mode when the user wants the challenge).
---

# Triage — Pre-Dev Gate

You are the **triage orchestrator**. Your job is to run three perspectives over the user's task in parallel — architect, engineer, product — collect their open questions into a single batched `AskUserQuestion`, and produce a unified brief the implementing specialist will consume.

This is the **lightweight 80% gate** — fast, parallel, structured. Reserved for production-shaped tasks. Not a substitute for `/architect` (heavy formal spec) or `/brainstorm` (divergent design exploration).

---

## When to use

| Mode | Run `/triage`? |
|---|---|
| **Worktree mode**, non-trivial task (anything beyond a typo / one-line change) | **Yes — mandatory** as Phase 1.5 between `/start-task` and the implementing specialist |
| **Worktree mode**, trivial fix the user is explicit about | Skip |
| **Inline mode**, user describes a real change | Optional — run only if the change spans multiple files OR the user asks "me ajuda a pensar antes" / "questiona isso" |
| **Question / meta-work / debugging without edits** | Skip |
| **Architectural feature** (new module, migration, auth, payments) | Skip `/triage`, go straight to `/architect` |

If unsure, run it — the cost is low and the brief is reused by the specialist for free.

---

## Inputs

`$ARGUMENTS` is the user's task brief — the same text that would normally route directly to a specialist. Verbatim, no edits.

If `$ARGUMENTS` is empty, ask the user once: "Qual é a tarefa que você quer triar?" Then proceed.

---

## Workflow

### Step 1 — Spawn the three perspectives in parallel

Use a **single message with three `Agent` tool calls** so they run concurrently. Each subagent gets the same `task_brief`, so they have equal context.

```
Agent({
  description: "Architect triage",
  subagent_type: "triage-architect",
  prompt: "task_brief: \"<the user's brief verbatim>\"\n\nProduce your structured brief per your skill definition. Be surgical and time-boxed."
})

Agent({
  description: "Engineer triage",
  subagent_type: "triage-engineer",
  prompt: "task_brief: \"<the user's brief verbatim>\"\n\nProduce your structured brief per your skill definition. Be surgical and time-boxed."
})

Agent({
  description: "Product triage",
  subagent_type: "triage-product",
  prompt: "task_brief: \"<the user's brief verbatim>\"\n\nProduce your structured brief per your skill definition. Be surgical and time-boxed."
})
```

Wait for all three to return. They should each respond in under 5 minutes; if one is significantly slower, that's a signal the task is bigger than triage can handle — see the escalation rule below.

### Step 2 — Show the three briefs

Print each brief verbatim under a labeled header so the user can see the three perspectives:

```markdown
# Triage briefs

## Architect
<architect brief>

## Engineer
<engineer brief>

## Product
<product brief>
```

Do not paraphrase. The user reads the three briefs as-is. If a brief failed to follow its template, note it but proceed.

### Step 3 — Batch the open questions

Each subagent surfaced up to 2–3 open questions. Collect them all (deduplicate when two ask the same thing in different words), then present them in a single `AskUserQuestion` call with at most **5 questions total**. Each question MUST have a `(Recommended)` default.

If the three subagents collectively produced **zero** open questions, skip this step entirely — the brief is ready and you can go straight to Step 4.

If they produced **more than 5**, drop the lowest-impact ones.

After the user answers, capture each answer (including `default` choices) in a confirmation block:

```markdown
## Triage decisions

| # | Topic | Decision |
|---|-------|----------|
| 1 | [topic] | [user answer] |
```

### Step 4 — Produce the unified pre-dev brief

Synthesize the three briefs + the answered questions into the canonical handoff. Output **exactly** this structure:

```markdown
# Pre-dev brief — [3-6 word task summary]

## Specialist
- `[/backend | /frontend | /fullstack | /ai-backend | other]`
- Reason: [one sentence]

## Outcome
- [one sentence — the success metric from the Product brief, refined by user answers]

## Scope
- **In:** [bullets from Product MVP cut, refined by answers]
- **Out:** [bullets — explicit deferrals]

## Reuse map (DRY first)
[verbatim from Engineer's reuse map; trim columns if needed]

## Files
- **Create:** [bullets from Engineer brief]
- **Modify:** [bullets from Engineer brief]

## Test plan
[verbatim from Engineer brief]

## Baseline rules to enforce
- R[id]: [one-sentence note]
- ... (union of Architect's and Engineer's lists, dedup'd)

## Risks
- **Architectural:** [bullets from Architect — empty if none]
- **UX:** [bullets from Product — empty if none]
- **Edge cases that probably bite:** [bullets from Product — top 3]

## Triage decisions
[verbatim from Step 3 if questions were asked; "No open questions — three perspectives agreed." otherwise]
```

Cap the whole brief at **80 lines**.

### Step 5 — Hand off to the specialist

Invoke the recommended specialist via the `Skill` tool, passing the **entire pre-dev brief** as `$ARGUMENTS`.

```
Skill({
  skill: "<specialist name>",
  args: "<the unified pre-dev brief verbatim>"
})
```

After the specialist returns, the lifecycle continues normally (`/finish-task` for worktree mode; stop for inline mode).

---

## Escalation rules

- **Architect brief flags risk class High** → stop. Tell the user: *"Architect classified this as High risk. Recommend `/architect` for a full spec before implementation."* Wait for confirmation.
- **Engineer brief estimates size L** (≥16 files) → same escalation: route to `/architect`.
- **Product brief lists ≥5 edge cases that bite, OR the MVP cut is genuinely ambiguous** → loop back to Product with a follow-up clarification question (max 2 questions, one round). If still ambiguous, escalate to `/brainstorm` for divergent exploration.
- **Two of the three briefs disagree on layer/specialist** → flag the disagreement to the user as one of the open questions. Do not silently pick a side.

---

## Hard rules

1. **Parallel by default.** Three subagents in one message, never sequentially.
2. **One question batch.** All open questions in a single `AskUserQuestion` call. Never loop into question-then-question.
3. **Brief is the contract.** The unified pre-dev brief is what the specialist consumes — never paraphrase it on the way to the specialist.
4. **No code, ever.** `/triage` is read-only. It produces a brief and hands off; it never edits files.
5. **Time-boxed.** ≤ 10 minutes from invocation to handoff. If it takes longer, the task is bigger than triage can handle — escalate.

$ARGUMENTS
