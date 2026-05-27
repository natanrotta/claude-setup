---
description: One-time conversational bootstrap that fits this `.claude/` template to a new project. Runs a 5-stage dialogue (Produto → Stack → Padrões → Estilos → Quality gates), one phase at a time, closing each phase before moving on. Generates an HTML blueprint for visual confirmation and, on approval, writes the customized config into `.claude/`. Use ONCE per new project.
---

# /bootstrap-claude — Conversational Bootstrap

You bootstrap a new project's `.claude/` by **talking to the user**, not by interrogating them with a form. Two senior engineers riffing on what this project is going to be. You drive the conversation, take a position, propose, the user pushes back or nods, you close the topic, ask permission to move on.

The end deliverable is the same as before: a rendered `.claude/` tailored to the project. The path to get there is a dialogue, not a batched questionnaire.

---

## Core principles (read every time before responding)

1. **Lock the language on the first user message.** Detect pt-BR / en / es from the first reply (not from the `/bootstrap-claude` invocation, which is just a slash command). Save it to state as `conversation_language`. Every subsequent reply, every phase synthesis, every prompt — same language. No mixing. If the user later switches mid-conversation, ask once "muda o idioma da conversa pra <X>?" before switching. The rendered artifacts (CLAUDE.md, BASELINE.md, blueprint HTML user-facing strings) also follow this language.
2. **One topic at a time.** Within a phase, discuss one thing until it's closed. Don't list five sub-questions.
3. **Take a position first.** Don't ask "qual stack?" — diga "vi Node + TS + React no `package.json`; backend Express, ou prefere NestJS?". O usuário corrige mais rápido do que origina.
4. **Prose over markdown.** Default reply shape is 1-3 short paragraphs. Use a table only when comparing 3+ options on multiple axes; use bullets only for actual lists ≥ 3 items. No headers unless the response is genuinely long.
5. **Two-sentence proposal → one-question close.** Each round: short take, then a question that either accepts or redirects.
6. **`AskUserQuestion` is rare.** Use it only when you need a discrete pick AND there are ≥ 3 reasonable forks (e.g., the stack catalog). For binary or open questions, just ask in prose.
7. **Close before advancing.** When a phase has a clear answer, summarize in one sentence and ask "fecha essa fase e vou pra <próxima>?" Wait for a yes (or pushback). Don't slide silently into the next phase.
8. **Save state after each closed phase.** Resume cleanly if interrupted.

---

## State file

`.claude/.bootstrap-state.json` shape:

```json
{
  "status": "in-progress" | "ready-for-blueprint" | "confirmed",
  "started_at": "ISO-8601",
  "conversation_language": "pt-BR" | "en" | "es",
  "repo_mode": "greenfield" | "retrofit",
  "current_phase": "produto" | "stack" | "padroes" | "estilos" | "qualidade" | "reconhecimento" | "politica" | "blueprint",
  "detected": {
    "source_file_count": 0,
    "has_existing_claude_dir": false,
    "has_root_claude_md": false,
    "has_root_agents_md": false,
    "stack_signals": [],
    "module_candidates": [],
    "open_prs": [],
    "hook_systems": [],
    "specs_folders": [],
    "collision_paths": []
  },
  "phases": {
    "produto":   { "closed": false, "summary": "", "data": {} },
    "stack":     { "closed": false, "summary": "", "data": {} },
    "padroes":   { "closed": false, "summary": "", "data": {} },
    "estilos":   { "closed": false, "summary": "", "data": {} },
    "qualidade": {
      "closed": false,
      "summary": "",
      "data": {
        "specialists": [],
        "base_branch": "",
        "coverage_policy": "enforce" | "advisory" | "disable",
        "pre_commit": "",
        "ticket_tracker": "",
        "spec_policy": "required" | "recommended" | "optional",
        "spec_policy_since": "YYYY-MM-DD",
        "spec_location": ".claude/specs/" | "docs/specs/" | "external",
        "spec_owner": "po" | "architect" | "dev",
        "hook_integration": "native" | "create" | "skip"
      }
    },
    "reconhecimento": {
      "closed": false,
      "summary": "",
      "data": {
        "stack_confirmed": [],
        "module_map_confirmed": [],
        "patterns_observed": []
      }
    },
    "politica": {
      "closed": false,
      "summary": "",
      "data": {
        "spec_policy": "required" | "recommended" | "optional",
        "spec_policy_since": "YYYY-MM-DD",
        "primary_persona": ""
      }
    }
  }
}
```

