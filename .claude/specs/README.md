# `.claude/specs/` — Specs as the contract

This directory holds the **specifications** that drive implementation. Each non-trivial task lives under its own folder:

```
.claude/specs/
└── <task-slug-or-id>/
    ├── spec.md       # the intent: what, why, scope, rules, edge cases, tests
    └── brief.md      # optional: the /triage 3-perspective output, when used
```

---

## Why this exists

The project follows **Spec-Driven Development** (SDD): the spec is the source of truth, the code is the executable derivative. Without a written spec, the implementation drifts in the chat, gets lost on session compaction, and re-derives context every run — that's the failure mode of "vibe coding" and the reason token budgets explode.

A spec on disk:

- **Survives session compaction.** Specialists reload it instead of re-deriving the intent.
- **Acts as the audit anchor.** The auditor checks the diff against `## Scope` — anything outside is flagged.
- **Carries into the PR.** `/finish-task` links `specs/<slug>/spec.md` in the PR body, giving reviewers the contract for free.
- **Lives next to the code.** Renaming the feature renames the spec; refactoring the feature updates the spec.

---

## Who writes specs here

| Command | Artifact | Size |
|---|---|---|
| `/triage` | `brief.md` (3-perspective pre-dev brief) | XS — handoff inside one session |
| `/spec` | `spec.md` (1-page mid-weight spec) | S/M — the default for non-trivial tasks |
| `/architect` | `spec.md` (full technical specification) | L — new modules, migrations, sensitive surfaces |
| `/brainstorm` | `spec.md` (design exploration → converged spec) | varies |

Every implementing specialist loads `specs/<slug>/spec.md` (or `brief.md` if only triage ran) at **Step 0** and prints `Spec activated: <path>` before touching code.

---

## Slug convention

- **With ticket tracker**: use the ticket ID directly (`DEVEL-1234`, `LIN-456`, `gh-789`).
- **Without ticket tracker**: lowercase kebab-case derived from the feature name (`patient-export-csv`, `multi-tenant-billing`).
- **Quick fixes (≤2 files, no behavior change)**: skip the spec — the lifecycle allows it. Document the skip in the PR body.

---

## Spec lifecycle

```
draft ────▶ approved ────▶ implementing ────▶ shipped
   │            │                 │
   │            │                 └──▶ /refine-spec  (reality educated the spec)
   │            └──▶ pending changes (back to draft)
   └──▶ rejected (cancel task)
```

The `## Status` line at the top of `spec.md` tracks this. Specialists refuse to implement against `draft` or `rejected` specs.

---

## What lives here vs. elsewhere

| Belongs here | Belongs elsewhere |
|---|---|
| Per-task specs (`<slug>/spec.md`) | Project-wide rules → `.claude/patterns/BASELINE.md` |
| Per-task pre-dev briefs (`<slug>/brief.md`) | Module-level docs → `.claude/knowledge/<module>.md` |
| Spec status, scope, edge cases, test plan | Architectural decisions → `docs/decisions/NNNN-<slug>.md` |

If a spec accumulates rules that apply to *every* future task, promote them via `/evolve-claude` into `BASELINE.md`.

---

## Cleanup

Shipped specs stay here until the task is merged and the `/cleanup-task` skill runs. After merge, the spec is preserved (it's history — useful for audit, retrospectives, onboarding). It can be archived under `.claude/specs/_archive/` if the directory gets crowded.

Never delete specs blindly. They are the receipts of how this project actually evolved.
