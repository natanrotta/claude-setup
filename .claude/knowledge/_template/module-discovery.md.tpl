# {{MODULE_NAME}} — Module Discovery

**Discovered:** {{DISCOVERED_AT}} via task `{{TASK_SLUG}}` (`/{{SOURCE_SPECIALIST}}`)
**Confidence:** {{CONFIDENCE}}  ·  **Files sampled:** {{FILES_SAMPLED_COUNT}} (top by churn)
**Files reviewed:**
{{FILES_REVIEWED_BULLETS}}

---

## Purpose

{{PURPOSE_PARAGRAPH}}

## Patterns observed

- **Error handling:** {{ERROR_PATTERN}} — cite: `{{ERROR_CITATION}}`
- **Validation:** {{VALIDATION_PATTERN}} — cite: `{{VALIDATION_CITATION}}`
- **Naming:** {{NAMING_PATTERN}} — cite: `{{NAMING_CITATION}}`
- **Test layout:** {{TEST_PATTERN}} — cite: `{{TEST_CITATION}}`
- **Other recurring patterns:** {{OTHER_PATTERNS}}

## Gotchas

- {{GOTCHA_1}}
- {{GOTCHA_2}}
- {{GOTCHA_3}}

## Out of scope (this module does NOT own)

- {{OUT_1}}
- {{OUT_2}}

## Notes for IA editing this module

- Match the patterns above. Don't introduce a different error style "to be consistent with the rest of the project" — `BASELINE.md` is the cross-module rule, this file is the local rule, and **local wins on style decisions**.
- When extending, walk the DRY-first gate from `BASELINE.md` against the files in this module first; only then look across modules.
- If you find a pattern not listed here that you'd add — append it under `Patterns observed` with the citation. Do not rewrite existing entries.

---

## Update history

| Date | Author (agent / user) | What changed |
|---|---|---|
| {{DISCOVERED_AT}} | `/{{SOURCE_SPECIALIST}}` (initial discovery) | First contact, 5 sections filled |
