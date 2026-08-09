---
name: milestone-completion-check
description: Use to check whether a milestone spec's ## Tasks checklist is fully checked off — reports complete/not, remaining count, and which tasks remain. Single source of truth for this check; two independent hand-rolled versions of it (different grep patterns) previously existed and could disagree.
---

Read-only. One definition, so every caller sees the same answer.

## Step 1 — Locate the checklist

Given a spec file path, find its `## Tasks` section. Match unchecked/checked lines under that heading specifically — not any `- [ ]`/`- [x]` elsewhere in the file (a spec can have `- [ ]` prose examples outside the real checklist).

## Step 2 — Count

```bash
grep -c '^- \[ \]' <spec-file>   # unchecked
grep -c '^- \[x\]' <spec-file>   # checked
```
Anchored at line start (`^`), case-sensitive on the lowercase `x` — matches this roster's own checkbox convention exactly (`- [ ]` / `- [x]`, never `- [X]`). If a spec ever contains `- [X]` uppercase, treat it as unchecked-format-drift and report it as a finding rather than silently miscounting.

## Step 3 — Report

- Unchecked count `0` → report: `Complete. All tasks checked in <spec-file>.`
- Unchecked count `> 0` → report: `<N> task(s) remaining in <spec-file>:` followed by the actual unchecked line text (not just the count) — a caller deciding what to do next needs to know *which* tasks, not just how many.

## Idempotent by nature

Read-only — safe to call repeatedly, always reflects current file state.
