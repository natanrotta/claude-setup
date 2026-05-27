# Spec — {{TASK_TITLE}}

- **Slug:** `{{TASK_SLUG}}`
- **Status:** `draft` | `approved` | `implementing` | `shipped` | `rejected`
- **Owner:** {{SPEC_OWNER}}
- **Created:** {{CREATED_AT}}
- **Updated:** {{UPDATED_AT}}
- **Source:** `/spec` | `/architect` | `/triage` | `/brainstorm`
- **Size:** S | M | L
- **Tracker link:** {{TRACKER_LINK}}

> The IA refuses to implement against this spec unless `Status: approved`. Move to `implementing` at handoff, `shipped` after PR merges.

---

## 1. Intent (the why)

One paragraph. What problem does this solve, for whom, and how do we know it's solved?

- **Problem:** {{PROBLEM}}
- **Affected user:** {{AFFECTED_USER}}
- **Success signal:** {{SUCCESS_SIGNAL}}

---

## 2. Scope

### In scope
- {{IN_SCOPE_BULLETS}}

### Out of scope (explicit deferrals)
- {{OUT_OF_SCOPE_BULLETS}}

> The auditor reads this section in BABYSIT L1.5. Any file touched outside `## In scope` is flagged as out-of-spec drift.

---

## 3. BASELINE rules to enforce

Cite by ID from `.claude/patterns/BASELINE.md`. Every spec MUST list at least the rules the auditor should check this diff against.

- **R{{RULE_ID}}** — {{RULE_NOTE}}
- ...

---

## 4. Behavior contract

The minimum behavior the implementation MUST satisfy. Write in present-tense imperatives.

- {{BEHAVIOR_BULLET_1}}
- {{BEHAVIOR_BULLET_2}}
- {{BEHAVIOR_BULLET_3}}

---

## 5. Edge cases that probably bite

Top 3–5 scenarios where naive implementations break.

- {{EDGE_CASE_1}}
- {{EDGE_CASE_2}}
- {{EDGE_CASE_3}}

---

## 6. Files

| Action | Path | Why |
|---|---|---|
| Create | {{NEW_FILE}} | {{REASON}} |
| Modify | {{MODIFIED_FILE}} | {{REASON}} |

> The Reuse map (DRY-first protocol from BASELINE) MUST be walked before this table is filled.

---

## 7. Test plan

- **Unit:** {{UNIT_TESTS}}
- **Integration:** {{INTEGRATION_TESTS}}
- **E2E (if applicable):** {{E2E_TESTS}}
- **Coverage gate:** {{COVERAGE_NOTES}}

---

## 8. Open questions

Questions that came up during spec authoring. **All MUST be resolved before `Status: approved`.**

- [ ] {{OPEN_QUESTION_1}}
- [ ] {{OPEN_QUESTION_2}}

---

## 9. Decisions (audit trail)

Append decisions made during implementation that the spec didn't anticipate. Use `/refine-spec <slug>` to formalize.

| Date | Decision | Reason |
|---|---|---|

---

## 10. Links

- **Pre-dev brief:** `brief.md` (if `/triage` ran)
- **Design exploration:** `.claude/specs/{{TASK_SLUG}}/design.md` (if `/brainstorm` ran)
- **PR:** {{PR_URL}} (filled by `/finish-task`)
- **Related specs:** {{RELATED_SPECS}}
