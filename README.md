<div align="center">

<sub>· CLAUDE CODE TEMPLATE ·</sub>

# claude-setup

**A conversational bootstrap for Claude Code — Spec-Driven from day one.**
Drop `.claude/` into an empty repo, talk to it for ten minutes, and you walk away with a fully tuned workspace — task lifecycle, self-audit loop, pattern docs, hooks, specialists, telemetry, and a spec discipline that pins intent to disk before any code lands. All shaped to the project you described.

[Why SDD](#why-spec-driven-and-not-vibe-coding) · [Quick start](#quick-start) · [How it works](#how-it-works) · [What you get](#what-you-get) · [The 5-phase conversation](#the-5-phase-conversation) · [Lifecycle](#lifecycle-after-bootstrap) · [Keeping it alive](#keeping-the-setup-alive)

</div>

---

## Why this exists

Setting up Claude Code properly takes a week of trial and error. You write your first agent and learn it's too generic. You add hooks and find out grep regexes need to match your stack. You build a code-review checklist, distill it into a BASELINE, configure the lifecycle commands. By the time it's good, you've burned forty hours.

Then you start your next project. Nothing carries over cleanly — regexes target the wrong paths, pattern docs reference modules that don't exist, specialists know the wrong stack. So you copy-paste and edit by hand, and there goes another half-week.

`claude-setup` collapses that into a ten-minute conversation. The portable spine — triage, audit loop, lifecycle commands — copies over untouched. The project-specific parts — anti-pattern codes, hook regexes, BASELINE rules, specialist routing — are filled in by a meta-skill that interviews you about the project and renders the templates.

---

## Why Spec-Driven, and not vibe coding

**Vibe coding** — tossing vague instructions at an AI and accepting whatever it returns — works for throwaway scripts. It collapses in real systems: the AI re-derives context every turn (token waste), the architecture decisions come out random, and there is no contract anywhere that says what the change *was supposed to do*. The intent only ever lives in the chat, and the chat compacts.

**Spec-Driven Development (SDD)** flips that. The specification is the source of truth; the code is the executable derivative. The dev's job moved from writing lines to writing intent — what the system should do, for whom, with which guarantees. The AI executes the spec.

This template ships SDD as defaults, not best practices:

- `.claude/specs/<slug>/spec.md` — every non-trivial task gets a 1-page spec on disk before any edit lands. It survives session compaction. It links into the PR. It is what the auditor checks the diff against.
- **Three authoring routes**, sized to the task: `/triage` (XS — 3-perspective brief), `/spec` (S/M — 1 page), `/architect` (L — full field-research spec). All three persist to `.claude/specs/`.
- **The BABYSIT loop is anchored to the spec.** Before the auditor runs, the specialist restates which spec sections it implemented (L0). The auditor flags any file edited outside `## Scope § In` as `S-C1` drift (L1.5). Silent scope creep is forbidden.
- **`spec_policy: required | recommended | optional`** — chosen during bootstrap. Under `required`, implementing specialists refuse to edit code without an approved spec.
- **`AGENTS.md`** at the repo root — so Cursor, Codex, Aider, and any other tool that picks up the standard finds the same orientation Claude Code does via `.claude/CLAUDE.md`.

The dev gets the leverage of AI execution without the brittleness of intent-by-chat. The token cost drops because the contract is on disk and short, not re-derived every prompt. And when reality educates the spec mid-implementation, `/refine-spec <slug>` formalizes the change instead of letting it drift.

---

## Quick start

```bash
# 1. From inside your new empty repo
npx degit natanrotta/claude-setup/.claude .claude

# 2. Open Claude Code
claude

# 3. Inside Claude Code
/bootstrap-claude
```

The skill greets you, scans your repo for hints (`package.json`, `Cargo.toml`, etc.) and opens a conversation. Five phases, around ten minutes. At the end you confirm a visual HTML blueprint, the bootstrap writes the rendered files, and you're working.

<details>
<summary><b>Alternatives (curl, git submodule)</b></summary>

```bash
# curl + tar — no Node required
curl -L https://github.com/natanrotta/claude-setup/archive/refs/heads/main.tar.gz \
  | tar -xz --strip-components=2 -C . claude-setup-main/.claude

# git submodule — tracks upstream
git submodule add https://github.com/natanrotta/claude-setup .claude-upstream
ln -s .claude-upstream/.claude .claude
```

</details>

---

## How it works

```mermaid
flowchart LR
    A[Empty repo] -->|degit .claude/| B[Template copied]
    B -->|/bootstrap-claude| C{Phase 1<br/>Product}
    C -->|close| D{Phase 2<br/>Stack}
    D -->|close| E{Phase 3<br/>Patterns}
    E -->|close| F{Phase 4<br/>Styles}
    F -->|close| G{Phase 5<br/>Quality}
    G -->|/preview-blueprint| H[HTML in browser]
    H -->|approved| I[.tpl files rendered<br/>real .claude/ written]
    I --> J[First task:<br/>/triage]
    J -.->|months later| K[/evolve-claude]
    K -.-> I

    style B fill:#1e2530,stroke:#6e8cff,color:#e6edf3
    style H fill:#1e2530,stroke:#6e8cff,color:#e6edf3
    style I fill:#1e2530,stroke:#34c69b,color:#e6edf3
    style J fill:#1e2530,stroke:#34c69b,color:#e6edf3
```

Three moving parts, working together:

| Part | What it is | Lives in |
|---|---|---|
| **Portable spine** | Stack-agnostic agents and commands — triage, code-auditor, code-reviewer, duck-debug, lifecycle commands. Copied as-is into your project. | `.claude/agents/`, most of `.claude/commands/` |
| **Templates** | `.tpl` files with `{{MUSTACHE}}` placeholders for anti-pattern codes, hook regexes, BASELINE rules, specialist routing. Rendered during bootstrap. | `.claude/patterns/*.tpl`, `.claude/hooks/*.tpl`, `.claude/CLAUDE.md.tpl`, `.claude/settings.json.tpl` |
| **Meta-skills** | The brains. `/bootstrap-claude` runs the conversation, `/preview-blueprint` renders the HTML confirmation, `/evolve-claude` refines the setup over time. | `.claude/commands/{bootstrap-claude,preview-blueprint,evolve-claude}.md` |

---

## What you get

After bootstrap finishes, your project has a `.claude/` that looks roughly like this — but the **contents** are tuned to your specific stack:

```
your-project/
├── AGENTS.md                           Industry-standard pointer (Cursor / Codex / Aider compatible)
├── .claude/
│   ├── CLAUDE.md                       Lifecycle contract + spec routing
│   ├── agents/
│   │   ├── code-auditor.md             Mechanical L1 reviewer + L1.5 spec-drift (grep + codes + S-*)
│   │   ├── code-reviewer.md            Semantic L2 reviewer (judgment + behavior contract)
│   │   ├── duck-explainer.md           Verbalizes the change in prose
│   │   ├── duck-challenger.md          Probes the explanation, blind to code
│   │   ├── triage-architect.md         Architectural perspective
│   │   ├── triage-engineer.md          DRY + tests perspective
│   │   └── triage-product.md           User-value + MVP perspective
│   ├── commands/
│   │   ├── start-task.md               Worktree + branch creation
│   │   ├── triage.md                   3-perspective pre-dev gate → brief.md on disk
│   │   ├── spec.md                     Mid-weight 1-page spec → spec.md on disk
│   │   ├── architect.md                Heavy spec for L-sized features → spec.md on disk
│   │   ├── brainstorm.md               Divergent design
│   │   ├── code-review.md              Wrapper → code-reviewer subagent
│   │   ├── normalize.md                Read-only audit dispatcher
│   │   ├── duck-debug.md               Rubber-duck orchestrator
│   │   ├── check.md                    Type + lint + format + test loop
│   │   ├── finish-task.md              Coverage → review → check → PR (links spec)
│   │   ├── finish.md                   PR creation
│   │   ├── cleanup-task.md             Worktree + branch removal
│   │   ├── evolve-claude.md            Setup refinement skill
│   │   └── <specialists>.md            /backend, /frontend, /fullstack, ...
│   ├── specs/                          Spec artifacts — the SDD contracts
│   │   ├── README.md                   How specs work in this repo
│   │   ├── _template/                  Runtime templates for /spec and /architect
│   │   │   ├── spec.md.tpl
│   │   │   └── brief.md.tpl
│   │   └── <slug>/                     One folder per task
│   │       ├── spec.md                 The contract — status, scope, behavior, edge cases, tests
│   │       └── brief.md                Optional — when /triage ran but /spec didn't
│   ├── hooks/
│   │   ├── post-edit-backend.sh        Layer-specific anti-pattern regexes
│   │   ├── post-edit-frontend.sh       Layer-specific anti-pattern regexes
│   │   └── check-test-coverage.sh      Coverage gate (if enabled)
│   ├── patterns/
│   │   ├── BASELINE.md                 Non-negotiables (R1–Rn) + spec discipline section
│   │   └── code-review-checklist.md    Full anti-pattern catalog + universal S-* spec codes
│   ├── knowledge/                      Grows as agents accumulate wisdom
│   ├── learning/
│   │   ├── protocol.md                 Telemetry + knowledge contract
│   │   └── violations.md               Append-only ledger
│   └── settings.json                   Hooks wired + permissions allow-list
```

The `.tpl` files are gone after bootstrap — rendered into their final form and removed.

<details>
<summary><b>Example: what a generated BASELINE rule looks like</b></summary>

For a `Node + Express + Prisma + Postgres` project with a multi-tenant model, the bootstrap generates rules like:

> **R1** — Every Prisma query (read AND write) on a multi-tenant table filters by the tenant column.  Anchor: `B-C1`.
> **R2** — Every read filters out soft-deleted rows (`deleted_at: null`).  Anchor: `B-C2`.
> **R4** — Errors use `AppError` subclasses with `ErrorCode`. Never `throw new Error(...)`.  Anchor: `B-C4`.

For a `React + Chakra + TanStack Query` frontend:

> **R10** — Semantic tokens only (`bg.*`, `text.*`, `border.*`). No hardcoded hex.  Anchor: `F-C2`.
> **R14** — Every mutation has `onError`. `invalidateQueries` is selective — never `queryKeys.X.all` unless every sub-key is genuinely affected.  Anchor: `F-C5`, `F-C6`.

The codes (`B-C1`, `F-C2`) are cited by the auditor, the reviewer, and the hooks — one vocabulary across the whole quality stack.

</details>

---

## The 5-phase conversation

The bootstrap is structured as a dialogue, not a form. Each phase discusses one topic at a time, closes with a one-sentence synthesis, and asks permission before advancing.

| # | Phase | What it captures | Skipped when… |
|---|---|---|---|
| 1 | **Product** | One-liner, primary persona, domain, top 3–5 MVP features, UI language | Never — always runs |
| 2 | **Stack** | Language, frameworks, data layer, package manager, monorepo shape, deploy target | Never |
| 3 | **Patterns** | Architecture style, validation, error handling, DI | Already decided by an opinionated stack (Next.js, NestJS, Rails) |
| 4 | **Styles & UI** | Design system, color discipline, theme, i18n, forms | Backend-only projects |
| 5 | **Quality gates** | Specialists, base branch, coverage policy, pre-commit, ticket tracker | Never |

The bot opens with what it detected (from `package.json`, `README.md`, file structure) and takes positions: *"saw Node + TS + React in `package.json`; backend Express, or do you prefer NestJS?"*. You correct in one sentence. The conversation moves.

Whichever language you reply in first locks the entire bootstrap **and** every rendered artifact — `CLAUDE.md`, `BASELINE.md`, blueprint HTML, commit messages, PR descriptions. No mixing.

---

## Lifecycle after bootstrap

```mermaid
flowchart TD
    A[User describes the task in plain language] --> B{Worktree?}
    B -->|"create a worktree"| C[/start-task]
    B -->|default| D[Inline mode]
    C --> SG{Spec exists<br/>or task trivial?}
    D --> SG
    SG -->|no spec, non-trivial| SPEC[/spec OR /triage OR /architect<br/>persist to .claude/specs/&lt;slug&gt;/]
    SG -->|yes / waived| H[Implementing specialist<br/>/backend, /frontend, etc.]
    SPEC --> H
    H --> I[BABYSIT loop]
    I --> L0[L0 spec citation<br/>which sections of spec are implemented]
    L0 --> J[L1 code-auditor<br/>mechanical grep]
    J --> J5[L1.5 spec-drift<br/>diff vs scope, S-C1]
    J5 --> K[L2 code-reviewer<br/>semantic judgment + behavior contract]
    K --> M{M/L task?}
    M -->|yes| MM[L3 /duck-debug<br/>rubber-duck dialogue]
    M -->|no| N[Handoff]
    MM --> N
    N -->|inline| O[Stop. User decides next.]
    N -->|worktree| P[/finish-task]
    P --> Q[Coverage gate → /code-review →<br/>/check → /finish → PR with spec link]
    Q --> R[After merge: /cleanup-task<br/>spec status → shipped]

    style SG fill:#1e2530,stroke:#e5484d,color:#e6edf3
    style SPEC fill:#1e2530,stroke:#6e8cff,color:#e6edf3
    style L0 fill:#1e2530,stroke:#d4a017,color:#e6edf3
    style J fill:#1e2530,stroke:#d4a017,color:#e6edf3
    style J5 fill:#1e2530,stroke:#d4a017,color:#e6edf3
    style K fill:#1e2530,stroke:#d4a017,color:#e6edf3
    style MM fill:#1e2530,stroke:#d4a017,color:#e6edf3
    style Q fill:#1e2530,stroke:#34c69b,color:#e6edf3
```

**Five levels of self-audit run automatically.** L0 anchors the diff to the spec — the specialist restates which sections it's implementing. L1 (`code-auditor`) is mechanical — grep the diff for known anti-pattern codes. L1.5 is spec-drift — the auditor flags any file edited outside `## Scope § In` as `S-C1`. L2 (`code-reviewer`) is semantic — read the diff like a senior engineer would, checking BASELINE rules **and** the spec's `## Behavior contract` + `## Edge cases`. L3 (`/duck-debug`) is verbalization — force the implementer to explain the change in prose to a duck that's blind to the code; the gap in the explanation is the gap in the design.

Every Critical/High finding gets logged to `learning/violations.md`. That's the seed for the next phase.

---

## Keeping the setup alive

The setup decays if nothing updates it. New modules appear. New libraries get added. The same violation keeps showing up in `violations.md` and nobody promotes it. `/evolve-claude` is the antidote.

```bash
/evolve-claude
```

It runs three surveys in parallel:

- **Recurring violations.** Any code with ≥5 hits in the last 30 days is a candidate for promotion into a hook regex (write-time enforcement) or a new BASELINE rule.
- **New modules.** Recent commits added folders that don't yet have `knowledge/<module>.md` entries.
- **Stack drift.** `package.json` (or your stack's equivalent) gained a top-level dependency that changes architecture — new ORM, new state library, new test runner.

It presents everything as a single batched proposal. You pick what to promote, what to ignore, what to defer. The setup gets sharper.

For targeted refinements there are modes:

```bash
/evolve-claude --promote-hook B-C99       # wire a specific code into the hooks
/evolve-claude --add-knowledge payments   # bootstrap a knowledge file for one module
/evolve-claude --refine-stage patterns    # reopen one phase of the bootstrap
/evolve-claude --reset                    # full re-bootstrap (preserves knowledge/ + violations.md)
```

---

## Design philosophy

**Front-load understanding, then get out of the way.** All architectural decisions captured in 5 conversation rounds at the start. After that, the user describes tasks in natural language and the lifecycle drives itself. No more micro-decisions, no more "do you want X or Y here?".

**Take positions, don't interview.** The bootstrap leads with what it detected: *"saw Node + Express in `apps/api`; staying with Prisma or do you prefer Drizzle?"*. Users correct faster than they originate. Open-ended questions multiply work.

**Visual confirmation before writing.** The HTML blueprint is the contract. You see the whole setup on one page — stack, codes, hooks, specialists, file tree — before any file lands on disk. Screenshots are shareable; the blueprint becomes a team artifact.

**Portable spine + project-specific filling.** The agents and lifecycle are universal — they work the same in Cuidda, in a Rust crate, in a Python ETL. The codes, hooks, BASELINE rules are tuned per project. That's why the two halves can update independently — bump the spine via `degit --force`, refine the project parts via `/evolve-claude`.

**Telemetry-driven evolution.** Every Critical/High violation logged in a structured ledger. Recurring patterns get promoted into hooks or BASELINE. The setup doesn't guess at what to enforce — it observes what's actually breaking and tightens those specific rules.

---

## FAQ

<details>
<summary><b>Does this work for non-TypeScript / non-Node projects?</b></summary>

The portable spine (agents, lifecycle commands, triage gate, BABYSIT loop) is fully language-agnostic. The bootstrap interview asks about your stack and renders the templates accordingly.

The built-in anti-pattern catalog has best coverage for Node + TS + React + Prisma + Postgres (the stack this template was distilled from). Other stacks (Python, Go, Rust, Ruby) work but ship with fewer pre-built codes — you'll grow the catalog faster via `/evolve-claude`. PRs adding catalog coverage for new stacks are welcome.

</details>

<details>
<summary><b>What if I already have a `.claude/` in my project?</b></summary>

`degit` refuses to overwrite. Two options:

1. Back up your existing `.claude/`, run `degit`, then port your customizations into the new portable spine.
2. Use `degit --force` if you're sure — but you'll lose any custom agents or commands you wrote.

The `/evolve-claude --reset` mode is designed for this case — it preserves `knowledge/` and `learning/violations.md` while regenerating the rest. If you ran the original bootstrap, prefer this over `degit --force`.

</details>

<details>
<summary><b>Can I share the same setup across multiple repos?</b></summary>

Yes, via the `git submodule` import (see the collapsible in Quick start). The submodule tracks the upstream `claude-setup` repo — when you pull updates upstream, every consumer project that runs `git submodule update` gets the new portable spine.

The project-specific files (`patterns/BASELINE.md`, the rendered hooks) still live inside each consumer's repo, so they can diverge per project without polluting the shared spine.

</details>

<details>
<summary><b>Is the HTML blueprint shareable?</b></summary>

Yes. It's a single self-contained file — no external CSS, no fonts, no images. You can screenshot it, attach the file to a Slack thread, or commit it temporarily to share with your team. The bootstrap deletes it after final confirmation, but you can keep a copy if useful.

</details>

<details>
<summary><b>What's the relationship to Cuidda?</b></summary>

This template was distilled from the production `.claude/` setup of [Cuidda](https://cuidda.com), a clinical SaaS. The original setup evolved over months of real PRs — adding hooks when grep-able anti-patterns kept slipping through, adding the duck loop when latent bugs survived auditor + reviewer, adding the telemetry ledger when we wanted to evolve rules from evidence rather than vibes.

The template here is the architecture stripped of Cuidda-specific content. The portable spine is identical; the per-project content (BASELINE rules tied to Patient PHI, hooks that grep `apps/api` paths, knowledge entries about specific modules) was replaced with templates and a bootstrap that re-derives equivalents for whatever project you point it at.

</details>

---

<div align="center">

<sub>MIT License · maintained by <a href="https://github.com/natanrotta">@natanrotta</a></sub>

</div>
