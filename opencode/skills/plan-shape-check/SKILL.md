---
name: plan-shape-check
description: Use to validate a plan file has the standard shape before trusting or committing it — a real header (**Branch:**/**Parent branch:**) and a parseable - [ ]/- [x] checklist, not prose or a plain numbered list. Used both at write time (architect self-checking before committing a new plan) and at read time (before a caller trusts an existing plan's step boundaries).
---

A plan that looks plausible and isn't actually parseable breaks every downstream step silently — no error, just wrong step boundaries or a milestone that never gets tracked. This check exists to catch that before it propagates.

## Step 1 — Header check

Read the plan file. Confirm at minimum:
```
**Branch:** `<name>`
**Parent branch:** `<name>`
```
are both present, each on their own line, non-empty. (`**Parent spec:**` and `**Test scope:**` are expected on milestone-mode plans but are not the hard minimum — flag their absence separately, don't fail the whole check on them.)

Missing either of the two required headers → **INVALID: missing header**, name which one.

## Step 2 — Checklist check

Confirm the plan's step list is discrete `- [ ]` / `- [x]` checkboxes, one per step:
```bash
grep -c '^- \[[ x]\]' <plan-file>
```
Zero matches → **INVALID: no parseable checklist**. A plain numbered list (`1. Do X`), steps buried in paragraphs, or prose-only "plan" all fail this check — they aren't a structural fix away from being usable, they need actual reformatting.

## Step 3 — Report

- Both checks pass → **VALID**. Nothing further.
- Either fails → report which one, with the specific missing/malformed element quoted. Do not guess at the intended structure or silently proceed — that's exactly the failure mode this check exists to prevent.

**At write time** (architect, right after drafting, before committing): a failure here means fix the draft before writing it — cheapest point to catch this.
**At read time** (a caller about to trust an existing file's step boundaries): a failure here means route to reformat mode rather than improvising step detection against a malformed file.

## Idempotent by nature

Read-only — safe to call repeatedly, always reflects current file content.
