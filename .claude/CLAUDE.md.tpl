# {{PROJECT_NAME}} — Task Lifecycle Contract

This file defines the **task lifecycle** for implementation work in this repository. It is loaded automatically into every Claude Code session and applies to direct requests and to every specialist skill.

Two execution modes — pick based on whether the user explicitly asked for a worktree:

- **Worktree mode (full lifecycle):** triggered only when the user explicitly asks ("crie um worktree", "nova worktree", "/start-task", "abre uma branch nova", or similar). Runs the entire flow: worktree → branch → triage → implement → review → tests → PR → cleanup.
- **Inline mode (default):** when the user describes a change without asking for a worktree, edit the **current branch** in the **current checkout**. No new worktree, no new branch, no automatic PR. The user owns commit/push/PR decisions.

---

## Project context

- **Bootstrap mode:** `{{REPO_MODE}}` — `greenfield` (5-phase interview) or `retrofit` (3-phase, non-destructive, with module discovery).
- **Product:** {{PRODUCT_ONELINER}}
- **Primary persona:** {{PRIMARY_PERSONA}}
- **Stack summary:** {{STACK_SUMMARY}}
- **Base branch:** `{{BASE_BRANCH}}`
- **Specialists configured:** {{SPECIALISTS_LIST}}
- **Spec discipline:** `{{SPEC_POLICY}}` since `{{SPEC_POLICY_SINCE}}` — files touched before that date are legacy (spec gate dispensed). Specs live in `{{SPEC_LOCATION}}`. Spec owner: `{{SPEC_OWNER}}`. See § Spec-Driven Development below.
- **Conversation language:** `{{CONVERSATION_LANGUAGE}}` — every reply, every prompt, every PR description, every commit message in this language. No mixing. If the user clearly switches mid-session, ask once before switching.

For the full stack table, baseline rules, and module layout, see `.claude/patterns/BASELINE.md`. If `repo_mode = retrofit`, also read `.claude/patterns/RETROFIT-NOTES.md` for the list of preserved-but-displaced files (`.pre-claude-setup.bak`) and the module discovery queue.

---

## Spec-Driven Development (SDD)

**The spec is the contract. The code is the executable derivative.** Specs live in `.claude/specs/<slug>/spec.md` (or `brief.md` for `/triage`-only tasks). They are read at Step 0 by every specialist and linked in every PR.

**Authoring routes**, choose by task size:

| Size | Tool | Artifact | When |
|---|---|---|---|
| Trivial (≤2 files, no behavior change) | none — proceed inline | — | typo, dependency bump |
| XS — single session, brief is enough | `/triage` | `brief.md` | multi-file but contained |
| S/M — pin contract on disk | `/spec` | `spec.md` (1 page) | default for non-trivial |
| L — new module, migration, sensitive surface | `/architect` | `spec.md` (full, 5 phases) | high blast radius |
| Idea, not yet a task | `/brainstorm` | `design.md` then `spec.md` | scope still fuzzy |

**Policy enforcement (`spec_policy: {{SPEC_POLICY}}`):**

- `required` — implementing specialists REFUSE to edit code without `.claude/specs/<slug>/spec.md` (Status: `approved`). Trivial fixes only allowed with explicit *"sem spec"* / *"skip spec"* override from the user.
- `recommended` — IA warns + asks once via `AskUserQuestion` when a spec is missing on M+ work.
- `optional` — IA uses spec when available, doesn't require it.

**Spec lifecycle:** `draft → approved → implementing → shipped`. Any deviation during implementation goes through `/refine-spec <slug>` — silent drift is forbidden.

**Legacy carve-out (`spec_policy_since`):** when `repo_mode = retrofit`, files last touched before `{{SPEC_POLICY_SINCE}}` are considered legacy. Tasks that only modify legacy files **do not** trigger the spec gate, even under `required`. The specialist still loads `.claude/knowledge/<module>.md` (module discovery file) and respects local patterns. Manutenção em código velho fica scope-tight — não vira refactor disfarçado.

---

## Module discovery (on-touch onboarding)

The IA learns the project module by module, not all at once. The first time a specialist touches module `X`:

1. **Silent scan:** read top 5 files in `X/` by churn.
2. **Extract patterns:** error handling, validation, naming, test layout, gotchas — with `file:line` citations.
3. **Write** `.claude/knowledge/X.md` from the template at `.claude/knowledge/_template/module-discovery.md.tpl`.
4. **Ask ONE confirmation** in prose. User can accept (`seguir`) or request one round of edits (`r`).

Subsequent tasks on the same module load `knowledge/X.md` silently — no re-discovery.

