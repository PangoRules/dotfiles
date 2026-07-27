---
name: project-scaffolding
description: Use when defining a brand-new project from scratch, before any implementation begins — works through scope, architecture, data model, glossary, and functional-spec gates with the user, one document at a time.
---

Define what's being built before any code is written. Ask, listen, synthesize, and write foundational docs one at a time — each gate produces one approved document. Do not write implementation code or plans here; that's `@fire_keeper`'s job once this skill hands off.

Reference shape below is validated against a real multi-phase project (12 phases, 194 numbered FRs) that actually shipped through five phases using this exact document set — it's not a hypothetical template.

## Step 0 — Resume detection

```bash
ls docs/*.md 2>/dev/null
```
- **Nothing exists** → start at Step 1.
- **Some files exist** → list them, tell the user which gates are already done, resume from the first missing file. Do not re-do approved docs.

---

## Step 1 — Project identity → `scope.md`

Ask:
```
Three questions before we define the scope:

1. What problem does this solve, and who has it?
2. What does this product do that nothing else does well enough?
3. What is explicitly NOT in scope — things that might seem obvious but you're intentionally leaving out?
```
**STOP. Wait for answers.**

Synthesize into `scope.md`:
- Project name, one-line description, version/date header
- Vision (2-3 sentences — what makes this distinct, not just what it does)
- The problem (a table: problem → impact, if multiple distinct pain points)
- The solution (how the pieces fit together at a glance)
- Personas — who uses it, primary/secondary/emerging, what each needs
- In-scope modules — grouped by area, one line per module, table form scales better than prose once you're past ~10 modules
- Out of scope — table: item → rationale. Every excluded item gets a reason, not just a name — "explicitly excluded" items are the ones people re-propose later, the rationale is what stops the re-litigation
- Change request triggers — what requires a scope discussion before work begins (new external integration, re-scoping an out-of-scope item, replacing a core infra choice, etc.)
- Development phases — sequential, one goal sentence per phase. This becomes the backbone `functional-spec.md` checklists hang off in Step 5, so name phases by *milestone outcome*, not by calendar time ("Project Space — Web UI: full board usable in browser", not "Sprint 3")
- Constraints (regulatory, technical, timeline, team)

Show the draft inline. Do not write the file yet.

### GATE 1 — Scope review
```
scope.md draft above. Approve or give feedback.
```
**STOP. Wait for user.**
- Approved → write `docs/scope.md`, commit (`docs: define project scope`), go to Step 2.
- Feedback → revise inline, return to GATE 1.

---

## Step 2 — Technical direction → `architecture.md`

Ask:
```
Three questions for the architecture:

1. What's your stack? (languages, frameworks, databases, deployment target)
2. What already exists that this integrates with or replaces?
3. Any hard constraints? (must be offline-capable, must use X, cannot use Y, must fit in Z budget)
```
**STOP. Wait for answers.**