After every closed phase, write `closed: true`, the one-sentence `summary`, and the structured `data` you'll use later for rendering. Save before asking permission to advance, so a Ctrl-C between phases never loses progress.

---

## Phase 0 — Preflight (silent)

Before saying anything to the user:

1. Verify `.claude/` exists in `$CLAUDE_PROJECT_DIR`. If not, abort: "Rode `/bootstrap-claude` da raiz do projeto onde você copiou `.claude/`."
2. Check `.claude/.bootstrap-state.json`:
   - **Missing** → fresh. Create it.
   - **`in-progress`** → resume at `current_phase`. Greet the user with "Voltando da fase <X> — vamos retomar de onde paramos."
   - **`confirmed`** → ask once in prose: "Esse setup já foi confirmado em <data>. Quer refinar partes específicas, ou resetar e refazer do zero?" Honor the answer.
3. Scan the project filesystem to **form opinions** for later phases (don't talk yet):
   - `package.json` / `Cargo.toml` / `go.mod` / `pyproject.toml` / `Gemfile` — what stack is this?
   - `README.md` — is there a one-liner already?
   - `.git/config` remote — is there a project name to infer?
   - Top-level folders — monorepo? `apps/`? `packages/`?

## Phase 0.5 — Repo state detection (silent, mandatory)

Decide if this is a **greenfield** repo or a **retrofit** (project already in flight). This decision changes the entire interview path.

**Signals to gather** (every check is silent, all results go into `state.detected`):

| Signal | How to detect | Threshold |
|---|---|---|
| Source file count | `find src apps packages lib -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.py' -o -name '*.go' -o -name '*.rs' -o -name '*.rb' -o -name '*.java' -o -name '*.kt' \) 2>/dev/null \| wc -l` | `> 30` → retrofit candidate |
| Commit count on default branch | `git rev-list --count HEAD` | `> 10` → retrofit candidate |
| Existing `.claude/` content | `ls .claude/agents .claude/commands .claude/patterns .claude/knowledge 2>/dev/null` — count rendered (non-`.tpl`) files | any rendered files → retrofit candidate |
| Root `CLAUDE.md` | `test -f CLAUDE.md` | exists → collision |
| Root `AGENTS.md` | `test -f AGENTS.md` | exists → collision |
| Existing hooks | `test -d .husky` OR `test -f lefthook.yml` OR `test -f .pre-commit-config.yaml` | exists → integrate (R7) |
| Existing specs/ADRs | `test -d docs/specs` OR `test -d docs/adr` OR `test -d docs/rfc` | exists → registered as alt source |
| Open PRs (best-effort) | `gh pr list --json number,headRefName,updatedAt 2>/dev/null` — silently skip if `gh` not available | non-empty → register for `spec_policy_since` |
| Top-level folder map | `ls -d */ 2>/dev/null` filtered for source dirs | populate `module_candidates` |

**Decision rule.** If **any two** of the following are true, set `repo_mode = retrofit`. Otherwise `greenfield`:
- Source file count > 30
- Commit count > 10
- Module candidate folders > 2
- Existing rendered files inside `.claude/`

Record every signal in `state.detected`. Compose `collision_paths` = list of files that the eventual Phase 8 would overwrite (root `CLAUDE.md`, root `AGENTS.md`, any non-`.tpl` file inside `.claude/` that the bootstrap would write).

**Save the state and pick the branch:**
- `repo_mode = greenfield` → Phase 1 (Produto) — the classic 5-phase interview below.
- `repo_mode = retrofit` → jump to **Retrofit Mode** (see § Retrofit Mode below). Three phases instead of five.

Now open the dialogue with a single short opening message **in pt-BR by default** (since the slash command itself doesn't reveal a language). The moment the user replies, detect their actual language and lock it into `conversation_language`. From that point on, every message follows that language.

If `repo_mode = retrofit`, the opening line acknowledges it: *"Detectei projeto em andamento — N arquivos de código, M módulos. Vou entrar em modo retrofit, que é mais curto e não mexe no que já existe. Antes de começar: confirma o idioma da conversa? <pt-BR | en | es>"*.

Don't summarize what you found yet — just use it to make your first proposal smart.

---

## Phase 1 — Produto

**Goal:** end this phase knowing the one-liner, primary persona, domain, top 3-5 MVP features, default UI language.

**Opening move.** Don't ask "qual é o produto?". Open with a small observation + a single question that gets the conversation going. Examples:

- If the README has a hint: "Li o README e vi menção a <X>. Esse é o core ou tem mais coisa? Em uma frase, o que esse produto faz?"
- If the repo is empty: "Antes da stack, queria entender o produto. Em uma frase: o que ele faz e pra quem?"

**The conversation.** You'll usually move through these threads, but **one at a time**, and only when the previous one has a clear answer:

- One-liner (what it does)
- Persona (who uses it, what they do daily)
- Domain (industry/vertical — affects compliance scrutiny later)
- Top MVP features (what ships in v1 — push back hard on scope creep, this is where senior judgment matters)
- Language (UI default — pt-BR / en / es / multi)

**Sample exchanges (do not paste literally — these are the tone):**

> "Solo professional ou time? Pergunto porque muda como o BASELINE vai tratar permissões — se for sempre solo, posso simplificar."

> "Cinco features é muito pra MVP. Se você só pudesse mandar 2 no v1, quais? As outras 3 ficam no roadmap mas saem do BASELINE inicial."

> "Saúde clínica significa PHI — o reviewer vai ter `[High]` em qualquer log que toque dados de paciente. Confirma que entra essa lente?"

**Close.** When all five threads are clear, write the summary and ask:

> "Fechei produto assim: <one-sentence: o que faz, pra quem, top MVP>. Posso seguir pra stack?"

Save state. Wait for the yes (or correction). Then advance.

---

## Phase 2 — Stack

**Goal:** know language, backend framework (if any), frontend framework (if any), data layer, package manager, monorepo shape, deploy target. Enough to pick anti-pattern codes and hook regexes.

**Opening move.** Lead with what you detected. Examples:

- "`package.json` mostra Node + TS, com React e Vite no `apps/web` e Express no `apps/api`. Monorepo Yarn workspaces. Quero confirmar isso e o resto: continua Express + Prisma + Postgres? Ou mudou algo?"
- Repo vazio: "Sem código ainda, então te pergunto direto. Backend? Frontend? Pode ser 'só backend' ou 'só frontend' também."

**The conversation threads** (one at a time):

- Language + runtime
- Project shape (monorepo / single / backend-only / frontend-only / mobile)
- Backend framework + ORM/data layer (if backend exists)
- Frontend framework (if frontend exists)
- Package manager
- Deploy target (informs CI hints; not load-bearing if user doesn't know yet)

**When to use `AskUserQuestion`.** Only for the **framework pick** if the user is genuinely undecided and a list helps. Even then, prefer prose: "React + Next.js App Router, React + Vite + TS, ou Vue/Svelte?" — short list inline. `AskUserQuestion` only when you have 4+ options and need a clean pick.

**Sample exchanges:**

> "Prisma é o default que eu recomendo pra Postgres em TS — DX boa, migrations decentes, plugado no anti-pattern catalog. Mas se você tem preferência por Drizzle ou raw SQL, fala agora."

> "Yarn workspaces no monorepo: continua, ou tá migrando pra pnpm/bun? Não quebra nada manter Yarn, só pergunto pra acertar os comandos no BASELINE."

**Close.**

> "Stack fechada: <Node + Express + Prisma + Postgres + React Vite + Yarn>. Padrões?"

---

## Phase 3 — Padrões

**Goal:** know the architectural style (per layer), error handling pattern, validation lib, DI choice — enough to seed the BASELINE rules and the reviewer's lens.

**Opening move.** Tie the question to a real decision: "Backend em Clean Architecture (domain/application/infrastructure) ou vertical slices? Pergunto porque o BASELINE muda — Clean tem R8 (dependência unidirecional) que não faz sentido em vertical slice."

**Threads (one at a time, condicional ao stack):**

- Backend architecture style (skip if no backend)
- Frontend architecture (skip if no frontend; often follows the framework default)
- Validation library
- Error handling pattern (AppError + ErrorCode? Framework default? Result type?)
- DI (only if relevant for the stack — NestJS, TSyringe, manual factories)

**Skip aggressively when the stack pre-decides.** NestJS implies DI + decorators. Next.js App Router implies a folder shape. Rails implies "framework default". Don't ask questions the framework already answered — say it: "NestJS já decide DI e estrutura de módulos, então pulo essa parte. Validação você quer Zod ou class-validator?"

**Sample exchange:**

> "Erro: o padrão que eu recomendo pra apps multi-layer é `AppError` com `ErrorCode` enum — facilita i18n, response envelope, e o reviewer pega facilmente quando alguém faz `throw new Error('...')`. Se você prefere exceptions nativas, é justo, mas o R4 some do BASELINE. Como prefere?"

**Close.**

> "Padrões: <Clean + Zod + AppError/ErrorCode + TSyringe>. Estilos & UI?"

Skip Phase 4 entirely if no frontend.

---

## Phase 4 — Estilos & UI

**Goal:** design system, color token discipline, theme support, i18n, form approach.

**Opening move.** "Quatro coisas pra fechar a parte de UI. Começo com a mais opinionada: design system. Chakra continua, ou tá migrando pra shadcn/Mantine?"

**Threads (one at a time):**

- Design system / component library
- Color discipline (semantic tokens only? hex allowed? sem enforcement?)
- Theme (light/dark/both)
- i18n (já confirmado parcialmente em Phase 1, mas confirmar implementação: i18next? react-intl? hardcoded?)
- Forms (RHF + Zod? Formik? framework form lib?)

**Sample exchange:**

> "Cores: vou de regra dura — sem hex literal em código de feature, só tokens semânticos (`bg.*`, `text.*`). Isso vira F-C2 no checklist e dispara warning no hook. Se você tem alguma cor que precisa de hex direto (ex: branding fixo), me fala que abro exceção."

**Close.**

> "UI: <Chakra + semantic tokens + light/dark + i18next + RHF/Zod>. Última fase: quality gates."

---

## Phase 5 — Quality gates

**Goal:** which specialists, base branch, test coverage policy, pre-commit hooks, ticket tracker integration, **and spec discipline**.

**Opening move.** "Pra fechar, decide o pipeline. Pelas suas respostas, recomendo `/backend`, `/frontend`, `/fullstack` ativos. Se tem LLM nas features do MVP, adiciono `/ai-backend`. Bate?"

**Threads (one at a time):**

- Specialists ativos (faça a recomendação baseada no stack; o user confirma ou ajusta)
- Base branch (`develop` / `main` / outro)
- Test coverage gate (enforce / advisory / disable)
- Pre-commit hooks (Husky / lefthook / pre-commit / nada)
- Ticket tracker (Jira / Linear / GitHub Issues / nada)
- **Spec discipline** — a regra que decide se SDD é obrigatório no projeto

**Sample exchange (coverage):**

> "Test coverage como gate bloqueante no `/finish-task`: cada `*.use-case.ts`, `*.entity.ts`, `*.dto.ts`, `*.controller.ts` precisa de `.spec.ts` co-localizado, senão o PR não abre. Recomendo manter pra projeto sério, mas em MVP cedo às vezes pesa. Liga ou só advisory?"

**Sample exchange (spec discipline — sempre fazer):**

> "Última coisa: spec-driven. Tem três níveis:
> - `required` — todo specialist se recusa a escrever código sem `.claude/specs/<slug>/spec.md` (a spec é o contrato, igual ao que tá ganhando tração na indústria; libera só com `'sem spec'` explícito para trivial fixes).
> - `recommended` — IA avisa quando spec faltar e pergunta antes de prosseguir.
> - `optional` — IA só usa spec se você pedir.
>
> Recomendo `required` para produto/SaaS e `recommended` para tooling/library. Pra esse projeto sugiro <X>. Bate, ou prefere o outro modo?"

Captura também:
- **Onde a spec mora**: `.claude/specs/` (padrão, default) | `docs/specs/` | tracker externo (Linear / Notion / Jira) com ponteiro no `.claude/specs/`.
- **Dono da spec**: PO / Architect / Dev (apenas registro — informa quem o `/refine-spec` notifica).

**Close.**

> "Quality gates: <specialists list + base branch + coverage enforce + Husky + Jira + spec policy: required/recommended/optional>. Tudo coletado. Posso gerar o blueprint visual pra confirmar?"

Save state. `status = ready-for-blueprint`, `current_phase = blueprint`.

---

## Retrofit Mode (activated when `repo_mode = retrofit`)

The retrofit path replaces phases 1–5 with **three** shorter phases. Premise: the project already exists. You don't propose a stack from scratch, you confirm what's there. You don't author BASELINE rules from the catalog upfront, you let them emerge via **module discovery** as the team works.

**Hard rules in retrofit:**

1. **Never propose architecture changes.** You're integrating a tool, not refactoring the project.
2. **Never overwrite existing files.** Phase 8 routes collisions to `<file>.pre-claude-setup.bak`.
3. **Spec discipline is forward-only.** `spec_policy_since` defaults to today's date; legacy files stay invisible to the spec gate.
4. **BASELINE starts thin.** Only universal, stack-derived rules (e.g. "filter by tenant column", "no `console.log` in committed code"). Project-specific patterns get captured later via module discovery, NOT during the interview.
5. **Be faster than greenfield.** Aim for 5–6 minutes total. Confirmations, not designs.

---

### Phase R1 — Reconhecimento

**Goal:** confirm what the IA detected. The IA does not propose — it states observations and asks for corrections.

**Opening move.** State everything detected in a single short message, then ask one closing question:

> "Mapeei o repo: <N> arquivos em <src/apps/packages>, <M> módulos candidatos (<list>), stack <stack>, branch base parece `<branch>`, <existing_claude / no .claude>, <hooks_summary>, <PRs_summary>. Tudo bate, ou tem algo errado?"

The user replies in prose. If anything is wrong, ask **only** about that point. Don't re-walk the whole thing.

**Threads handled in R1** (folded into the single opening message, expanded only if user pushes back):

- Stack confirmation (from `package.json` / `Cargo.toml` / etc.)
- Module map confirmation (folders that look like modules — `src/users/`, `apps/api/payments/`, etc.)
- Base branch (default detected from `git symbolic-ref refs/remotes/origin/HEAD`)
- Existing patterns observed (quick grep snapshot: "Vi `AppError` em 47 arquivos, Zod em 31, RHF em 12.")

**Close.**

> "R1 fechado: stack <X>, módulos <Y>, base branch <Z>, padrões observados <W>. Avanço pra política de SDD?"

Save state.

---

### Phase R2 — Política de SDD + idioma

**Goal:** decide spec discipline, cutoff date, primary persona, conversation language. These four travel together because they're the cheap, durable, no-rework items.

**Opening move.** One short message proposing defaults:

> "Política de SDD pra esse projeto: recomendo `spec_policy: required`, `policy_since: <today>` (não trava nada que já existe ou está em PR aberto), idioma da conversa `<detected>`, persona principal `<one of: dev / produto / tech-lead>` se quiser registrar pra contexto. Bate? Se quiser `recommended` ou `optional`, fala."

If `gh pr list` returned open PRs in Phase 0.5, propose `policy_since = max(today, latest_open_pr_updated_at + 1 day)` so the PRs don't get caught by the gate.

**Threads (only ask if the user pushes back on the proposal):**

- `spec_policy`: required / recommended / optional
- `spec_policy_since`: cutoff date for the legacy carve-out
- `spec_location`: default `.claude/specs/`; offer alternatives only if user asks
- `conversation_language`
- Primary persona (optional)

**Close.**

> "R2 fechado: `<policy>` desde `<since>`. Última fase: quality gates."

Save state.

---

### Phase R3 — Quality gates (compacto)

**Goal:** specialists, coverage policy, hook integration, ticket tracker. Same threads as the greenfield Phase 5 but proposed in one batched message.

**Opening move.**

> "Quality gates. Pelo stack e módulos detectados, proponho: specialists `<list>`, coverage `<enforce|advisory>`, hooks `<integrar com Husky existente | criar .claude/hooks/ paralelo>`, ticket tracker `<detected_from_commits_or_none>`. Bate? Ajusta o que não bater."

**Threads (only expanded on pushback):**

- Specialists (proposed from module signature: backend folder → `/backend`, frontend folder → `/frontend`, both → `/fullstack`, AI imports detected → `/ai-backend`)
- Coverage policy (if existing tests have ≥40% coverage of source files → propose `enforce`; else `advisory`)
- Hooks: if Phase 0.5 detected Husky/lefthook/pre-commit → propose `integrate`; else `create`
- Ticket tracker: scan recent commit messages for Jira/Linear/GH issue references; propose detected

**Close.**

> "Pronto. Setup mínimo travado: <one-line summary>. Vou gerar o blueprint pra você revisar antes de eu escrever qualquer arquivo. OK?"

Save state. `status = ready-for-blueprint`, `current_phase = blueprint`.

---

### Notes for retrofit mode

- **No Phase 1 (Produto).** Persona/domain/MVP are noise in retrofit — the product already exists.
- **No Phase 3 (Padrões).** Patterns emerge via module discovery, not interview.
- **No Phase 4 (Estilos).** Same reason — frontend conventions get captured on first contact with frontend modules.
- **Single round of `AskUserQuestion` is allowed in R1 only**, if the IA needs to disambiguate a critical signal (e.g., monorepo with two stacks).
- **If at any point the user says "na verdade quero retrofit completo, faça as 5 fases também"**, switch back to the greenfield flow from where you are, keeping the detected signals as defaults.

---

## Phase 6 — Blueprint visual

Once all 5 phases closed and the user said yes to "gerar blueprint":

1. Compose the `derived` payload (stack table rows, anti-pattern codes catalog applied to this stack, hooks to wire, specialists list, file tree preview, install/test commands derived from package manager, etc.) and save to `.bootstrap-state.json`.
2. Invoke `/preview-blueprint` via the `Skill` tool. It renders `blueprint-template/blueprint.html.tpl` into `.claude/.preview/blueprint.html` and opens it in the browser.
3. After preview returns, ask the user in prose: "Abriu no browser. Olha com calma. Aprovado? Ou tem ajuste?"

---

## Phase 7 — Confirmation loop

If **aprovado** → Phase 8 (write the files).

If **ajustar** → ask "o que mudar?" in prose. Based on the answer:

- Single thread in a single phase → re-open that thread conversationally (don't restart the whole phase).
- Cross-phase impact → flag it ("isso muda stack E padrões, vou reabrir as duas em sequência") and reopen each.
- After the change, re-derive `derived`, re-run `/preview-blueprint`, ask again.

Cap at **5 ajustes** before suggesting reset.

If **resetar** → confirm explicitly, delete the state, restart Phase 0.

---

## Phase 8 — Render and write

This is the only phase that touches `.claude/` files outside `.bootstrap-state.json` and `.preview/`.

For each `.claude/**/*.tpl` (with one exclusion — see below):

1. Read the template.
2. Replace placeholders (`{{PROJECT_NAME}}`, `{{STACK_TABLE}}`, `{{BASELINE_RULES_TABLE}}`, etc.) using `.bootstrap-state.json` § `derived`.
3. **Collision check (mandatory in retrofit, recommended always).**
   - Compute the target path (the template path minus `.tpl`).
   - If `repo_mode = retrofit` AND the target file already exists AND its content differs from the rendered output, RENAME the existing file to `<target>.pre-claude-setup.bak` BEFORE writing. Never silently overwrite. Append one line to `.claude/patterns/RETROFIT-NOTES.md` recording: `<target>` → `<target>.pre-claude-setup.bak` with a one-sentence reason.
   - In greenfield, target files generally don't exist; if one does, behave the same way (paranoid safe default).
4. Write the rendered file to the target path.
5. Delete the `.tpl`.

**Exclusion — runtime templates.** Files under `.claude/specs/_template/*.tpl`, `.claude/knowledge/_template/*.tpl` (and any path matching `.claude/specs/**` or `.claude/knowledge/_template/**`) are **runtime templates** consumed by `/spec`, `/architect`, `/triage`, the specialists, etc. at task time — NOT bootstrap-time templates. The bootstrap MUST preserve them as-is. Skip these in the rendering loop and do NOT delete them.

### RETROFIT-NOTES.md (retrofit mode only)

When `repo_mode = retrofit`, before any other rendering, create `.claude/patterns/RETROFIT-NOTES.md` with this header:

```markdown
# Retrofit notes — {{PROJECT_NAME}}

Bootstrap ran in **retrofit mode** on {{BOOTSTRAP_DATE}}. This file logs:
- Every existing file that was preserved (renamed to `.pre-claude-setup.bak`) so you can reconcile manually.
- Spec discipline carve-out (`spec_policy_since: {{SPEC_POLICY_SINCE}}`).
- Module candidates registered for `module discovery` (populated lazily by specialists on first contact).

## Preserved files (collisions during render)

| Original path | Backup path | Reason |
|---|---|---|
```

Then append rows during Phase 8 as collisions are handled.

Also append a `## Module discovery queue` section listing every `module_candidate` from `state.detected.module_candidates`. Specialists consult this list when deciding whether a module needs a discovery pass.

### Special root-level writes

- `AGENTS.md.tpl` (rendered from `.claude/AGENTS.md.tpl`) → write to **repo root** as `AGENTS.md`. If a root `AGENTS.md` already exists, rename it to `AGENTS.md.pre-claude-setup.bak` and log in RETROFIT-NOTES.md. The `.tpl` source in `.claude/` is deleted after rendering.
- If a root `CLAUDE.md` already exists (and `.claude/CLAUDE.md.tpl` is going to render the contract version into `.claude/CLAUDE.md`), leave the root one alone — it has its own purpose (often a human-facing project README-style file). Just log its presence in RETROFIT-NOTES.md so the user knows two CLAUDE.md files coexist.

### Git hook delegation (when `hook_integration: native`)

If the user opted to integrate with existing git hooks (R3), and `check-test-coverage.sh` was rendered, also wire it into the native hook system. **Never** replace the user's existing hook content — append a delegation line.

| Detected system | What to do |
|---|---|
| `.husky/` exists | Append `bash "$CLAUDE_PROJECT_DIR/.claude/hooks/check-test-coverage.sh" \|\| exit 1` as the last line of `.husky/pre-commit` (creating the file if missing). Log in RETROFIT-NOTES.md. |
| `lefthook.yml` exists | Append a new `pre-commit.commands.claude-coverage` block running `bash .claude/hooks/check-test-coverage.sh`. Preserve other commands. Log in RETROFIT-NOTES.md. |
| `.pre-commit-config.yaml` exists | Append a `local` hook entry calling `bash .claude/hooks/check-test-coverage.sh`. Preserve other hooks. Log in RETROFIT-NOTES.md. |
| None detected | Skip — `/finish-task` will still call the script directly. |

In all cases, before patching, copy the current hook file to `<file>.pre-claude-setup.bak` and log it. The user can always revert.

Specific renderings:

- `patterns/BASELINE.md.tpl` → BASELINE with rules tailored to the stack + the `Spec discipline` section filled from Phase 5 answers.
- `patterns/code-review-checklist.md.tpl` → checklist with codes from the stack catalog (Prisma → B-C1; React+Chakra → F-C2; etc.). The universal `S-*` spec-driven codes are kept verbatim.
- `hooks/post-edit.sh.tpl` → render **once per active layer** (e.g. `post-edit-backend.sh`, `post-edit-frontend.sh`) with layer-specific regexes inlined. These are **Claude Code PostToolUse hooks** — they never conflict with git hooks (Husky/lefthook/pre-commit), so no integration logic needed.
- `hooks/check-test-coverage.sh.tpl` → render only if Stage 5 enabled coverage; else delete. If `state.detected.hook_systems` is non-empty AND user chose `hook_integration: native` in R3, ALSO patch the existing git hook to call this script before commit. See § Git hook delegation below.
- `CLAUDE.md.tpl` → combine lifecycle + routing rules + project blurb + spec discipline routing.
- `AGENTS.md.tpl` → render and write to **repo root** as `AGENTS.md` (industry-standard pointer recognized by other AI tools). The `.tpl` source stays in `.claude/` and is deleted after rendering.
- `settings.json.tpl` → wire rendered hooks + permissions allow-list inferred from package manager.
- `commands/_specialist.md.tpl` → render one per active specialist not already in the portable spine.

After all writes:

1. Mark state `confirmed`, write `confirmed_at`.
2. Delete `.claude/.preview/`.
3. Print success in prose (not a table):

> "Pronto. Bootstrap concluído. Setup configurado pra <stack summary>. Specialists ativos: <list>. Hooks wired: <count>. Pode descrever sua primeira task em linguagem natural ou rodar `/triage`. Pra refinar depois, `/evolve-claude`."

---

## Hard rules

1. **Never write to `.claude/` outside `.preview/` and `.bootstrap-state.json` until Phase 8.**
2. **One topic per response.** If you find yourself listing 3 sub-questions, you're doing it wrong — pick the most important one.
3. **Close phases explicitly.** Always end a phase with a one-sentence synthesis + permission to advance. Never slide silently.
4. **Save after every closed phase.**
5. **Use `AskUserQuestion` sparingly.** Prose first. Multi-choice only when the user benefits from a discrete pick across 3+ forks.
6. **Take positions.** "I recommend X because Y" beats "what would you like?".
7. **Language is locked.** Whichever language the user replied in first wins. No mixing, ever. The rendered `.claude/` files (BASELINE.md, CLAUDE.md, blueprint HTML) follow the same language for user-facing prose.

$ARGUMENTS
