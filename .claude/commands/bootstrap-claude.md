---
description: One-time interactive bootstrap that fits this `.claude/` template to a new project. Runs a 5-stage interview (Produto → Stack → Padrões → Estilos → Quality gates), generates an HTML blueprint for visual confirmation, and on approval writes the customized config into `.claude/`. Use ONCE per new project, immediately after copying `.claude/` from the `claude-setup` template repo.
---

# /bootstrap-claude — Interview Engine

You are the **bootstrap orchestrator**. You run a structured 5-stage interview that captures everything needed to render this `.claude/` template into a project-specific setup, then dispatch `/preview-blueprint` to generate a visual HTML confirmation page, then on approval write the final config.

This skill is the front door for every new project. The user already copied `.claude/` into their empty repo; you have ~10 minutes to interview them and build a coherent, tailored Claude Code workspace.

---

## Critical rules

1. **Run once.** If `.claude/.bootstrap-state.json` already exists and is marked `confirmed`, this is a re-run. Ask the user via `AskUserQuestion`: `[Refine existing setup]` `[Reset and re-bootstrap from scratch]` `[Abort]`.
2. **No code generation until the HTML blueprint is approved.** The blueprint is the contract.
3. **Save state after every stage.** Resume on interruption.
4. **Use a single `AskUserQuestion` per stage.** Each question must have a `(Recommended)` default.
5. **One language.** Match the user's language (default pt-BR if ambiguous).

---

## Workflow

### Phase 0 — Preflight

1. Verify `.claude/` exists in `$CLAUDE_PROJECT_DIR`. If not, abort with "Run from the root of the project where you copied `.claude/`."
2. Check for `.claude/.bootstrap-state.json`:
   - **Doesn't exist** → fresh bootstrap. Create it.
   - **Exists, status=in-progress** → resume from the last completed stage.
   - **Exists, status=confirmed** → ask the user (refine / reset / abort).
3. Read the project's `README.md`, `package.json`, `Cargo.toml`, `go.mod`, `requirements.txt`, `pyproject.toml`, etc. (whatever exists) to **pre-populate sensible defaults** for the Stack stage. Do not skip the question — but make the recommended option match the detected stack so the user can click through fast when you guessed right.

State file shape:

```json
{
  "status": "in-progress",
  "started_at": "2026-05-23T12:34:56Z",
  "stages": {
    "produto":   { "done": false, "answers": {} },
    "stack":     { "done": false, "answers": {} },
    "padroes":   { "done": false, "answers": {} },
    "estilos":   { "done": false, "answers": {} },
    "qualidade": { "done": false, "answers": {} }
  }
}
```

Persist after each stage so the user can interrupt and resume.

---

### Stage 1 — Produto

**Goal:** capture what this product is and for whom.

Questions (single `AskUserQuestion` round, max 5):