**Local rules win on style.** When BASELINE says one thing and the module's discovery file says another (e.g., BASELINE prefers Zod but the module uses class-validator), the local rule wins for code touched in that module. Cross-module rules in BASELINE remain authoritative for new modules and global invariants (tenancy, errors, secrets).

**Discovery is read-only on code.** It captures what's there — never refactors, never suggests "you should standardize." Promotion of a discovered pattern into BASELINE goes through `/evolve-claude --promote-pattern`.

---

## Worktree mode (when the user asks)

| # | Phase | Owner |
|---|---|---|
| 0 | **Start task** (worktree + branch) | `/start-task` |
| 1 | **Triage** (architect + engineer + product in parallel) | `/triage` |
| 2 | **Plan** (internal, baseline-aware) | Specialist skill |
| 3 | **Implement** (with in-loop BABYSIT self-audit) | Specialist skill |
| 4 | **Code review** | `/finish-task` → `/code-review` |
| 5 | **Validate tests** | `/finish-task` → `/check` |
| 6 | **Open PR to `{{BASE_BRANCH}}`** | `/finish-task` → `/finish` |
| 7 | **Cleanup** (after PR merged) | `/cleanup-task` |

## Inline mode (default)

| # | Phase | Owner |
|---|---|---|
| 1 | **Triage** (optional) | `/triage` if multi-file or user asks for challenge |
| 2 | **Plan** (internal) | Specialist skill |
| 3 | **Implement on current branch** | Specialist skill (BABYSIT still applies) |
| 4 | **Stop and report** | The IA |

**Inline golden rule:** if the user did not ask for a worktree, do not create one, do not switch branches, do not open a PR.

---

## Autonomy contract

The user expects to describe a task **once**, then see it executed end-to-end without being pulled back for minor decisions — **but the spec gate comes first**. No vibe coding around an unwritten contract.

**Spec gate (applies when `spec_policy = required`):**
- If the task is non-trivial AND no `.claude/specs/<slug>/spec.md` exists, the IA MUST run `/spec` (or `/triage` → `/spec`, or `/architect` for L tasks) before editing project code.
- The user can waive the gate with an explicit *"sem spec"* / *"skip spec"* — the waiver is logged in the PR body.

**The IA MUST:**
- Front-load understanding (read files silently before talking).
- Load the spec at Step 0 and print `Spec activated: <path>` (or `none — trivial fix waived`).
- Batch uncertainty into ONE `AskUserQuestion` at the start.
- Decide and announce when there are 2–3 reasonable choices ("Using X because Y").
- Default to the existing convention.
- Skip `ExitPlanMode` approval for normal tasks. Plan inline in 3–6 bullets and proceed.

**The IA MUST NOT:**
- Skip the spec gate when `spec_policy = required` and the task is non-trivial.
- Silently expand the diff beyond `## Scope § In` of the spec. Use `/refine-spec <slug>` to formalize changes.
- Ask for things it can infer (ticket ID, branch name, prefix).
- Pause mid-implementation to confirm a small decision.
- Ask permission to read files or run tests.
- End with "let me know if…" or "anything I got wrong?"

---

## Specialist auto-routing

The user describes the task in natural language. You classify the scope and invoke the right specialist via the `Skill` tool. {{ROUTING_RULES}}

**Ambiguity rule:** pick the best specialist with judgment and announce the choice in one sentence. Only ask if two specialists have genuinely equal signal.

**Explicit override:** if the user types `/<specialist>` directly, honor it.

---

## Quality enforcement

Five layers protect against pattern drift:

1. **Patterns docs** (`.claude/patterns/BASELINE.md`, `.claude/patterns/code-review-checklist.md`) — authority.
2. **Live hooks** (`.claude/hooks/post-edit-*.sh`) — advisory, write-time, non-blocking.
3. **Blocking gates** (`/finish-task` → coverage → review → check → PR).
4. **The audit subagents** (`code-auditor`, `code-reviewer`, `duck-*`) — read-only, isolated context, called in the BABYSIT loop.
5. **Telemetry ledger** (`.claude/learning/violations.md`) — every Critical/High logged, recurring violations promoted via `/evolve-claude`.

---

## Applicability

This contract applies when the user asks you to change code in this repository. It does NOT apply to:
- Pure Q&A or explanations
- Reading / summarizing code
- Debugging without edits
- Configuration of Claude Code itself

When in doubt about mode, **default to inline mode**. Worktree mode is opt-in via explicit user request.

---

> Generated by `/bootstrap-claude` on {{BOOTSTRAP_DATE}}. Refine with `/evolve-claude`.
