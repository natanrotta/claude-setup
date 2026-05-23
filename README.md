# claude-setup

> A reusable, intelligent `.claude/` template that adapts itself to any new project through a conversational bootstrap.

This repo is the **seed** for every new project you start. Drop the `.claude/` folder into an empty repo, run `/bootstrap-claude`, answer 5 short rounds of interview, confirm the visual HTML blueprint, and you have a fully wired Claude Code workspace — task lifecycle, BABYSIT loop, pattern docs, hooks, specialists, telemetry — all tuned to the project you described.

The setup is **not** a static boilerplate. It's:

- **A skeleton** of agents, commands, patterns and hooks that are portable across stacks.
- **A bootstrap skill** that interviews you about the new project and **fills the skeleton** with stack-specific rules, regexes, and routing.
- **A blueprint generator** that produces a single self-contained HTML you confirm before any file is written.
- **An evolve skill** that keeps the setup alive as the project grows (promotes recurring violations into hooks, detects new modules, refines patterns).

---

## How to use it on a new project

### 1. Create your new empty repo and clone it

```bash
gh repo create my-new-project --private --clone
cd my-new-project
```

### 2. Import the `.claude/` folder from this repo

Pick one of three import strategies — they all produce the same starting state:

**Option A — `degit` (recommended, lightest):**
```bash
npx degit natanrotta/claude-setup/.claude .claude
```

**Option B — `curl + tar` (no Node required):**
```bash
curl -L https://github.com/natanrotta/claude-setup/archive/refs/heads/main.tar.gz \
  | tar -xz --strip-components=2 -C . claude-setup-main/.claude
```

**Option C — git submodule (if you want to track upstream updates):**
```bash
git submodule add https://github.com/natanrotta/claude-setup .claude-upstream
ln -s .claude-upstream/.claude .claude
```

### 3. Open Claude Code and run the bootstrap

```bash
claude
```

Inside Claude Code:

```
/bootstrap-claude
```

The skill runs a 5-stage interview (Produto → Stack → Padrões → Estilos → Quality gates). Each stage is one batched `AskUserQuestion` round. Takes about 10 minutes.

### 4. Confirm the visual blueprint

After the interview, the skill generates `.claude/.preview/blueprint.html` and opens it in your browser. You see — in one page — exactly what will be written: stack, architecture, anti-pattern codes, hooks, specialists, quality pipeline, full file tree.

- **Looks right?** Reply `aprovado` (or `approve`). The skill writes the real files into `.claude/`.
- **Want to adjust?** Reply with the change ("muda o stage 3", "remove i18n", etc.). The skill runs a mini-interview just on that point, regenerates the HTML, asks again.

### 5. Start working

Your `.claude/` is now fully tuned. First task:

```
/triage "implementar feature X"
```

The triage runs Architect + Engineer + Product perspectives in parallel, produces a pre-dev brief, and hands off to the right specialist.

---

## What lives in this repo

```
claude-setup/
├── .claude/                     # the template — this is what gets copied
│   ├── agents/                  # portable subagents (triage-*, code-auditor, code-reviewer, duck-*)
│   ├── commands/                # portable skills (start-task, finish-task, triage, normalize, ...)
│   │                            # + meta-skills (bootstrap-claude, preview-blueprint, evolve-claude)
│   ├── hooks/                   # generic post-edit + coverage hooks (regexes filled in by bootstrap)
│   ├── patterns/                # BASELINE / code-review-checklist templates (filled in by bootstrap)
│   ├── knowledge/               # empty — grows as agents accumulate wisdom
│   ├── learning/                # violations.md starts empty
│   └── settings.json            # hook wiring (stack-tailored by bootstrap)
├── blueprint-template/          # HTML + CSS assets for the confirmation page
├── scripts/                     # local helpers (none required, all optional)
└── docs/                        # design rationale, decision logs (not loaded by Claude Code)
```

---

## How it stays alive over time

After bootstrap, the setup is not frozen. Run:

```
/evolve-claude
```

…to:

- Promote codes recurring ≥5× in `learning/violations.md` into hook regexes or BASELINE rules.
- Detect new modules from recent commits and offer to create `knowledge/<module>.md` entries.
- Re-run a focused interview if the stack drifted (new dependency, new sub-project).

The result is a Claude Code workspace that gets sharper with every PR instead of decaying.

---

## Design philosophy

1. **Front-load the interview, then get out of the way.** All decisions captured in 5 batched rounds; after that the user describes tasks in natural language and Claude drives the lifecycle.
2. **Visual confirmation before writing.** The HTML blueprint is the contract — you see the whole setup in 30 seconds before any file lands on disk.
3. **Portable spine + project-specific filling.** Agents, lifecycle, BABYSIT loop are universal. Patterns, hooks, specialists are tuned per project.
4. **Telemetry-driven evolution.** Every Critical/High violation logged. The setup evolves by promoting recurring patterns, not by guessing.
5. **Zero ceremony on the user side.** The user types `/bootstrap-claude` once, answers questions in plain language, confirms, and starts coding.

---

## Inspired by

This template distills the patterns from a production-grade `.claude/` setup that evolved across a real clinical SaaS codebase (Cuidda) — including the triage gate, the 3-level BABYSIT loop (`code-auditor` → `code-reviewer` → `/duck-debug`), the task lifecycle contract, and the violations telemetry ledger.

License: MIT.
