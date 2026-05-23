# blueprint-template/

Single self-contained HTML file that `/preview-blueprint` renders into `.claude/.preview/blueprint.html` for visual confirmation before the bootstrap writes any real files.

## Files

- `blueprint.html.tpl` — the template, all CSS inlined, no external dependencies

## Design constraints

1. **Self-contained.** No CDN, no external fonts, no remote images. The user must be able to open the file with no internet and see the same thing.
2. **Dark by default.** Matches Claude Code aesthetics. Single theme — no light variant.
3. **Optimized for screenshot.** The full page renders well at 1280px width — important because the user often shares the blueprint with their team via screenshot.
4. **One screen for the gist.** Hero + MVP features + Stack badges should fit in the viewport on a 1440x900 display so the first impression is "wow, that's my project".
5. **Mustache-style placeholders.** All replacements use `{{PLACEHOLDER}}`. No conditional blocks — `/preview-blueprint` emits empty strings for absent sections.

## Sections

| Section | Purpose |
|---|---|
| Hero | Product one-liner + key meta (persona, domain, language, base branch) |
| MVP features | What ships in v1 — concrete list, no jargon |
| Stack pinned | Visual badges for each tech choice |
| Architecture | ASCII diagram of the chosen layer structure |
| Anti-pattern codes | Table of codes the auditor will catch |
| Hooks | Which scripts run when, on which files |
| Specialists | One card per `/backend`, `/frontend`, ... configured |
| Pipeline | Visual flow of triage → babysit → finish-task |
| File tree | Exactly what will be written into `.claude/` |
| Next steps | Concrete commands for the user |

## When to edit

- Adding a new section: extend the template, add a `{{NEW_PLACEHOLDER}}`, update `/preview-blueprint` to populate it.
- Adjusting visuals: edit the `<style>` block. Keep all CSS inline — no extracting to a separate file.
- Adding theme variations: don't. Single dark theme is the design.
