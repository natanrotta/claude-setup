# patterns/

This directory contains the **canonical pattern docs** for your project. They are the authority every specialist defers to.

After bootstrap, this directory contains the **rendered** versions of the `.tpl` files:

- `BASELINE.md` — non-negotiables (R1–Rn), the fast-load compass
- `code-review-checklist.md` — full anti-pattern catalog with codes
- (optional) `backend.md`, `frontend.md`, `mobile.md`, etc. — per-layer canonical lifecycle docs

The `.tpl` files stay in the template repo (`claude-setup`) and are not used at runtime. The bootstrap copies the `.tpl`, fills placeholders from interview answers, writes the rendered `.md` here, and removes the `.tpl` from the project (it lives only in the source template).

---

## How to edit

- **Small refinement** (typo, rule wording, new edge case): edit the `.md` directly in your project.
- **Stack-level change** (you swapped your DB, your frontend framework, your test runner): run `/evolve-claude` and select the affected stages — it regenerates only the affected sections.
- **New anti-pattern code**: edit `code-review-checklist.md` directly, then optionally run `/evolve-claude --promote-hook B-C99` to wire it into the hook regex.

## Why keep BASELINE short

BASELINE is a **fast-load compass**. If it grows past ~150 lines, specialists won't read it carefully at every task start. Move detail into the per-layer pattern docs and keep BASELINE focused on the rules whose violation is most expensive.

The full anti-pattern catalog lives in `code-review-checklist.md`. The auditor and reviewer read both.
