---
name: review-cycle-diff
description: Use inside a review-fix loop to classify whether this cycle made progress — REPEAT (same finding survived a fix attempt), NO-PROGRESS (fix commit is a no-op vs its own previous attempt), or NEW-ISSUES (genuinely different findings, loop should continue). Skip on cycle 1 — there's nothing to compare yet.
---

Two independent checks, either one can fire. Both are signals that the loop is stuck, not that the developer or reviewer did something wrong — a stuck loop can mean the plan itself is wrong.

## Check 1 — Repeat signature

Given this cycle's findings and the immediately preceding cycle's findings (skip entirely on cycle 1):

Compare each finding's `file:line` + problem text against the prior cycle's list. A finding counts as **substantively the same** if it names the same file:line and the same underlying problem, even if the wording changed.

Any match → **REPEAT**. Report both cycles' findings side by side — the caller needs to see exactly what didn't change, not just that something didn't change.

## Check 2 — No-progress diff

After a fix commit lands in response to a review cycle, compare it against its own previous fix commit in the same chain (not the original pre-review commit — specifically the last attempted fix):

```bash
git diff <previous-fix-commit-sha> <new-fix-commit-sha>
```

Empty, or trivially equivalent (whitespace/comment-only changes) → **NO-PROGRESS**. The same code was resubmitted. Report the diff (or lack of one) as evidence.

## Otherwise — NEW-ISSUES

Neither check fired: the findings are genuinely different from last cycle, and the fix diff has real content. Report **NEW-ISSUES** — the loop should continue (fix the current findings, increment cycle, review again), this is normal progress, not a stop condition.

## Idempotent by nature

Read-only comparison — safe to call repeatedly, always reflects the actual git state and findings text handed to it.
