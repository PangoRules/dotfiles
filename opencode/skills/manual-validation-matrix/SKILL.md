---
name: manual-validation-matrix
description: Use when code review has approved an implementation and manual end-to-end validation is needed before closing the task — after plan execution, feature builds, bug fixes, or refactors
---

# Manual Validation Matrix

Generate a tight manual E2E test matrix after review approval. Confirm what was built matches what was asked.

**Core principle:** Test what changed. Skip what automated tests already cover.

## Step 1 — Read the scope

From plan, spec, PR description, or diff — identify:
- What behaviors were **added or changed**
- What was **not touched** (these become regression targets)
- Any external integrations or side effects

## Step 2 — Build scenarios

One **action → expected result** per step. No compound steps.

Expected results must be explicit — not "it works" but "returns 200", "shows error toast", "redirects to /home".

## Step 3 — Output the matrix

```markdown
## Validate: [Feature / Task Name]

### Setup
- [ ] [required state or prerequisite]

### Happy Path
1. [Do X] → [Y happens]
2. [Do A with B] → [C result]

### Edge Cases
1. [Empty / null / max / boundary input] → [expected error or fallback]
2. [Invalid or unusual state] → [graceful failure, no crash]

### Regressions
1. [Previously working feature] → [still works as before]
2. [Adjacent behavior] → [unchanged]

### Cleanup
- [ ] [restore state / delete test data, if needed]
```

## Calibration by change type

| Change type | Focus |
|-------------|-------|
| New feature | Happy path + edge cases |
| Bug fix | Exact repro passes + similar paths don't break |
| Refactor | Regression-heavy — all existing behavior preserved |
| Integration | External call succeeds + failure mode is handled |
| UI change | Visual states + keyboard/a11y if affected |

## Self-check before handing off

- [ ] Every step has a concrete expected result
- [ ] Regressions cover only what this change could have broken
- [ ] Setup lists every prerequisite — no hidden assumptions
- [ ] Readable and actionable in under 2 minutes