1. **Product one-liner** — describe the product in one sentence. _(Free text via follow-up question, no `(Recommended)` default — needs the user's words.)_
2. **Primary persona** — who is the main user?
   - Options: `End consumer (B2C)` / `Business professional (B2B)` / `Internal operator` / `Developer / API consumer` / `Other (describe)`
3. **Domain** — what industry/vertical?
   - Options: `Health / Clinical` / `Finance / Fintech` / `E-commerce / Marketplace` / `Education / EdTech` / `Productivity / SaaS` / `Logistics / Supply chain` / `Other (describe)`
4. **Top 3–5 features in MVP** — what will the product *do* in v1? (Free text follow-up.)
5. **Default UI language** — `pt-BR (Recommended for Brazilian projects)` / `en` / `es` / `Multi (i18n from day 1)`

After answers, save state and advance.

---

### Stage 2 — Stack

**Goal:** capture every technical choice.

Pre-populated defaults come from your Phase 0 detection (`package.json`, etc.). Show one batched `AskUserQuestion`:

1. **Project shape** — `Monorepo (multiple apps under one repo)` / `Single repo (one app)` / `Backend only` / `Frontend only` / `Mobile (RN / native)`
2. **Backend stack** — examples to offer (mark detected one `(Recommended)`): `Node + Express + TS` / `Node + Fastify + TS` / `Node + NestJS + TS` / `Python + FastAPI` / `Python + Django` / `Go + standard library` / `Rust + Axum` / `Ruby on Rails` / `None (frontend-only project)` / `Other (describe)`
3. **Frontend stack** — `React + Vite + TS` / `React + Next.js (App Router) + TS` / `Vue 3 + Vite + TS` / `Svelte + SvelteKit + TS` / `React Native + Expo` / `None (backend-only project)` / `Other (describe)`
4. **Data layer** — `PostgreSQL + Prisma` / `PostgreSQL + Drizzle` / `PostgreSQL + raw SQL` / `MySQL + Prisma` / `MongoDB + Mongoose` / `Supabase` / `Firebase` / `None` / `Other (describe)`
5. **Package manager** — `yarn (classic)` / `yarn (berry)` / `npm` / `pnpm` / `bun` / `not applicable`
6. **Deploy target** — `Vercel` / `Fly.io` / `Railway` / `AWS (ECS/EKS/Lambda)` / `GCP (Cloud Run / GKE)` / `Self-hosted (VPS / Docker)` / `Mobile (App Store / Play Store)` / `Other / TBD`

After answers, save state and advance.

---

### Stage 3 — Padrões

**Goal:** capture architectural conventions. **Conditional** — if Stage 2's backend/frontend stack is highly opinionated (Next.js App Router, NestJS, Rails), some questions are skipped because the stack already decides them.

Single batched `AskUserQuestion` with the relevant subset:

1. **Backend architecture style** (skip if backend = none):
   - `Clean / Hexagonal (domain / application / infrastructure layers) (Recommended for serious projects)`
   - `Vertical-slice (feature-folders contain everything)`
   - `Transactional script (controller does everything)`
   - `Framework-default (Rails/NestJS conventions)`
2. **Frontend architecture** (skip if frontend = none):
   - `Module folders (one per feature, with presentation/domain/infrastructure inside) (Recommended)`
   - `Pages folder + shared components (Next.js style)`
   - `Atomic design (atoms/molecules/organisms)`
   - `Framework-default`
3. **Validation** — `Zod (Recommended)` / `Yup` / `class-validator` / `joi` / `framework-default (Rails strong params, etc.)` / `none`
4. **Error handling** — `Custom AppError + ErrorCode enum (Recommended for multi-layer apps)` / `Framework default exceptions` / `Result<T, E> pattern`
5. **Dependency injection** — `TSyringe / typedi / NestJS DI (Recommended if using NestJS or hexagonal)` / `Manual factories / function composition` / `Framework default` / `Not applicable`

After answers, save state and advance.

---

### Stage 4 — Estilos & UI

**Skip entirely** if Stage 2 frontend = none.

Single batched `AskUserQuestion`:

1. **Design system / component library** — `Chakra UI (Recommended for React)` / `Mantine` / `shadcn/ui + Radix` / `Material UI` / `Ant Design` / `Tailwind only (no component lib)` / `Headless (build from scratch)` / `Other (describe)`
2. **Color tokens** — `Semantic tokens only (no hex literals in feature code) (Recommended)` / `Hex literals allowed but discouraged` / `No enforcement`
3. **Theme support** — `Light + Dark (Recommended)` / `Light only` / `Dark only` / `System-follow`
4. **i18n** — `Yes — all UI strings via i18n from day 1 (Recommended for non-English markets)` / `No — single language hardcoded` / `Yes but only in feature code` (matches Default language from Stage 1)
5. **Forms** — `react-hook-form + Zod (Recommended)` / `Formik` / `Native form elements only` / `Framework form library`

After answers, save state and advance.

---

### Stage 5 — Quality gates

**Goal:** wire up the lifecycle.

Single batched `AskUserQuestion`:

1. **Which specialists do you want?** Multi-select (`AskUserQuestion` supports one selection per question — present this as a single question with a list of comma-separated picks via free-text follow-up).
   - `/backend` — for any backend task
   - `/frontend` — for any frontend task
   - `/fullstack` — for tasks touching both
   - `/ai-backend` — for LLM/RAG/embedding work
   - `/mobile` — for React Native / native tasks
   - `/data` — for data pipeline / ETL tasks
   - **Recommended:** based on Stage 2 stack — e.g. if monorepo with apps/api + apps/web, recommend `/backend` `/frontend` `/fullstack`. If LLM in MVP features (Stage 1), add `/ai-backend`.
2. **Base branch for PRs** — `develop (Recommended for GitFlow-style)` / `main` / `master` / `Other (describe)`
3. **Test coverage gate** — `Yes — enforce co-located test files at /finish-task (Recommended for serious projects)` / `Advisory only` / `No tests enforced`
4. **Pre-commit / hooks** — `Husky + lint-staged (Recommended)` / `pre-commit (Python)` / `lefthook` / `Custom shell` / `None`
5. **Ticket tracker integration** — `Jira (DEVEL-XXXX style)` / `Linear` / `GitHub Issues` / `None`

After answers, save state, mark `status: ready-for-blueprint`.

---

### Phase 6 — Dispatch the blueprint preview

Compose a structured payload combining all stages' answers + the project's detected metadata:

```json
{
  "project_name": "<from package.json or directory name>",
  "bootstrap_date": "<today YYYY-MM-DD>",
  "main_checkout_path": "<absolute path of $CLAUDE_PROJECT_DIR>",
  "worktrees_parent_path": "<sibling to main checkout: <parent>/<name>-worktrees>",
  "stages": { ...all answers... },
  "derived": {
    "stack_table_rows": [...],
    "specialists_list": [...],
    "modules_roots": [...],
    "install_cmd": "...",
    "typecheck_cmd": "...",
    "lint_cmd": "...",
    "format_check_cmd": "...",
    "format_write_cmd": "...",
    "unit_test_cmd": "...",
    "e2e_test_cmd": "...",
    "env_files_to_seed": [...],
    "baseline_rules": [...],
    "anti_pattern_codes": [...],
    "hooks_to_wire": [...],
    "integrations": [...],
    "file_tree_preview": [...]
  }
}
```

Write this to `.claude/.bootstrap-state.json` (status = `ready-for-blueprint`).

Invoke `/preview-blueprint` via the `Skill` tool. It will:
1. Read the state file.
2. Render `blueprint-template/blueprint.html.tpl` with the data.
3. Write `.claude/.preview/blueprint.html`.
4. Open it in the user's browser (`open` on macOS, `xdg-open` on Linux, `start` on Windows).
5. Return control to you with the path of the rendered HTML.

---

### Phase 7 — Confirmation loop

After the blueprint is generated, ask the user via `AskUserQuestion`:

1. **Confirma o blueprint?** — `Aprovado — pode escrever os arquivos` / `Ajustar (descrever o que mudar)` / `Resetar e refazer entrevista`

If **Aprovado**: proceed to Phase 8.

If **Ajustar**: ask the follow-up free-text question "O que mudar?". Based on the answer:
- If it touches one stage's answer, re-run *just that stage* (single `AskUserQuestion`) and merge.
- If it's a small textual tweak (e.g. "muda o one-liner"), update the state JSON directly.
- Re-invoke `/preview-blueprint` to regenerate the HTML.
- Loop back to the confirmation question (max 5 ajustes — beyond that, suggest "Resetar e refazer entrevista").

If **Resetar**: delete `.claude/.bootstrap-state.json` and restart from Phase 0.

---

### Phase 8 — Render and write

This is the only phase that touches files in `.claude/` outside `.bootstrap-state.json` and `.preview/`.

For each template file under `.claude/**/*.tpl`:

1. Read the template.
2. Replace placeholders (`{{PROJECT_NAME}}`, `{{STACK_TABLE}}`, `{{BASELINE_RULES_TABLE}}`, `{{CHECKS_BODY}}`, ...) using the data in `.bootstrap-state.json` § `derived`.
3. Write the rendered file to the same path **without** the `.tpl` extension.
4. Delete the `.tpl` file (it lives in the template repo, not the project).

Special handling:

- **`patterns/BASELINE.md.tpl`** → render and write `patterns/BASELINE.md`. Generate baseline rules from the stack choices (e.g. if PostgreSQL + Prisma + multi-tenant, include `R1: account_id filter`). Use the template's `{{BASELINE_RULES_TABLE}}` placeholder.
- **`patterns/code-review-checklist.md.tpl`** → render with the anti-pattern codes derived from stack. The bootstrap ships a built-in catalog of stack→codes mappings (e.g. Prisma → `B-C1 account_id missing`, React+Chakra → `F-C2 hex literal`, etc.). Use the `{{BACKEND_CHECKS}}`, `{{FRONTEND_CHECKS}}`, `{{CROSS_CHECKS}}` placeholders.
- **`hooks/post-edit.sh.tpl`** → render **once per active layer** (typically `post-edit-backend.sh` and `post-edit-frontend.sh`), each with the layer-specific regex catalog inlined.
- **`hooks/check-test-coverage.sh.tpl`** → render only if Stage 5 enabled coverage; otherwise delete the template without rendering.
- **`CLAUDE.md`** at project root → generate from a built-in template that combines: the lifecycle contract (always), the routing rules for the active specialists, and the project's name/persona/domain blurb.
- **`settings.json`** → wire the rendered hooks. Start with the permissions allow-list inferred from the stack (e.g. `yarn type-check`, `yarn lint`, `yarn test` if package manager is yarn).
- **Specialist agents** (`agents/<specialist>.md`) — for each specialist chosen in Stage 5 that isn't already shipped in the template, generate a minimal specialist file from a built-in `specialist.md.tpl` shape, customized for the project's stack and patterns docs. (The portable agents `code-auditor`, `code-reviewer`, `triage-*`, `duck-*` were already copied from the template — no rendering needed.)

After all files written:

1. Mark `.bootstrap-state.json` status = `confirmed`, write `confirmed_at`.
2. Delete `.claude/.preview/` (the HTML was only for confirmation).
3. Print the success summary:

```
✅ Bootstrap complete.

  Project:        <name>
  Specialists:    <list>
  Base branch:    <branch>
  Hooks wired:    <count>
  Patterns docs:  <count rendered>
  Knowledge dir:  empty (will grow as agents accumulate wisdom)

You can now describe your first task in natural language. The setup will route you
to the right specialist. For a structured intake, run /triage.

To refine the setup later (new modules, new rules, evolved stack), run /evolve-claude.
```

---

## Hard rules

1. **Never write to `.claude/` outside `.preview/` and `.bootstrap-state.json` before Phase 8.** The HTML is the contract.
2. **Single `AskUserQuestion` per stage.** No question chains within a stage.
3. **Always offer `(Recommended)` defaults** so the user can click through fast when you guessed right.
4. **Detect the stack before asking** so defaults are not random.
5. **Save state after every stage** so the user can interrupt safely.
6. **One language throughout** — match the user's input language.
7. **Refuse to re-run silently.** If `.bootstrap-state.json` shows `confirmed`, ask before overwriting.

$ARGUMENTS
