# opencode config

Global opencode configuration, agents, skills, and commands — tracked in dotfiles so any machine gets the same setup.

## What's here

| Path | Purpose |
|------|---------|
| `opencode.json` | Base config: default model (DeepSeek V4 Pro), plugins |
| `agents/planner.md` | **Entry point** — brainstorm → spec gate → architect → plan gate |
| `agents/orchestrator.md` | **Task runner** — branch setup → dev → review loop → docs → E2E gate → PR |
| `agents/brainstorm.md` | Explores approaches, writes design spec (callable standalone) |
| `agents/architect.md` | Reads spec, writes step-by-step task plans (callable standalone) |
| `agents/developer.md` | Executes plans, commits + pushes incrementally |
| `agents/reviewer.md` | Reviews diffs against plan, finds bugs, outputs manual validation matrix on LGTM |
| `agents/docs.md` | Updates project docs, marks spec task done, captures lessons in CLAUDE.md/AGENTS.md, commits to branch |
| `agents/git.md` | Sets up task branches, creates PRs, runs post-merge cleanup |
| `agents/builder.md` | Triage: small → implement, complex → escalate to plan, scope creep → backlog |
| `skills/post-merge-cleanup` | After PR merges: delete branch, remove plan file |
| `skills/test-failure-diagnosis` | Diagnose test failures before investigating values |
| `skills/manual-validation-matrix` | Output a test matrix for manual validation |
| `skills/dotnet-verification` | .NET/EF Core build, test, migration-drift check sequence |
| `skills/ef-core-model-test` | Pattern for DB-independent EF Core model contract tests |
| `skills/clean-architecture-boundary-check` | Grep-based Dependency Rule violation check, for review |
| `skills/nuxt-verification` | Nuxt/Vue/TS typecheck, lint, build check sequence |
| `skills/frontend-design` | Distinctive UI design guidance — Nuxt 4, Vue, Spectre.Console; prevents templated AI aesthetics |
| `skills/signalr-verification` | Hub method + event contract check; catches silent real-time failures build/test miss |
| `skills/pgvector-migration-safety` | pgvector pitfalls: transaction-incompatible indexes, missing extension, untyped columns |
| `skills/spectre-tui-verification` | TUI build, smoke run, and feature-parity check against web UI |
| `skills/docker-preflight` | Verify postgres/pgvector/MinIO services before any DB or storage task |
| `commands/prompt.md` | `/prompt <text>` — optimizes a prompt using Claude best practices |

---

## Agent responsibilities

| Agent | Creates branches | Commits | Pushes | Creates PR | Cleanup |
|-------|-----------------|---------|--------|------------|---------|
| planner | No | No | No | No | No |
| orchestrator | No | No | No | No | No |
| git | **Yes** (Task D: task branches) | No | Yes (PR branch) | Yes | Yes |
| developer | No | Yes | Yes (after each commit) | No | No |
| reviewer | No | No | No | No | No |
| docs | No | Yes (docs + spec checkbox + lessons + plan deletion) | No | No | No |

> Git agent owns all branch operations. Developer confirms it's on the right branch before touching any file — stops and reports if not. Main is read-only — only PRs merge to main.

---

## The full flow

### Your only touchpoints

```
1. /planner      → read spec → "approved" → read plans → "approved"
2. /orchestrator → one call per task, runs autonomously until E2E gate
3. E2E gate      → smoke test → "ready" (or give findings to @builder)
4. GitHub        → review + merge each PR
5. @git          → "PR merged" → cleanup → repeat
```

---

### Phase 1 — Plan with `/planner`

```
/planner
I want to add ingredient search — users type a name and get matching
inventory items filtered by dietary restriction.
```

Planner calls `@brainstorm` internally. When spec is written it stops and asks:

```
Spec written: docs/specs/YYYY-MM-DD-<slug>-design.md
Read it. "approved" to proceed, or give feedback to revise.
```

You review. Reply `approved` or give feedback. Planner then calls `@architect`. When plans are written it stops again:

```
Plans written:
- docs/plans/YYYY-MM-DD-task-1-<slug>.md
- docs/plans/YYYY-MM-DD-task-2-<slug>.md

Read them. "approved" to start work, or give feedback to revise.
```

You review. Reply `approved`. Planner outputs the exact `/orchestrator` calls to run.

---

### Phase 2 — Execute with `/orchestrator`

Run one call per task (in order, or parallel if tasks are independent):

```
/orchestrator
Work from docs/plans/YYYY-MM-DD-task-1-<slug>.md
```

Orchestrator runs autonomously until the E2E gate:

```
@git        → Task D: creates task/<slug> off latest feat/<milestone>,
              or resumes it if already exists on remote
@developer  → confirms it's on the right branch (stops if not),
              checks plan checkboxes, resumes from first unchecked step,
              implements, ticks each plan checkbox in the same commit as
              its code, commits + pushes incrementally
              → about to get cut for context? pushes a wip: checkpoint
              commit — orchestrator detects wip: prefix and re-invokes
              developer to resume automatically
@reviewer   → receives branch name + full commit list for context,
              reviews against plan (max 3 cycles), runs stack-specific
              verification skills depending on what the diff touches
              (dotnet-verification / clean-architecture-boundary-check /
              nuxt-verification), outputs manual validation matrix on LGTM
  ↺ if findings: @developer fixes → @reviewer re-reviews
@docs       → updates project docs (per project's own AGENTS.md/CLAUDE.md
              convention), marks spec task checkbox done (- [ ] → - [x]),
              scans git history for lessons not yet in CLAUDE.md/AGENTS.md
              (wip: commits, multi-cycle review findings, WORKAROUND
              comments) and appends them, then deletes plan file —
              all in one docs: commit

← [YOU: E2E GATE — smoke test or manual validation]
  → "ready" → PR created
  → describe findings → @builder triages:
      SMALL: fix directly on branch, then gate loops
      COMPLEX: @architect writes new plan on same feat branch, you run /orchestrator
      SCOPE CREEP: appended to docs/backlog.md, skipped

@git        → creates PR: task/<slug> → feat/<milestone>
              body includes Plan: + Spec: refs + bullet list from git log
→ outputs PR URL, stops
```

You only get interrupted if 3 review cycles exhaust without LGTM, an agent hits a hard error, or the E2E gate fires.

**Something broke badly mid-task?** `@git` → "drop this branch" → branch deleted (local + remote), plan file untouched. Rerun the same `/orchestrator` call later — git agent rebuilds the branch fresh off the feat branch's current tip.

---

### Phase 3 — Merge and cleanup

1. Review the PR on GitHub. Merge it.
2. Switch to `@git` in opencode and type:
   ```
   PR merged
   ```
3. Git agent: deletes task branch (local + remote), removes plan file. Checks if any unchecked tasks remain in the milestone spec.
4. If all milestone tasks done, git asks:
   > "All tasks complete. Ready to merge feat/\<milestone\> to main?"
5. You say yes → milestone PR created → you review + merge on GitHub → `PR merged` to `@git` → done.

---

## Flow at a glance

```
/planner
  → @brainstorm writes spec
  ← [YOU: approve spec]
  → @architect writes plans
  ← [YOU: approve plans]

for each task:
  /orchestrator
    → @git sets up task/<slug> (create or resume off latest feat branch)
    → @developer confirms branch, implements, ticks plan checkboxes live,
                  wip-checkpoints on context cutoff (auto-resumed)
    ↺ @reviewer until LGTM (max 3) — gets commit list, runs stack checks
    → @docs: update docs + mark spec task done + lessons learned + delete plan file
  ← [YOU: E2E gate — smoke test, give findings or say "ready"]
      SMALL finding  → @builder fixes → gate loops
      COMPLEX        → new plan → /orchestrator → gate loops
      SCOPE CREEP    → backlog.md → gate loops
    → @git creates PR (with Plan: + Spec: refs in body)
  ← [YOU: merge PR on GitHub]
  → @git "PR merged" → cleanup
  ⚠ broke badly? @git "drop this branch" → rerun /orchestrator, fresh start

when all tasks done:
  → @git creates milestone PR
  ← [YOU: merge milestone to main]
  → @git "PR merged" → spec fully checked, branch cleaned
```