Synthesize into `architecture.md`:
- System overview (what it is, what it isn't — one paragraph)
- Layer structure — name the actual layers and the dependency direction between them (e.g. `Domain ← Application ← Infrastructure ← Server/Client`). If it's Clean Architecture, say so explicitly and name what belongs in each layer — this table gets read by `@architect` on every future plan, ambiguity here compounds
- Key patterns (CQRS, event-driven, REST vs GraphQL, real-time transport, etc.)
- Component map — major pieces and how they connect
- Cross-cutting concerns worth settling now: error handling shape (exceptions vs Result types), auth model, real-time strategy — these are expensive to change once code exists, cheap to decide now
- Key constraints and non-negotiables
- What's deferred (explicitly out of scope for now, revisit later)

Show the draft inline.

### GATE 2 — Architecture review
```
architecture.md draft above. Approve or give feedback.
```
**STOP. Wait for user.**
- Approved → write `docs/architecture.md`, commit (`docs: define system architecture`), go to Step 3.
- Feedback → revise inline, return to GATE 2.

---

## Step 3 — Data model → `data-model.md`

Based on scope + architecture, infer the core entities. Ask:
```
Looking at what we defined — here are the entities I can infer:
<list entities you can derive from scope + architecture>

Questions:
1. What am I missing or getting wrong?
2. Any enums or fixed value sets we should define now? (statuses, types, roles, categories)
3. Any relationships that aren't obvious?
```
**STOP. Wait for answers.**

Synthesize into `data-model.md`:
- Entity table per entity: fields, types, constraints, notes
- Relationship map (one-to-many, many-to-many, ownership — call out FK ownership explicitly when a field can be owned by more than one entity type, that ambiguity causes real bugs later)
- Enum definitions with all values and their meaning
- Explicitly note fields that are TBD or deferred

Show the draft inline.

### GATE 3 — Data model review
```
data-model.md draft above. Approve or give feedback.
```
**STOP. Wait for user.**
- Approved → write `docs/data-model.md`, commit (`docs: define initial data model`), go to Step 4.
- Feedback → revise inline, return to GATE 3.

---

## Step 4 — Terminology → `glossary.md`

Extract domain terms from everything said so far:
```
Domain terms I've picked up — correct or add:
<list of terms with one-line definitions>
```
**STOP. Wait for corrections/additions.**

Write `glossary.md` — alphabetical, one term per entry:
```
**Term** — definition. Distinguish from <similar term> if needed.
```

### GATE 4 — Glossary review
```
glossary.md draft above. Approve or give feedback. (Quick gate — usually just additions.)
```
**STOP. Wait for user.**
- Approved → write `docs/glossary.md`, commit (`docs: define domain glossary`), go to Step 5.
- Feedback → revise, return to GATE 4.

---

## Step 5 — Roadmap → `functional-spec.md`

Ask:
```
Last gate: the roadmap.

1. What are the phases or milestones? (pull from scope.md's Development Phases if already listed there)
2. What's in each phase at a high level?
3. What must ship in Phase 1 for the project to be considered "started"?
```
**STOP. Wait for answers.**

This is the document every other agent in the system reads most — `@architect` splits phases into plans, `@docs` ticks checkboxes here every task, `@fire_keeper` gates on it existing at all. Use the FR-numbered shape, not a bare bullet list — it scales to a large project without losing traceability, and every requirement gets a stable ID other docs/commits can reference (`D-14 supersedes FR-88`, `plan fixes FR-102`).

```markdown
# <Project Name> — Functional Specification

> **Version:** 1.0
> **Date:** YYYY-MM-DD

## Table of Contents
<one entry per section below>

> ✅ = Confirmed | ❓ = Needs discussion | 🔜 = Future

## 1. <Domain Area 1>

| # | Requirement | Status |
|---|---|---|
| FR-1 | <requirement, specific and testable> | ✅ |
| FR-2 | ... | ✅ |

## 2. <Domain Area 2>
...continue numbering FRs sequentially across all sections, never restart per-section...

## N. Non-Functional Requirements

| # | Requirement | Target |
|---|---|---|
| NFR-1 | <e.g. page load time> | < 2 seconds |
| NFR-2 | <e.g. test coverage> | > 90% |

## N+1. Development Phase Checklists

### Phase 1: <name> 🏗️
> Goal: <one sentence>
- [ ] <milestone or feature — this becomes one @brainstorm spec later>
- [ ] <milestone or feature>

### Phase 2: <name>
...
```

Group FRs by domain area (auth, real-time, a given feature module), not by phase — phases reference FRs, they don't own them, since a phase's scope can shift without renumbering every requirement. Status starts `✅` for anything the user confirmed; use `❓` for anything you're inferring and flagging back to them, `🔜` for explicitly-future items that shouldn't block current phases.

If a phase has a decision that must be made before implementation starts (e.g. "pick a file storage backend before Phase 2"), add a `> ⚠️ **Pre-phase decision needed:** ...` blockquote directly under that phase's heading with a recommendation — don't bury infra decisions in prose the architect has to hunt for.

The checkboxes are LIVE — `@docs` ticks them as work completes. Never delete checked items.

Show the draft inline.

### GATE 5 — Functional spec review
```
functional-spec.md draft above. Approve or give feedback.
This is the roadmap everything else runs from — take your time.
```
**STOP. Wait for user.**
- Approved → write `docs/functional-spec.md`, commit (`docs: define functional specification and roadmap`), go to Step 6.
- Feedback → revise inline, return to GATE 5.

---

## Step 6 — Scaffold remaining structure

```bash
mkdir -p docs/specs docs/plans docs/manual-validation docs/archive/specs docs/archive/plans docs/archive/manual-validation
```

Write `docs/DECISIONS.md` stub:
```markdown
# Architecture Decision Records

<!-- Format: ## D-N: <title> | Date | Context | Decision | Consequences -->
```

Write `docs/backlog.md` stub:
```markdown
# Backlog

<!-- Items surfaced during development that are out of scope for current milestone -->
```

```bash
git add docs/ && git commit -m "docs: scaffold remaining documentation structure"
```

A project may grow docs beyond this baseline set as it goes (e.g. a standalone vision/pipeline doc for a specific subsystem) — that's fine, `@brainstorm` or the user can add those ad hoc later. This skill only owns the five gated foundational docs plus the folder scaffold.

---

## Step 7 — Done, hand off with a concrete next step

Report to user:
```
Project defined. All foundational docs committed:

  docs/scope.md              ✓
  docs/architecture.md       ✓
  docs/data-model.md         ✓
  docs/glossary.md           ✓
  docs/functional-spec.md    ✓
  docs/DECISIONS.md          ✓ (empty)
  docs/backlog.md            ✓ (empty)

Phase 1 goal: <pull the actual Phase 1 goal sentence from functional-spec.md>

Run:
/fire_keeper
<restate Phase 1's goal as a one-line brief, pulled from functional-spec.md — not a generic
placeholder. The user just spent five gates defining this; the handoff should not make them
re-type it.>
```
Stop.

---

## Rules

- Never skip a gate. Each doc must be explicitly approved before moving on.
- Never invent content the user hasn't confirmed. Ask when uncertain.
- Revise inline (in chat) before writing to file. File = approved version only.
- If user wants to revisit an already-approved doc: re-open that gate, revise, recommit.
- If user says "good enough for now" on any gate: accept it, note it's provisional, move on.
- One commit per document. No batch commits across multiple docs.
