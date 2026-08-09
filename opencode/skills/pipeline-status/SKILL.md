---
name: pipeline-status
description: Use when the user asks "where am I", "what's the status", "what's left", or anything asking for the current state of a milestone/plan/gate without naming a specific agent — reads disk + git state and reports which gate is open and what unblocks it, without requiring the user to know which primary agent's own resume logic to invoke.
---

Fire Keeper and Erwin each detect their own in-progress state (spec-but-no-plans, plan-but-no-PR, etc.) but only when invoked directly and only for their own stage. This skill answers the same question — "what's the state of things" — from cold, for whoever's asking, without picking an agent first.

## Step 1 — Find active milestones

```bash
ls docs/specs/ 2>/dev/null
ls docs/plans/ 2>/dev/null
git branch --list 'feat/*' 'task/*'
```

## Step 2 — Per active spec, determine gate

For each file in `docs/specs/`:
- No matching plan files in `docs/plans/` yet → **GATE 1 open** (spec written, awaiting approval) — or plans genuinely not started yet if the spec was just approved seconds ago; say "spec written, no plans yet" either way, the human knows which.
- Plan files exist, no `task/*` branch under the milestone → **GATE 2 open** (plans written, awaiting approval).
- `task/*` branch(es) exist → in execution. For each: check the plan's own `- [ ]`/`- [x]` state and whether a PR exists (`gh pr list --head <branch>` if `gh` is available) to say "N/M steps done, PR open" or "N/M steps done, no PR yet."

## Step 3 — Report

One line per active milestone/task, plain:
```
feat/ingredient-search — GATE 2 open, 3 plans written, awaiting approval
task/ingredient-search-plan-2 — 4/6 steps done, no PR yet
```
No active specs/plans/branches found → say so plainly ("nothing in flight — ready for a new `/fire_keeper` or `/the_well`"), don't pad.

## When to run

Any primary agent, when the request is a status/state question rather than a task to perform. `@gandalf` is the natural home for this via `roster-routing`'s own table — it already fields "not sure what I need" requests, and "where am I" is the same shape.
