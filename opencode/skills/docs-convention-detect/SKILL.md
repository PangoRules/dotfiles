---
name: docs-convention-detect
description: Use before writing or updating project documentation — detects whether the project has its own established doc layout (via AGENTS.md/CLAUDE.md or an existing docs/ folder) and maps intents (mark a task done, document a new file, etc.) to the file that already serves them. Falls back to a standard layout only when nothing established exists. Same "detect the convention, don't assume a framework" shape as dependency-vulnerability-scan and error-handling-consistency-check.
---

Do not assume any specific doc layout applies. Check first, every time — a project's own convention always wins over a default.

## Step 1 — Check for an established convention

- Read `AGENTS.md` / `CLAUDE.md` if present — many projects declare their real doc layout there (e.g. `docs/scope.md`, `docs/functional-spec.md` instead of a numbered scheme, or something else entirely).
- Run `ls docs/` and look at what already exists.

## Step 2 — Match by intent, not filename

If the project has its own layout, find the file that already serves each intent below by what it actually contains, not by guessing a filename that matches this skill's own defaults:

| Intent | Look for |
|---|---|
| Mark a milestone/phase task done | Whichever file tracks milestone/phase checklists — could be a roadmap file, or a "live" checklist section inside a functional-spec-type file |
| Document a new file or architectural change | Whichever file documents repo structure/architecture — could be dedicated, or folded into a broader design doc |

## Step 3 — Fall back only if nothing established

Only when the project has no `docs/` folder and no AGENTS.md/CLAUDE.md doc-layout declaration, use this standard layout:

```
docs/
├── scope.md              — vision, personas, goals, non-goals, explicit out-of-scope
├── functional-spec.md    — FRs, NFRs, phase/milestone checklists (LIVE)
├── architecture.md       — system design, layers, key boundaries, patterns, constraints
├── data-model.md         — entity definitions, relationships, enums (authoritative source)
├── glossary.md           — terminology and domain concepts
├── DECISIONS.md          — ADRs inline: D-1, D-2, D-3...
├── backlog.md            — uncommitted ideas and scope-creep items
├── specs/                — active milestone specs
├── plans/                — task plans
├── manual-validation/    — spec-level E2E matrices
└── archive/
    ├── plans/            — shipped plans, archived not deleted
    └── specs/            — completed specs + their final test matrices
```

## Step 4 — Report

Name which path was taken (established convention found + which file matched each intent, or fallback layout used) before doing any actual writing — the caller's next step depends on knowing which file it's about to touch.

## Idempotent by nature

Read-only detection — safe to call repeatedly, always reflects the project's current doc state.