---

## Edge cases

**Small bugfix — skip planner entirely:**
```
/architect
The login form crashes when email is empty. Write a fix plan.
```
Then run `/orchestrator` with the plan path.

**Trivial one-liner — skip both:**
```
/builder
Fix the typo in the error message on line 42 of auth.ts
```
Builder triages it as SMALL and implements directly.

**Reviewer feedback is wrong:**
Orchestrator passes findings to developer which uses `receiving-code-review` — evaluates critically, pushes back on incorrect findings rather than blindly implementing.

**Standalone brainstorm (exploration only, not committing to implementation):**
```
/brainstorm
I'm thinking about switching from REST to tRPC. What are the tradeoffs for this project?
```

**Milestone QA / detective mode (all tasks done, not ready to ship yet):**

When git asks "all tasks complete, ready to merge milestone to main?" — say `not yet`. You're now on `feat/<milestone>`. Do your QA pass and fix what you find:

| What you found | Who |
|----------------|-----|
| Trivial (typo, 1-2 lines) | `/builder` — commits directly to milestone branch |
| Multi-step bug or enhancement | `/architect` quick plan → `/orchestrator` |
| Several things at once | `/planner` — groups them into tasks, runs orchestrator per task |

When satisfied, ship the milestone:
```
@git
Submit PR feat/<milestone> to main
```

---

## Docs structure (fallback default)

`@docs` checks the project's own `AGENTS.md`/`CLAUDE.md` and existing `docs/` layout first. The layout below is the default for new projects — `@brainstorm` scaffolds it automatically when `docs/` is missing.

```
docs/
├── scope.md              — vision, personas, goals, non-goals, explicit out-of-scope
├── functional-spec.md    — FRs, NFRs, phase/milestone checklists (LIVE)
├── architecture.md       — system design, layers, key boundaries, patterns
├── data-model.md         — entity definitions, relationships, enums (authoritative)
├── glossary.md           — terminology and domain concepts
├── DECISIONS.md          — ADRs inline: D-1, D-2, D-3... one per architectural decision
├── backlog.md            — uncommitted ideas, scope-creep items surfaced during dev
├── specs/                — milestone design specs (brainstorm writes, permanent)
└── plans/                — task plans (architect writes, deleted after LGTM)
```

**Starting a new project?** Run `/planner` as normal — `@brainstorm` detects the empty `docs/` folder, scaffolds the structure, populates `scope.md` and `functional-spec.md` from the first spec, and commits everything in one shot before the spec approval gate.

---

## Cloud model setup

All agents use cloud providers. No local runtime required. Strategy: MinMax subscription covers high-volume agents; OpenRouter budget targets creative/planning and cheapest summarization.

| Agent | Model | Why |
|-------|-------|-----|
| architect | `openrouter/deepseek/deepseek-v4-pro` | plan creation needs full reasoning — errors cascade into every downstream task |
| brainstorm | `openrouter/google/gemini-2.5-flash` | creative + large-context exploration; 1M window reads existing specs/CLAUDE.md/AGENTS.md in full |
| docs | `openrouter/google/gemini-2.5-flash-lite` | summarization and doc writes — cheapest workload, Flash Lite is sufficient |
| developer | `openrouter/qwen/qwen3-coder` | coding specialist — purpose-built for code gen and instruction-following; frees MinMax quota for reviewer where quality gates matter |
| reviewer | `minimax-coding-plan/MiniMax-M3` | quality gate — best owned model catches more bugs per cycle |
| builder | `minimax-coding-plan/MiniMax-M2.7` | general purpose, moderate complexity |
| orchestrator | `minimax-coding-plan/MiniMax-M2.5` | pure delegation, no reasoning needed |
| planner | `minimax-coding-plan/MiniMax-M2.5` | gate-keeping only, same role as orchestrator |
| git | `minimax-coding-plan/MiniMax-M2.5` | deterministic bash ops, minimal reasoning |
| opencode default | `openrouter/deepseek/deepseek-v4-pro` | general interactive sessions |

