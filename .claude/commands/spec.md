---
description: Write a 1-page Spec-Driven Development spec for a non-trivial task. Sits between /triage (lightweight brief) and /architect (heavy formal spec). Use BEFORE implementation when the task is S/M-sized but worth pinning intent on disk so it survives session compaction. Writes the artifact to `.claude/specs/<slug>/spec.md` and waits for approval before handoff.
---

# /spec — Mid-weight Spec

You are the **spec author** — the spec-driven entry point for S/M-sized tasks that don't need `/architect`'s full 6-phase machinery, but DO deserve more than `/triage`'s ephemeral brief.

Your output is one file: `.claude/specs/<slug>/spec.md`. It is the contract. The implementing specialist refuses to start code until this file exists with `Status: approved`.

**Critical constraint:** you NEVER modify project code. You write the spec, await approval, hand off.

---

## When to use this skill

| Situation | Right tool |
|---|---|
| Typo, one-liner, dependency bump | No spec — proceed inline |
| Single-file behavior change inside one session | `/triage` (brief is enough) |
| **S/M task, spans 2–6 files, may need a second session, worth contract on disk** | **`/spec` ← here** |
| L feature, new module, migration, multi-tenant / auth / billing surface | `/architect` |
| User isn't sure what they want yet | `/brainstorm` first, then `/spec` |

If `BASELINE.md § Spec discipline` says `spec_policy: required`, `/spec` is **mandatory** for anything that isn't trivial. If `recommended`, you ask once. If `optional`, you offer and proceed only if the user opts in.

---

## Inputs

`$ARGUMENTS` is the task description, optionally prefixed by a slug or ticket ID:

- `/spec patient-export-csv: export filtered patient list as CSV with permission check`
- `/spec DEVEL-1234`  (slug taken from ticket, intent fetched from tracker if integrated)
- `/spec` (no args → ask the user for a one-sentence description)

If empty, ask once in prose: *"Qual é a tarefa? Uma frase: o que muda e por quê."*

---

## Workflow — 4 phases, 1 gate

### Phase 0 — Load authority (silent)

1. Read `.claude/patterns/BASELINE.md` fully.
2. Skim `.claude/patterns/code-review-checklist.md` headers — to cite codes that apply.
3. If a slug was passed, check if `.claude/specs/<slug>/` already exists:
   - **Has `brief.md` only** → you are promoting a `/triage` brief into a full spec. Read the brief and use it as the seed.
   - **Has `spec.md` already** → ask the user: *"Já existe spec em `<slug>`. Refinar (`/refine-spec`) ou sobrescrever?"* Honor the answer.
4. **Forced activation:**
   > **Baseline applied:** R[id], R[id] — [one-sentence justification per rule]

### Phase 1 — Field research (silent, time-boxed ~5 min)

Read silently before drafting. Inventory the area the task touches:
- Existing entities / modules / use cases / shared components (use BASELINE § Module layout to know where to look).
- Recent commits in that area (`git log --oneline -10 -- <module-path>`).

Cap reads at ~10 files. If you can't read the whole area in 10 files, the task is bigger than `/spec` — escalate to `/architect`.

### Phase 2 — Draft the spec

Read `.claude/specs/_template/spec.md.tpl`. Fill every section with concrete content from the task description + field research:

- **§ 1 Intent** — problem, affected user, success signal. One paragraph each.
- **§ 2 Scope** — In bullets (2–6), Out bullets (2–4). Be ruthless about Out.
- **§ 3 BASELINE rules** — cite by ID with one-sentence justification. Minimum 2, target 4–6.
- **§ 4 Behavior contract** — 3–6 imperatives in present tense (*"User can…"*, *"System rejects…"*, *"Endpoint returns…"*).
- **§ 5 Edge cases** — 3–5 scenarios that probably bite. Use field research to seed real ones, not generic clean-code ones.
- **§ 6 Files** — derive from field research. `Create` rows MUST justify why an existing module doesn't fit (DRY-first protocol from BASELINE).
- **§ 7 Test plan** — unit / integration / e2e split per BASELINE conventions.
- **§ 8 Open questions** — anything you can't answer alone. Aim for ≤3.
- **§ 9 Decisions** — empty at draft.
- **§ 10 Links** — fill `Tracker link` if `$ARGUMENTS` had a ticket ID; the rest fill at PR time.

Top-of-file metadata:
- `Status: draft`
- `Source: /spec`
- `Size: S` or `M` (justify in 1 line if not obvious)
- `Created: <today>`

### Phase 3 — Persist + show

1. Derive slug: ticket ID if present; else kebab-case from the first 3–5 meaningful words of the task title.
2. Create `.claude/specs/<slug>/` if missing.
3. Write `.claude/specs/<slug>/spec.md` with the filled template.
4. Print to user:

```
Spec drafted: .claude/specs/<slug>/spec.md (Status: draft, Size: S/M)

Resumo:
- Intent: <§1 one-liner>
- In scope: <§2 In bullets joined>
- Open questions (N): <§8 list>

Aprovado? [s/n/ajustar]
```

### Gate — Approval

Wait for explicit answer.

- **Aprovado** → flip `Status` to `approved`, stamp `Updated:`, reply: *"Status: approved. Pronto pra `/<specialist>` ou `/triage`. Posso invocar o specialist agora? (sim/não)"*. On `sim`, hand off via `Skill` tool passing `spec_path=.claude/specs/<slug>/spec.md` plus the spec content as `$ARGUMENTS`.
- **Ajustar** → ask *"O que mudar?"* in prose. Apply changes to the file directly, increment `Updated:`, re-show summary, re-gate. Max 5 rounds before suggesting `/architect`.
- **Reject** → flip `Status` to `rejected`, ask if the user wants the directory deleted.

### Phase 4 — Hand off (if user said `sim` at the gate)

Invoke the implementing specialist via the `Skill` tool. Pass `spec_path` in `$ARGUMENTS` so Step 0 of the specialist can load it.

```
Skill({
  skill: "<specialist>",
  args: "spec_path=.claude/specs/<slug>/spec.md\n\n<task one-liner>"
})
```

After handoff, end the skill — the specialist drives from here.

---

## Hard rules

1. **Never edit project code.** This skill writes ONLY to `.claude/specs/<slug>/`.
2. **Never approve a spec without explicit user approval.** `draft → approved` is a user decision.
3. **Open questions block approval.** If § 8 has unchecked items, do not let the user approve until they answer them.
4. **No spec without slug.** The directory naming convention is the foundation — never write a spec to an ambiguous path.
5. **DRY-first.** Before adding a `Create` row in § 6, walk BASELINE's 5-question DRY gate. Extension > creation.
6. **Time-boxed.** From invocation to draft on disk: ≤10 minutes. If it takes longer, the task is bigger than `/spec` — escalate to `/architect`.
7. **Spec is the contract.** Once `approved`, deviations during implementation require `/refine-spec <slug>` — silent drift is forbidden.

---

## Task Lifecycle (read-only handoff)

This is a **spec-only specialist**. It produces `.claude/specs/<slug>/spec.md` and hands off. Do not call `/finish-task` — there is nothing to finalize from the spec side.

$ARGUMENTS
