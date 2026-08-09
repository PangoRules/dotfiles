---
name: spec-task-append
description: Use when a new task is being added mid-milestone — on the milestone's feat branch, with some tasks already done or in progress — to reconcile it into that spec's ## Tasks checklist. Without this, milestone-completion-check can report "all done" while an added task is still open on the same branch, and the spec loses its own audit trail. Idempotent — skips if a matching checkbox already exists.
---

A new task plan on a milestone's feat branch is only half-tracked if the spec itself doesn't know about it. This closes that gap.

## Step 1 — Find the spec

Given a milestone slug (or a feat branch name — the slug is the part after `feat/`), locate `docs/specs/<slug>-design.md` (or whatever the project's actual spec-naming convention is — check `docs/specs/` if the exact filename isn't already known).

## Step 2 — Check for an existing match

Read the spec's `## Tasks` section.

```bash
grep -n '^- \[' docs/specs/<spec-file>
```

If a checkbox already exists whose task name matches the new task closely (same feature, not just similar wording) → **skip, report which existing checkbox already covers it.** Don't create a duplicate.

## Step 3 — Append

No match → append a new checkbox at the end of the `## Tasks` list, same shape as the rest:
```
- [ ] Task <next-N>: <name>
```
Use the next unused execution-order number in that spec — check the highest `<N>` already present, including any letter-suffixed ones (`3a`, `4b`), and continue sensibly from there.

```bash
git add docs/specs/<spec-file>
git commit -m "docs: add task <N> to <milestone-slug> spec (added mid-milestone)"
git push
```

The commit message names it as a mid-milestone addition explicitly — a future reader of the spec's history shouldn't have to guess why a task appeared after others were already checked off.

## Step 4 — Report

One line: which checkbox was added (or which existing one already covered it). The caller passes this new task number to whatever writes the actual plan file next (e.g. `@sokka` in quick mode), so the plan's `**Parent spec:**` header can cite `Task <N>` correctly.

## Idempotent

Re-running against a spec that already has the matching checkbox is a no-op report, not a duplicate append.
