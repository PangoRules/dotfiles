# opencode config

Global opencode configuration, agents, skills, and commands — tracked in dotfiles so any machine gets the same setup.

## What's here

| Path | Purpose |
|------|---------|
| `opencode.json` | Base config: default model (GPT-5.5), plugins, no local providers |
| `agents/planner.md` | **Entry point** — brainstorm → spec gate → architect → plan gate |
| `agents/orchestrator.md` | **Task runner** — dev→review loop → docs → git PR, autonomous |
| `agents/brainstorm.md` | Explores approaches, writes design spec (callable standalone) |
| `agents/architect.md` | Reads spec, writes step-by-step task plans (callable standalone) |
| `agents/developer.md` | Executes plans, commits + pushes incrementally |
| `agents/reviewer.md` | Reviews diffs against plan, finds bugs |
| `agents/docs.md` | Updates project docs, deletes plan file, commits to branch |
| `agents/git.md` | Creates PRs, runs post-merge cleanup |
| `agents/builder.md` | General-purpose, no restrictions |
| `skills/post-merge-cleanup` | After PR merges: tick spec checkbox, delete branch |
| `skills/test-failure-diagnosis` | Diagnose test failures before investigating values |
| `skills/manual-validation-matrix` | Output a test matrix for manual validation |
| `skills/dotnet-verification` | .NET/EF Core build, test, migration-drift check sequence |
| `skills/ef-core-model-test` | Pattern for DB-independent EF Core model contract tests |
| `skills/clean-architecture-boundary-check` | Grep-based Dependency Rule violation check, for review |
| `skills/nuxt-verification` | Nuxt/Vue/TS typecheck, lint, build check sequence |
| `commands/prompt.md` | `/prompt <text>` — optimizes a prompt using Claude best practices |

---

## Agent responsibilities

| Agent | Creates branches | Commits | Pushes | Creates PR | Cleanup |
|-------|-----------------|---------|--------|------------|---------|
| planner | No | No | No | No | No |
| orchestrator | No | No | No | No | No |
| developer | No | Yes | Yes (after each commit) | No | No |
| reviewer | No | No | No | No | No |
| docs | No | Yes (docs + plan deletion) | No | No | No |
| git | No | No | Yes (PR branch) | Yes | Yes |

> Brainstorm creates the milestone branch off main. Developer creates each task branch off the latest milestone branch when the task is picked up (resumes it if already started). Main is read-only — only PRs merge to main.

---

## The full flow

### Your only touchpoints

```
1. /planner      → read spec → "approved" → read plans → "approved"
2. /orchestrator → one call per task, runs autonomously
3. GitHub        → review + merge each PR
4. @git          → "PR merged" → cleanup → repeat
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
Spec written: docs/superpowers/specs/YYYY-MM-DD-<slug>-design.md
Read it. "approved" to proceed, or give feedback to revise.
```

You review. Reply `approved` or give feedback. Planner then calls `@architect`. When plans are written it stops again:

```
Plans written:
- docs/superpowers/plans/YYYY-MM-DD-task-1-<slug>.md
- docs/superpowers/plans/YYYY-MM-DD-task-2-<slug>.md

Read them. "approved" to start work, or give feedback to revise.
```

You review. Reply `approved`. Planner outputs the exact `/orchestrator` calls to run.

---

### Phase 2 — Execute with `/orchestrator`

Run one call per task (in order, or parallel if tasks are independent):

```
/orchestrator
Work from docs/superpowers/plans/YYYY-MM-DD-task-1-<slug>.md
```

Orchestrator runs autonomously:

```
@developer  → resolves the task branch first: resumes it if it already exists
              (checks plan's own checkboxes, picks up from first unchecked
              step), or branches fresh off the latest feat/<milestone> if not
            → implements, ticking each plan checkbox in the same commit as
              its code, commits + pushes incrementally
            → about to get cut for context/perf? pushes a wip: checkpoint
              commit instead of losing the work
@reviewer   → reviews against plan (max 3 cycles), runs stack-specific
              verification skills depending what the diff touches
              (dotnet-verification / clean-architecture-boundary-check /
              nuxt-verification)
  ↺ if findings: @developer fixes → @reviewer re-reviews
@docs       → updates docs/Roadmap + RepoStructure, deletes plan file
@git        → creates PR: task/<slug> → feat/<milestone>
→ outputs PR URL, stops
```

You only get interrupted if 3 review cycles exhaust without LGTM, or an agent hits a hard error.

**Something broke badly mid-task?** `@git` → "drop this branch" → branch deleted (local + remote), plan file untouched. Rerun the same `/orchestrator` call later — developer rebuilds the branch fresh off the feat branch's current tip.

