# 0001 — Template architecture

**Date:** 2026-05-23
**Status:** Accepted

## Context

We want a reusable `.claude/` setup that adapts itself to new projects through conversation, rather than a static boilerplate that requires manual customization for every new project.

The user's existing `.claude/` (in Cuidda) evolved into a production-grade structure: triage gate, BABYSIT 3-level loop, telemetry ledger, lifecycle contract. Re-creating that from scratch on every new project is expensive.

## Decision

The repo ships **three things bundled**:

1. **Portable spine** — agents, commands, and lifecycle docs that are stack-agnostic. Copied as-is into the new project's `.claude/`.
2. **Template files** (`.tpl` suffix) — pattern docs, hooks, settings.json, root `CLAUDE.md`, and specialist agent shapes. Contain `{{MUSTACHE}}` placeholders.
3. **Meta-skills** — `/bootstrap-claude` (5-stage interview), `/preview-blueprint` (HTML confirmation), `/evolve-claude` (post-bootstrap refinement). These are the brains that turn an interview into a rendered config.

A separate `blueprint-template/blueprint.html.tpl` contains the visual confirmation page rendered by `/preview-blueprint`.

The flow in a new project is:

1. `degit natanrotta/claude-setup/.claude .claude`
2. `/bootstrap-claude` — 5-stage interview (~10 min)
3. `/preview-blueprint` — visual confirmation (HTML in browser)
4. User approves → bootstrap writes the rendered files, deletes `.tpl`s
5. `/evolve-claude` — periodic refinement as the project grows

## Alternatives considered

**Plugin-only.** Push everything into a Claude Code plugin. Rejected because the per-project files (BASELINE, hooks with regexes, knowledge entries) must live IN the project for grep, telemetry, and version control.

**Template repo + manual fork.** Clone and edit by hand. Rejected because the user's stated pain is exactly that — manual customization per project.

**Pure CLI scaffolder** (`npx create-claude-setup --stack=nextjs`). Rejected because non-AI scaffolding can't adapt to nuanced project goals (the "objectives / functionalities / patterns / styles" the user wanted to discuss).

**Hybrid (chosen).** Combines plugin-like portability of agents with a template repo that the bootstrap skill renders. Best of both worlds.

## Consequences

**Positive:**
- Single command starts the bootstrap (`/bootstrap-claude`) — zero friction.
- HTML blueprint is a shareable artifact — the user can show it to their team before any code is generated.
- Setup evolves with the project (`/evolve-claude`) — does not decay.
- Portable spine updates apply uniformly via `degit --force`.

**Negative:**
- The bootstrap skill is large (every stack the user might pick requires a built-in catalog of anti-pattern codes, hook regexes, baseline rules). Initial investment is real.
- `.tpl` extension is non-standard — anyone reading the repo for the first time needs the README to understand the structure.
- Re-bootstrapping a long-lived project is risky — must preserve `knowledge/`, `learning/violations.md`, and manual customizations. `/evolve-claude --reset` handles this explicitly.

## Open items (deferred to next iterations)

- Stack catalog completeness — initial bootstrap supports Node/React/Prisma; adding Python/Go/Rust catalogs is incremental.
- Multi-project mode — what if the user wants the same setup across 5 sibling projects? (Today: re-run bootstrap per project.)
- Plugin packaging — eventually wrap this as a proper Claude Code plugin, so portable agents update automatically. For v1 we ship via `degit`.
