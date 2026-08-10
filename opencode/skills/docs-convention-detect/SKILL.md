---
name: docs-convention-detect
description: Use before writing or updating project documentation — detects whether the project has its own established doc layout (via AGENTS.md/CLAUDE.md or an existing docs/ folder), builds a full inventory of every living doc file so ad-hoc topic docs aren't missed, and maps intents (mark a task done, document a new file, etc.) to the file that already serves them. Falls back to a standard layout only when nothing established exists. Same "detect the convention, don't assume a framework" shape as dependency-vulnerability-scan and error-handling-consistency-check.
---

Do not assume any specific doc layout applies. Check first, every time — a project's own convention always wins over a default. Real projects accumulate documentation the fixed schema below never anticipates (e.g. a `docs/board-workflow.md` or `docs/admin-llm-providers.md` that grew organically) — missing that inventory is how a doc silently goes stale: nothing ever flags it for an update because nothing ever knew it existed.

## Step 1 — Check for an established convention

- Read `AGENTS.md` / `CLAUDE.md` if present — many projects declare their real doc layout there (e.g. `docs/scope.md`, `docs/functional-spec.md` instead of a numbered scheme, or something else entirely).
- Run `ls docs/` and look at what already exists.

## Step 2 — Full living-doc inventory (do this every time, not just on first contact)

A shallow `ls docs/` misses nested topic docs and subdirectories. Build the real list:

```bash
find . -iname "*.md" -not -path "*/node_modules/*" -not -path "*/archive/*" -not -path "*/.git/*"
```

Exclude `archive/` on purpose — those are frozen historical record, not living docs to keep current (see the caller's own archiving step for why). Everything else in this list is a candidate target: `README.md`, `CLAUDE.md`, `AGENTS.md`, every fixed-schema file, and every ad-hoc topic doc a project has accumulated (a `board-workflow.md`, an `agent-platform-vision.md`, a `docs/security/*.md`, whatever exists that doesn't match any named convention below). Skim each one's title/first heading — you need enough of a map to judge topical relevance in Step 3, not to have memorized the contents.

## Step 3 — Match by topic and intent, not filename

For whatever change or lesson you're documenting, check the **full inventory from Step 2 first** — an existing doc that already covers this exact topic always wins, whether or not it matches one of the named intents below. Only fall through to the fixed-schema intents, and only create a new file, when nothing in the inventory already owns the topic:

| Intent | Look for |
|---|---|
| Mark a milestone/phase task done | Whichever file tracks milestone/phase checklists — could be a roadmap file, or a "live" checklist section inside a functional-spec-type file |
| Document a new file or architectural change | Whichever file documents repo structure/architecture — could be dedicated, or folded into a broader design doc |
| Anything else topical (a subsystem, an admin feature, a workflow) | Check the Step 2 inventory for an existing doc on that exact subject before assuming none exists — a project's ad-hoc docs are exactly where this kind of thing already lives |

Creating a brand-new topic doc is the last resort, not the default — prefer updating whatever already exists on the subject, however it's named.

## Step 4 — Fall back only if nothing established

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

## Step 5 — Report

Name which path was taken (established convention found + which file matched each intent, or fallback layout used) plus the full Step 2 inventory (file list) before doing any actual writing — the caller's next step depends on knowing the whole set of candidate files, not just the one it thinks it needs.

## Idempotent by nature

Read-only detection — safe to call repeatedly, always reflects the project's current doc state. Re-run it every time, not just once per session — the inventory changes as docs get added.