---

### Phase 3 — Merge and cleanup

1. Review the PR on GitHub. Merge it.
2. Switch to `@git` in opencode and type:
   ```
   PR merged
   ```
3. Git agent: pulls milestone branch, deletes task branch (local + remote), ticks spec checkbox.
4. If all milestone tasks are done, git asks:
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
    → @developer resolves branch (resume or fresh off latest feat branch),
                  implements, ticks plan checkboxes live, wip-checkpoints on cutoff
    ↺ @reviewer until LGTM (max 3) — runs stack-specific checks on touched code
    → @docs updates + deletes plan file
    → @git creates PR
  ← [YOU: merge PR on GitHub]
  → @git "PR merged" → cleanup
  ⚠ broke badly mid-task? @git "drop this branch" → rerun /orchestrator, fresh start

when all tasks done:
  → @git creates milestone PR
  ← [YOU: merge milestone to main]
  → @git "PR merged" → spec archived
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

`@docs` checks the project's own `AGENTS.md`/`CLAUDE.md` and existing `docs/` layout first — hydra-forge, for example, uses `scope.md`/`functional-spec.md`/`architecture.md`/`data-model.md`, not this scheme. The numbered layout below only applies when a project has no established convention of its own.

```
docs/
├── 00-Overview.md        — project purpose, goals, non-goals
├── 01-Architecture.md    — system design, layers, key boundaries
├── 02-DataModel.md       — entity definitions, relationships
├── 03-RepoStructure.md   — folder layout, entry points, API reference
├── 04-Setup.md           — local dev setup, env vars, prerequisites
├── 05-Roadmap.md         — milestones, current state, what's next
└── decisions/            — one ADR per architectural decision
```

Specs and plans live in `docs/superpowers/` — plans deleted by docs agent after LGTM, specs archived in git history after milestone merges.

---

## Cloud model setup

All agents use cloud providers. No local runtime required.

| Agent | Model | Why |
|-------|-------|-----|
| brainstorm, architect | `openrouter/deepseek/deepseek-v4-pro` (OpenRouter) | spec + plan creation, needs full reasoning — errors here cascade into every downstream task |
| planner, orchestrator, developer, reviewer, docs, git, builder | `minimax-coding-plan/MiniMax-M2.7` (subscription) | delegation + execution, instruction-following — high volume, push it onto subscription quota, not paid tokens |
| opencode default | `openrouter/deepseek/deepseek-v4-pro` (OpenRouter) | general sessions |

> **Historical note:** `qwen3-coder:latest` (Ollama/local) was the previous developer model — worked well for code generation, dropped in favour of cloud-only setup. `openai/gpt-5.5` was the previous reasoning-tier model — dropped when access lapsed, replaced by `openrouter/deepseek/deepseek-v4-pro` via OpenRouter. `planner` moved off the reasoning tier — it's pure delegation/gate-keeping, same role as `orchestrator`, no reasoning of its own to pay premium for.

### Fallback models (manual)

opencode has no native model-fallback field (`AgentConfig.model` is a single string — confirmed against `https://opencode.ai/config.json` schema). If MiniMax subscription quota runs out or MiniMax infra is down, flip the affected agent's `model:` line by hand:

| Tier | Model | Covers |
|------|-------|--------|
| 1 | `openrouter/minimax/minimax-m2.7` | Subscription quota exhausted — same model, same behavior, just billed through OpenRouter instead. Zero prompt-tuning drift. |
| 2 | `openrouter/deepseek/deepseek-v3.2` | MiniMax infra itself down — tier 1 doesn't help here since it's still MiniMax's backend underneath OpenRouter's billing. Different provider, cheap, strong instruction-following. |

Revert to `minimax-coding-plan/MiniMax-M2.7` once quota/infra recovers — tiers above are paid-per-token, not subscription.

**Automatic fallback exists via community plugin, not installed here:** `opencode-fallback` (youngbinkim0/opencode-fallback) and `opencode-rate-limit-fallback` (liamvinberg/opencode-rate-limit-fallback) both add chain-on-failure switching since opencode core doesn't (open feature request: anomalyco/opencode#8687). Either would let the table above run automatically instead of by hand. Not added to `opencode.json` — third-party code running with full session access is worth reading before trusting; review the actual source first if picking one up later.

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
3. Model ids route through models.dev's catalog, not a model's own provider docs — if a model picked in `/models` doesn't behave as expected, verify the exact `provider/model` key at `https://models.dev/api.json` rather than guessing from a docs page (new models often show in `/models` before the provider's own docs catch up).

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
