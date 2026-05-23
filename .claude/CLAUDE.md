# claude-setup — Template repo (not a project)

This is the **claude-setup** repo. It contains the seed `.claude/` folder that is copied into new projects. Inside *this* repo, Claude Code is mostly used to:

- Maintain the portable agents and commands.
- Refine the bootstrap interview.
- Update the blueprint HTML template.
- Test the bootstrap end-to-end against a scratch project.

**You are not in a project being bootstrapped.** Do not run `/bootstrap-claude` from this repo — it's the source, not the target. To test the bootstrap, copy `.claude/` to a separate empty repo and run the skill there.

---

## Editing rules

- The agents and commands under `.claude/agents/` and `.claude/commands/` are the **portable spine**. Keep them stack-agnostic — no references to specific frameworks (Express, React, Prisma, etc.), specific module names, or specific file paths beyond the generic `.claude/` layout.
- The pattern files under `.claude/patterns/*.tpl` are **templates with placeholders**. Keep placeholders explicit (`{{STACK}}`, `{{SPECIALISTS}}`, `{{RULES}}`, ...). The bootstrap skill replaces them.
- The bootstrap, preview, and evolve skills under `.claude/commands/{bootstrap-claude,preview-blueprint,evolve-claude}.md` are the **brains**. Edit them when you want the interview, the HTML, or the evolution logic to change.
- The blueprint HTML lives in `blueprint-template/blueprint.html.tpl` — single file, self-contained, no external CSS or fonts.

---

## When the user asks for changes inside this repo

Treat changes here as **inline mode** by default (no worktree, no PR — the user owns commit decisions). If the user explicitly asks for a worktree or a PR, follow the standard task lifecycle.

Most edits in this repo fall into one of:

| Intent | Where to edit |
|---|---|
| Add a new portable agent | `.claude/agents/<name>.md` |
| Add a new portable command | `.claude/commands/<name>.md` |
| Change the interview questions | `.claude/commands/bootstrap-claude.md` |
| Change what the HTML blueprint shows | `blueprint-template/blueprint.html.tpl` |
| Add a new anti-pattern code to the catalog | `.claude/patterns/code-review-checklist.md.tpl` |
| Add a new hook check | `.claude/hooks/post-edit-<role>.sh.tpl` |
| Document a design decision | `docs/decisions/<NNNN>-<slug>.md` (create the folder if needed) |

---

## Distribution to consumer projects

When the user wants to test changes in this template against a real project:

1. Push the changes to `main` here.
2. In the target project: `npx degit natanrotta/claude-setup/.claude .claude --force` (overwrites).
3. The target project's customized files (BASELINE, hooks with project-specific regexes, knowledge entries) are NOT overwritten by this — they live outside `.claude/`'s template paths. Only the portable spine refreshes.

For a clean re-bootstrap of a project, the user runs `/evolve-claude --reset` in the target project, which interviews them again and re-renders patterns / hooks / specialists from scratch.

---

## Hard rules for this repo

1. **No project-specific code references** in the portable files. If you see a path like `apps/api/src/...` or a framework name in a portable agent, generalize it.
2. **Templates are templates.** Don't write a complete BASELINE for a specific stack — leave placeholders. The bootstrap fills them.
3. **Test the bootstrap end-to-end** after any change to `bootstrap-claude.md` / `preview-blueprint.md` / `evolve-claude.md` / `blueprint-template/`. Copy `.claude/` to a scratch repo and run the flow.
4. **The HTML blueprint is the user-visible contract.** Changes to it affect every future bootstrapped project — they go through `docs/decisions/` first.
