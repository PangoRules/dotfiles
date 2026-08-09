---
name: post-fix-review
description: Use after any ad hoc code fix that landed outside the normal plan-review loop — mikasa's off-script bug hunt, tarnished's SMALL-triage direct implement — to send it through levi's independent review before calling it done. The person/agent who wrote the fix is never the one who verifies it, no exceptions for "it was just a quick fix." No plan file required — levi already handles that case.
---

A fix isn't done because the person who wrote it ran the tests and they passed. That's self-report, not verification — the same reason levi never trusts arthur's "tests pass" claim without running them independently. This skill is what makes that same independence apply to fixes that don't go through the normal Step 3/4 plan loop.

## Step 1 — Get the commit range

Call `@hosea` (`git-state-query`): commits on `<branch>` ahead of its parent (or since the fix started, if that's more precise than "ahead of parent").

## Step 2 — Dispatch levi

Call `@levi`:
```
Review this fix on branch <branch> — no plan file, ad hoc fix.
Commits: <paste from hosea>
What it was fixing: <one-line description from whoever authored the fix>

Review DEEPLY: full mandatory checks, actually run the build and the
full test suite (not just this fix's own repro case) — do not infer
pass/fail from reading code or from the fix author's own report.
```
No `**Test scope:**` header exists for this path — that's expected. Levi already has a documented fallback for exactly this (treats missing-header work as `e2e`-safest by convention); don't invent one yourself.

## Step 3 — Liveness + loop, same shape as erwin's Step 4

Invoke `agent-liveness-check` (real-time mode) on levi's response — DEAD → stop, report, snapshot git state, same as any other dead-agent case.

**LGTM** → done. Report LGTM back to whoever invoked this skill, with levi's own phrasing quoted.

**Findings** → invoke `review-cycle-diff` against the previous cycle (skip on cycle 1). REPEAT/NO-PROGRESS → same stuck-report-and-offer-mikasa shape as erwin's Step 4 findings path — this can mean the fix's own root cause was wrong, not just that the fix needs polish. NEW-ISSUES → dispatch findings back to whoever authored the fix (mikasa for a root-cause hunt, arthur for a SMALL-triage fix) to address, then return to Step 2 for a fresh cycle.

## Never skip this because the fix was small

A one-line fix can still break a lint rule, drop test coverage, or introduce a regression levi's mandatory checks exist specifically to catch. "It was just a quick fix" is not a stopping condition — the loop above is the same rigor as any plan step's review, just without a plan file to point at.
