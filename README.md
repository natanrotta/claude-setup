<div align="center">

<sub>· CLAUDE CODE SETUP ·</sub>

# claude-setup

**A production-tested `.claude/` folder for Claude Code. It is Spec-Driven, self-auditing and self-learning.**
Copy it into a repo and Claude Code gets a full task lifecycle: triage, Task Spec, implementing specialists, a self-audit loop, blocking gates, a PR flow and a telemetry ledger that changes the rules over time.

[Quick start](#quick-start) · [Layout](#layout) · [Task lifecycle](#task-lifecycle) · [Quality layers](#quality-layers) · [Adapting it](#adapting-it-to-your-project)

</div>

---

## What this is

This is the `.claude/` setup a real product runs in production, extracted as is. It has the same files, the same phases and the same contracts. Data built up by that product (Task Specs, knowledge entries, the violations ledger, secrets) was removed. The learning ledgers ship empty, keeping their format, so they start filling as soon as you use them.

The patterns, hooks and specialists target the stack the setup was built on:

- **Monorepo:** Yarn workspaces + Turborepo. `apps/api` (backend), `apps/web` (frontend), shared packages under `@app/*`.
- **Backend:** Node.js + Express + TypeScript, Prisma (Postgres + pgvector), Zod, tsyringe DI, BullMQ/Redis, Vitest. The layout is module-first (`modules/<domain>/ · shared/ · core/`).
- **Frontend:** React + Vite + TypeScript, Chakra UI with semantic tokens, TanStack Query, react-i18next (pt-BR / en / es), Playwright E2E.
- **AI:** LangChain / LangGraph, RAG, embeddings, tool-calling copilot.
- **Infra:** Docker, Caddy, Cloudflare, VPS + WireGuard, GHCR.

On a different stack, the lifecycle, agents and gates still apply as they are. Rewrite the stack-specific parts (see [Adapting it](#adapting-it-to-your-project)).

---

## Quick start

```bash
npx degit natanrotta/claude-setup/.claude .claude
```

Then open Claude Code in the repo and describe a task in plain language, in Portuguese or English. You don't need to type a command. `.claude/CLAUDE.md` loads automatically and routes the work. The only command you type yourself is `/start-task`, when you want an isolated worktree with a PR at the end.

To refresh an existing project with the latest version of this setup:

```bash
npx degit natanrotta/claude-setup/.claude .claude --force
```

`--force` overwrites files that ship from here, including `knowledge/*.md` and `learning/violations.md`. Back those up first if your project has entries in them.

---

## Layout

```
.claude/
├── CLAUDE.md                    Task lifecycle contract (loaded every session)
├── settings.json                PostToolUse hooks + read-only permission allowlist
├── launch.json                  Dev servers for the in-app preview
├── agents/                      Subagents (isolated context, read-only unless noted)
│   ├── triage-architect.md      /triage: layer/module placement, contract risks
│   ├── triage-engineer.md       /triage: DRY/reuse map, BASELINE rules, test plan
│   ├── triage-product.md        /triage: who, why, MVP, edge cases
│   ├── code-auditor.md          BABYSIT L1: mechanical grep + checklist codes
│   ├── code-reviewer.md         BABYSIT L2: semantic judgment, spec compliance
│   ├── duck-explainer.md        BABYSIT L3: explains the diff in prose
│   ├── duck-challenger.md       BABYSIT L3: probes the explanation for gaps
│   ├── migration-safety.md      Prisma schema/migration blind spots
│   ├── security-auditor.md      SEC-* lens: auth, tenancy, secrets, injection
│   └── e2e-test-writer.md       Writes Playwright specs + Page Objects
├── commands/                    Skills (/name)
│   ├── start-task.md            Worktree + branch from origin/develop
│   ├── triage.md                3 perspectives in parallel → Task Spec
│   ├── architect.md             Field research + decision round → full spec (L / high risk)
│   ├── brainstorm.md            Validates scope and design before building
│   ├── backend.md               Implementing specialist: API
│   ├── frontend.md              Implementing specialist: web
│   ├── fullstack.md             Implementing specialist: both layers
│   ├── ai-backend.md            Implementing specialist: LLM / RAG / copilot
│   ├── test.md                  Backend unit tests (Vitest)
│   ├── test-e2e.md              E2E coverage (dispatches e2e-test-writer)
│   ├── ui-design.md             UI/UX audit and design
│   ├── security.md              Application security specialist
│   ├── devops.md                Production infra and deploy specialist
│   ├── normalize.md             Read-only drift audit (code-auditor)
│   ├── code-review.md           Wrapper → code-reviewer subagent
│   ├── duck-debug.md            Rubber-duck orchestrator (explainer ↔ challenger)
│   ├── check.md                 Type-check + lint + format + tests, with auto-fix
│   ├── finish-task.md           Gates → tests → commit + push + PR → learning
│   └── cleanup-task.md          Removes the worktree once the PR is merged
├── patterns/                    Source of truth that every specialist defers to
│   ├── BASELINE.md              Non-negotiables R1–R28 (fast-load compass)
│   ├── spec.md                  Spec-Driven Development: template + SC-* codes
│   ├── backend.md               Backend lifecycle and patterns
│   ├── backend-modules.md       Where a backend file goes (module-first)
│   ├── frontend.md              Frontend lifecycle and patterns
│   ├── e2e.md                   Playwright patterns
│   ├── security.md              Security model + SEC-* catalog
│   └── code-review-checklist.md Anti-pattern catalog (B-*, F-*, E-*, X-*, SC-*)
├── hooks/
│   ├── post-edit-backend.sh     Live warnings on apps/api edits
│   ├── post-edit-frontend.sh    Live warnings on apps/web edits
│   ├── post-edit-e2e.sh         Live warnings on e2e edits
│   ├── check-test-coverage.sh   /finish-task Phase 4.5 (blocking)
│   └── check-contract-sync.sh   /finish-task Phase 4.7 (advisory)
├── knowledge/<skill>.md         Per-specialist learned wisdom (starts empty)
├── learning/
│   ├── protocol.md              Self-learning + telemetry protocol
│   └── violations.md            Append-only ledger of Critical/High findings
├── specs/                       Task Specs: .claude/specs/<slug>.md
├── plans/                       Plan files for large / risky tasks
└── .secrets/                    Local-only credentials (gitignored except .gitkeep)
```

---

## Task lifecycle

`.claude/CLAUDE.md` is the contract. Claude picks one of two modes.

**Inline mode (the default).** Claude edits the current branch. It triages only when the change spans several files, writes a micro-spec for non-trivial changes, implements and runs the BABYSIT loop, then stops. It does not commit, push or open a PR on its own; you decide those.

**Worktree mode (only when you ask).** You say "abre uma worktree", "nova branch" or `/start-task`, and Claude runs the whole flow in the same session:

| # | Phase | Owner |
|---|---|---|
| 0 | Worktree + branch from `origin/develop` | `/start-task` |
| 1 | Triage → **Task Spec** in `.claude/specs/<slug>.md` (one batched question round) | `/triage` (or `/architect` for L / high risk) |
| 2 | Internal plan, BASELINE activation | Specialist |
| 3 | Implement against the acceptance criteria + BABYSIT self-audit | Specialist |
| 4 | Coverage gate → spec compliance → contract sync → code review | `/finish-task` 4.5–5 |
| 5 | Unit + E2E tests, with up to 3 auto-fix retries | `/finish-task` 6 |
| 6 | Commit + push + PR to `develop` | `/finish-task` 7 |
| 7 | Learning checkpoint (telemetry + knowledge + promotion radar) | `/finish-task` 8 |
| 8 | Remove the worktree after merge | `/cleanup-task` |

**Specialist auto-routing.** You never have to name a specialist. Claude classifies the request: AI/LLM work goes to `/ai-backend`, API-only to `/backend`, web-only to `/frontend`, both layers to `/fullstack`, scoping questions to `/brainstorm` or `/architect`, and audits to `/normalize`. It announces the choice in one sentence before it starts.

**Autonomy contract.** Claude reads the code first and asks every open question in one batch at the start. When there are small choices, it picks one and says which. It does not stop mid-task to ask about naming or file locations.

---

## Quality layers

1. **Patterns docs:** `patterns/*.md` are the authority. `BASELINE.md` lists the rule IDs a specialist activates at the start of a task.
2. **Live hooks:** `PostToolUse` scripts grep every edited file for known anti-patterns and print advisory warnings, so Claude fixes them mid-task.
3. **Blocking gates:** `/finish-task` runs the test-coverage gate, spec compliance, contract sync, code review and the test loop before it opens a PR.
4. **Audit subagents:** `code-auditor`, `code-reviewer`, `security-auditor` and `migration-safety` run in isolated context and never edit files.
5. **Triage + BABYSIT + telemetry:** the spec prevents building the wrong thing, triage prevents bad starts, the BABYSIT loop (auditor → reviewer → duck debug) prevents bad endings, and `learning/violations.md` records every Critical/High finding. Codes that show up ≥5 times in 30 days are proposed for promotion into a hook, a BASELINE rule or a knowledge entry.

---

## Adapting it to your project

The spine (lifecycle, triage, BABYSIT, gates, telemetry) works on any project. These files carry stack-specific assumptions to review:

| File | What to adjust |
|---|---|
| `patterns/BASELINE.md`, `backend*.md`, `frontend.md`, `e2e.md`, `security.md`, `code-review-checklist.md` | Rules, paths and anti-pattern codes for your stack |
| `hooks/*.sh` | Path globs (`apps/api/src/**`, `apps/web/src/**`) and grep regexes |
| `settings.json` | Permission allowlist (`yarn …`, `@app/*` workspace names) |
| `launch.json` | Dev servers and ports |
| `commands/check.md`, `finish-task.md`, `start-task.md` | Validation commands, base branch (`develop`), env files to copy |
| `commands/devops.md`, `commands/security.md`, `agents/triage-product.md` | Your infra topology (placeholders such as `<VPS_APP_IP>` and `example.com`) and your product |

Keep the rule IDs and anti-pattern codes stable once you start using them, because the violations ledger and the promotion radar key on them.