> **Historical note:** `qwen3-coder:latest` (Ollama/local) was the original developer model — dropped for cloud-only setup, now back as `openrouter/qwen/qwen3-coder` (same model, OR-hosted). `openai/gpt-5.5` was the previous reasoning-tier model. All agents previously flat on `MiniMax-M2.7` — now tiered: M3 for reviewer quality gate, Qwen3 Coder for developer (coding specialist, cheap OR), M2.7 for general, M2.5 for routing. Brainstorm moved from DeepSeek to Gemini Flash for larger context window when reading existing project docs.

### Fallback models (manual)

opencode has no native model-fallback field (`AgentConfig.model` is a single string — confirmed against `https://opencode.ai/config.json` schema). If MiniMax subscription quota runs out or MiniMax infra is down, flip the affected agent's `model:` line by hand:

| Tier | Model | Covers |
|------|-------|--------|
| 1 | `openrouter/minimax/minimax-m3` or `openrouter/minimax/minimax-m2.7` | Subscription quota exhausted — same model, billed through OpenRouter instead. Zero prompt-tuning drift. |
| 2 | `openrouter/deepseek/deepseek-v3` | MiniMax infra itself down — different provider, cheap, strong instruction-following. |

Revert to `minimax-coding-plan/MiniMax-M*` once quota/infra recovers — tiers above are paid-per-token, not subscription.

**Automatic fallback exists via community plugin, not installed here:** `opencode-fallback` (youngbinkim0/opencode-fallback) and `opencode-rate-limit-fallback` (liamvinberg/opencode-rate-limit-fallback) both add chain-on-failure switching since opencode core doesn't. Not added — third-party code with full session access is worth reading before trusting.

---

## Plugins

Loaded automatically on startup. Verify with `cat ~/.local/share/opencode/log/<latest>.log | grep "service=plugin"`.

| Plugin | Purpose |
|--------|---------|
| `superpowers` | Skills framework — all agent skills load through this |
| `opencode-vibeguard` | Masks secrets/tokens before sending to cloud providers |
| `opencode-dynamic-context-pruning` | Compresses stale context, deduplicates tool calls — saves tokens on long sessions |
| `opencode-shell-strategy` | Teaches agents to use non-interactive flags (`-y`, `--no-edit`) — prevents hangs |
| `type-inject` | Injects TypeScript type signatures when reading `.ts`/`.tsx` files |
| `opencode-notifier` | Desktop notification + sound on completion, permission requests, errors |

---

## Per-machine setup

1. Run `bash ~/dotfiles/bootstrap.sh`
2. Connect providers via `/connect` inside opencode — set API keys for OpenRouter and MiniMax/ZEN
3. Model ids route through models.dev's catalog, not a model's own provider docs — if a model picked in `/models` doesn't behave as expected, verify the exact `provider/model` key at `https://models.dev/api.json` rather than guessing from a docs page.

### Current provider config

```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "openrouter/deepseek/deepseek-v4-pro",
  "plugin": [
    "superpowers@git+https://github.com/obra/superpowers.git",
    "opencode-vibeguard@git+https://github.com/inkdust2021/opencode-vibeguard",
    "opencode-dynamic-context-pruning@git+https://github.com/Opencode-DCP/opencode-dynamic-context-pruning",
    "opencode-shell-strategy@git+https://github.com/JRedeker/opencode-shell-strategy",
    "type-inject@git+https://github.com/nick-vi/type-inject",
    "opencode-notifier@git+https://github.com/mohak34/opencode-notifier"
  ],
  "agent": {
    "developer": { "steps": 30 }
  }
}
```

---

## Adding new agents, skills, or commands

Add files to `agents/`, `skills/`, or `commands/` and commit. Available on every machine using these dotfiles.
