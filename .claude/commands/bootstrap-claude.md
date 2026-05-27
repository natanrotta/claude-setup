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
  "current_phase": "produto" | "stack" | "padroes" | "estilos" | "qualidade" | "blueprint",
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
        "spec_location": ".claude/specs/" | "docs/specs/" | "external",
        "spec_owner": "po" | "architect" | "dev"
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

Now open the dialogue with a single short opening message **in pt-BR by default** (since the slash command itself doesn't reveal a language). The moment the user replies, detect their actual language and lock it into `conversation_language`. From that point on, every message follows that language.

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
3. Write the rendered file to the same path **without** `.tpl`.
4. Delete the `.tpl`.

**Exclusion — runtime templates.** Files under `.claude/specs/_template/*.tpl` (and any path matching `.claude/specs/**`) are **runtime templates** consumed by `/spec`, `/architect`, `/triage`, etc. at task time — NOT bootstrap-time templates. The bootstrap MUST preserve them as-is. Skip these in the rendering loop and do NOT delete them.

Specific renderings:

- `patterns/BASELINE.md.tpl` → BASELINE with rules tailored to the stack + the `Spec discipline` section filled from Phase 5 answers.
- `patterns/code-review-checklist.md.tpl` → checklist with codes from the stack catalog (Prisma → B-C1; React+Chakra → F-C2; etc.). The universal `S-*` spec-driven codes are kept verbatim.
- `hooks/post-edit.sh.tpl` → render **once per active layer** (e.g. `post-edit-backend.sh`, `post-edit-frontend.sh`) with layer-specific regexes inlined.
- `hooks/check-test-coverage.sh.tpl` → render only if Stage 5 enabled coverage; else delete.
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
