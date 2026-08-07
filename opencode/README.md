# opencode config

Global opencode configuration, agents, skills, and commands — tracked in dotfiles so any machine gets the same setup.

## Agent names

Primary agents (the ones you can switch to / invoke directly, shown in chat) are themed — dark fantasy pulled from Lovecraft, Murakami, Attack on Titan, Dark Souls, and Elden Ring, one codename per universe. Every reference includes the old functional name in parentheses as a hint, e.g. **The Well (init)**, since the codename alone doesn't tell you what it does. Mention/slash-command form is always lowercase, no spaces, underscores for multi-word names: `@well`, `@fire_keeper`, `@commander`, `@tarnished`, `@carter`.

Subagents (`brainstorm`, `architect`, `developer`, `reviewer`, `docs`, `git`) keep their plain functional names — they aren't user-switchable and don't show up in the chat picker, so a codename would only add indirection with no payoff.

| Codename | Formerly | Universe | Why |
|---|---|---|---|
| **The Well** | `init` | Murakami | descent into stillness to define the world before anything's built |
| **Fire Keeper** | `planner` | Dark Souls | tends the flame between two checkpoints, turns raw intent into the structured thing others follow |
| **Commander** | `orchestrator` | Attack on Titan | sends the squad into the loop, holds every hard gate, doesn't flinch when the review loop runs long — knows the difference between stuck and just thorough |
| **Tarnished** | `builder` | Elden Ring | no fixed path, wanders in and does whatever the moment needs |
| **Carter** | `security` | Lovecraft (Randolph Carter) | investigator who goes looking for what's hidden and shouldn't be |

---

## What's here

| Path | Purpose |
|------|---------|
| `opencode.json` | Base config: default model (DeepSeek V4 Pro), plugins |
| `agents/well.md` | **The Well (init)** — thin wrapper around the `project-scaffolding` skill: scope → architecture → data model → glossary → functional-spec, one gate each |
| `agents/fire_keeper.md` | **Fire Keeper (planner)** — brief expansion → brainstorm → spec gate → architect → plan gate |
| `agents/commander.md` | **Commander (orchestrator)** — branch setup → dev → review loop → docs → docs recheck → E2E gate → PR |
| `agents/brainstorm.md` | Explores approaches, writes the finished design spec itself (callable standalone). `@fire_keeper` creates the branch and hands it the target path first — brainstorm Writes, commits (`caveman-commit`), and pushes its own file; still can't call `@git`/`@docs` itself (subagents can't call other subagents in opencode) |
| `agents/architect.md` | Reads spec, writes step-by-step task plan file(s) itself, one per task, flagged `**Test scope:** unit\|http\|e2e` (callable standalone). `@fire_keeper` (milestone mode) or `@tarnished` (standalone quick mode) creates the branch first and hands it the target path; architect Writes, commits, pushes its own file(s) |
| `agents/developer.md` | Executes plans. Implements, ticks plan checkboxes, commits and pushes directly using the `caveman-commit` skill (can't call `@git` itself — same subagent restriction) |
| `agents/reviewer.md` | Captain Levi — reviews diffs against plan. Mandatory pre-LGTM checks: lint/format, new compiler warnings, CVEs on touched manifests, DRY, 75% business-logic coverage (boilerplate excluded via the language's own tag). LGTM output branches on the plan's `**Test scope:**`: `unit` = nothing more, `http` = requires a `.http` file, `e2e` = writes/extends the single spec-level regression matrix directly |
| `agents/docs.md` | **Write mode** (dormant — general-purpose content+path writer, no current caller since brainstorm/architect write their own files now) and **update mode**, split into two commander-triggered calls: post-LGTM (docs update, mark task done, lessons learned — no archiving) and recheck-mode at Step 5.5 (drift check + archive plan + archive spec/matrix if milestone complete, all in one commit) |
| `agents/git.md` | Owns branch creation (milestone/quick/task, called by `@fire_keeper`/`@tarnished`/`@commander`), PR creation, post-merge cleanup. Never commits to `main` without explicit confirmation; checks for lingering uncommitted work before every checkout. Plan archiving is now `@docs`'s job (Step 5.5) — git's own archive step is a defensive fallback only |
| `agents/tarnished.md` | **Tarnished (builder)** — triage: small → implement, complex → escalate to plan, scope creep → backlog |
| `agents/carter.md` | **Carter (security)** — read-only, finds exploitable gaps + vulnerable/outdated deps, writes a severity-ranked report with a `## Tasks` checklist, hands off to `@tarnished`/`@architect` for remediation |
| `skills/project-scaffolding` | Gate-by-gate logic for `@well` — scope/architecture/data-model/glossary/functional-spec, folder scaffold, handoff to `@fire_keeper` |
| `skills/dependency-vulnerability-scan` | SCA — detects whichever package ecosystems are present (npm/pnpm/yarn, NuGet, pip, Go, Cargo, Bundler) and runs the right CVE audit for each. Stack-agnostic |
| `skills/security-code-review` | OWASP-style manual review: injection, XSS, broken authz/IDOR, secrets exposure, SSRF, insecure deserialization, weak crypto, missing rate-limiting/DoS resilience, CSRF, unsafe file upload. Stack-agnostic |
| `skills/python-verification` | Detects configured ruff/mypy/black/pytest and runs what's there — flags missing static analysis honestly instead of assuming tooling exists |
| `skills/playwright-e2e-verification` | Detects an existing Playwright config and runs it — no-ops if a project has no E2E infra, doesn't scaffold one |
| `skills/error-handling-consistency-check` | Detects a project's own error-handling convention (Result/Either, exceptions, Go-style multi-return) and flags deviations + universally-bad patterns (swallowed errors, empty catches) |
| `skills/hardcoded-endpoint-check` | Detects a centralized API-route-constants convention if one exists and flags inline URL literals bypassing it |
| `skills/post-merge-cleanup` | After PR merges: delete branch, archive plan file |
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

| Agent | Creates branches | Writes spec/plan files | Commits | Pushes | Creates PR | Archives | Cleanup |
|-------|-----------------|------------------------|---------|--------|------------|----------|---------|
| well (init) | No | No (via docs, through project-scaffolding skill) | No | No | No | No | No |
| fire_keeper (planner) | **Mediates** (calls `@git`) | No — brainstorm/architect write their own | No | No | No | No | No |
| tarnished (builder) | **Mediates** (calls `@git`, standalone quick-plan only) | No — architect writes its own | No | No | No | No | No |
| brainstorm | No | **Yes** (direct, via Write + `caveman-commit`) | Yes | Yes | No | No | No |
| architect | No | **Yes** (direct, via Write + `caveman-commit`) | Yes | Yes | No | No | No |
| commander (orchestrator) | No | No | No | No | No | No | No |
| git | **Yes** (milestone/quick/task, called by fire_keeper/tarnished/commander) | No | No | Yes | Yes | Defensive fallback only | Yes |
| developer | No | No | **Yes** (direct, via `caveman-commit` skill) | Yes | No | No | No |
| reviewer | No | No (matrix file is the one exception — writes directly on `e2e`-scoped LGTM) | Yes (matrix only) | Yes (matrix only) | No | No | No |
| docs | No | **Yes** (write mode — dormant, no current caller) | Yes (both modes) | Yes | No | **Yes** (recheck mode, Step 5.5 — sole primary owner) | No |
| carter (security) | No | Its own report only (writes + commits directly, like well) | Yes (report only) | Yes | No | No | No |

> Git agent owns all branch operations. `@docs` owns archiving (plan + spec, both at Step 5.5 — git's own archive step is a defensive fallback for the rare case docs got skipped). Neither `brainstorm` nor `architect` nor `developer` can call another agent directly — opencode subagents can't call other subagents — but Write/commit/push on their own file is a plain tool/skill use, not an agent call, so brainstorm and architect now write their own spec/plan files instead of relaying content through `@docs`. `fire_keeper`/`tarnished` (primary agents) still mediate branch creation, since that's a real platform restriction; developer falls back to committing directly via a skill instead of an agent call, same pattern. Main is read-only — only PRs merge to main, and no agent commits directly to `main` without explicit user confirmation.

---

## The full flow

### Your only touchpoints

```
0. /well          → new project only: scope → arch → data model → glossary → roadmap
1. /fire_keeper    → read spec → "approved" → read plans → "approved"
2. /commander      → one call per task, runs autonomously until E2E gate
3. E2E gate        → smoke test → "ready" (or give findings to @tarnished)
4. GitHub          → review + merge each PR
5. @git            → "PR merged" → cleanup → repeat
```

---

### Phase 1 — Plan with `/fire_keeper`

```
/fire_keeper
I want to add ingredient search — users type a name and get matching
inventory items filtered by dietary restriction.
```

Fire Keeper derives a slug from your brief and creates the milestone branch via `@git` first, then calls `@brainstorm` with the target spec path. Brainstorm explores the approaches, asks you whenever a design decision has more than one reasonable path (it no longer silently picks — that was a real bug), then writes the finished spec file itself, commits, and pushes — no relay through `@docs`, which used to be where specs quietly got thinner than they should. Fire Keeper stops and asks:

```
Spec written: docs/specs/YYYY-MM-DD-<slug>-design.md
Read it. "approved" to proceed, or give feedback to revise.
```

You review. Reply `approved` or give feedback. Fire Keeper then calls `@architect` with the spec path; architect drafts, writes, commits, and pushes one plan file per task itself (no new branch — the milestone branch already exists). Each plan is flagged `**Test scope:** unit | http | e2e` — decides later whether the task needs unit tests only, a `.http` file, or an entry in the E2E regression matrix. When plans are committed, Fire Keeper stops again:

```
Plans written:
- docs/plans/YYYY-MM-DD-task-1-<slug>.md
- docs/plans/YYYY-MM-DD-task-2-<slug>.md

Read them. "approved" to start work, or give feedback to revise.
```

You review. Reply `approved`. Fire Keeper outputs the exact `/commander` calls to run.

---

### Phase 2 — Execute with `/commander`

Run one call per task (in order, or parallel if tasks are independent):

```
/commander
Work from docs/plans/YYYY-MM-DD-task-1-<slug>.md
```

Commander runs autonomously until the E2E gate:

```
@git        → Task D: creates task/<slug> off latest feat/<milestone>,
              or resumes it if already exists on remote (lingering
              uncommitted work on the current branch? stops and asks first)
@developer  → confirms it's on the right branch (stops if not),
              checks plan checkboxes, resumes from first unchecked step,
              implements, ticks each plan checkbox in the same commit as
              its code, commits + pushes incrementally itself (via the
              caveman-commit skill — can't call @git directly, same
              subagent restriction as brainstorm/architect)
              → about to get cut for context? pushes a wip: checkpoint
              commit — commander detects wip: prefix and re-invokes
              developer to resume automatically
@reviewer   → Captain Levi. Receives branch name + full commit list for
              context. No cycle cap — runs until LGTM. Mandatory every
              cycle: lint/format, new compiler warnings (vs parent branch
              baseline), CVE scan on any touched dependency manifest, DRY,
              75% coverage on business logic (boilerplate excluded via
              the language's own tag — never tested just to hit the
              number). Plus stack-specific skills depending on what the
              diff touches (dotnet-verification / clean-architecture-
              boundary-check / nuxt-verification / etc). LGTM's next step
              depends on the plan's Test scope: unit = nothing more,
              http = requires a .http file, e2e = writes/extends the
              single spec-level regression matrix directly
  ↺ if findings: @developer fixes → @reviewer re-reviews
      commander watches for STUCK (same finding survives a fix cycle, or
      the fix diff is a no-op vs its own previous attempt → stop, report
      both cycles) and DEAD (a call to @developer/@reviewer errors or
      returns nothing usable → stop, snapshot git status/log, report —
      "dead" means commander stops calling it, there's no separate
      process to kill). Every 10th cycle with no repeat/no dead-agent:
      a soft checkpoint asks you "still finding new things, keep going?"
      instead of silently running forever or hard-stopping
@docs       → updates project docs (per project's own AGENTS.md/CLAUDE.md
              convention), marks spec task checkbox done (- [ ] → - [x]),
              scans git history for lessons not yet in CLAUDE.md/AGENTS.md
              (wip: commits, multi-cycle review findings, WORKAROUND
              comments) and appends them — all in one docs: commit.
              Plan file stays in place, nothing archived yet.

← [YOU: E2E GATE — smoke test or manual validation]
  → "ready" → @docs rechecks (git log since its last commit — catches
              anything the E2E/tarnished loop below changed), archives
              the plan (always) and the spec + matrix (if the milestone's
              last task just closed) in one commit → PR created
  → describe findings → commander can't dispatch @tarnished itself
              (primary agents can't call other primary agents — only a
              human switching sessions can), so it hands you the exact
              paste and tells you to switch to @tarnished manually.
              Tarnished triages: SMALL fix directly on branch, COMPLEX
              escalates to @architect for a new plan on the same feat
              branch, SCOPE CREEP appended to docs/backlog.md. Come back
              and run `/commander Resume gate for <plan-file-path>` — it
              re-detects the E2E gate and re-opens it, same block

@git        → creates PR: task/<slug> → feat/<milestone>
              body includes Plan: + Spec: refs + bullet list from git log
              (plan/spec archiving already done by @docs at Step 5.5 —
              this is a defensive re-check only, for the rare case it
              got skipped)
→ outputs PR URL, stops
```

You get interrupted if the review loop gets stuck or an agent dies mid-cycle, every 10th cycle if it's still finding genuinely new things, an agent hits a hard error, or the E2E gate fires.

**Something broke badly mid-task?** `@git` → "drop this branch" → branch deleted (local + remote), plan file untouched. Rerun the same `/commander` call later — git agent rebuilds the branch fresh off the feat branch's current tip.

---

### Phase 3 — Merge and cleanup

1. Review the PR on GitHub. Merge it.
2. Switch to `@git` in opencode and type:
   ```
   PR merged
   ```
3. Git agent: deletes task branch (local + remote); plan file was already archived to `docs/archive/plans/` at PR creation (defensive re-check via `post-merge-cleanup` skill if that step somehow got skipped). Checks if any unchecked tasks remain in the milestone spec.
4. If all milestone tasks done, git asks:
   > "All tasks complete. Ready to merge feat/\<milestone\> to main?"
5. You say yes → milestone PR created → you review + merge on GitHub → `PR merged` to `@git` → done.

---

## Flow at a glance

```
/fire_keeper
  → fire_keeper: @git creates feat/<slug> off main
  → @brainstorm thinks (asks when ambiguous), writes+commits+pushes spec itself
  ← [YOU: approve spec]
  → @architect writes+commits+pushes plan files itself, each flagged Test scope
  ← [YOU: approve plans]

for each task:
  /commander
    → @git sets up task/<slug> (create or resume off latest feat branch;
                  lingering uncommitted work → stops and asks first)
    → @developer confirms branch, implements, ticks plan checkboxes live,
                  commits + pushes directly via caveman-commit skill,
                  wip-checkpoints on context cutoff (auto-resumed)
    ↺ @reviewer (Captain Levi) until LGTM — no cycle cap. Every cycle:
                  lint/format, new compiler warnings, CVEs, DRY, 75%
                  business-logic coverage, plus stack checks. Commander
                  watches for STUCK (repeated finding / no-progress diff)
                  and DEAD (agent call errors/empty) → stops + reports;
                  soft checkpoint every 10 cycles if still finding new things
    → @docs: update docs + mark spec task done + lessons learned (no archive yet)
  ← [YOU: E2E gate — smoke test, give findings or say "ready"]
      any finding → switch to @tarnished yourself (commander can't
                    dispatch it — no primary-to-primary calls), it fixes
                    SMALL directly, escalates COMPLEX to a new plan, parks
                    SCOPE CREEP in backlog.md → you resume the gate
    → @docs rechecks for drift + archives plan (always) + spec/matrix
                  (if milestone complete) — single commit, single place
    → @git creates PR (Plan: + Spec: refs in body); archive step here is
                  a defensive no-op, docs already did it
  ← [YOU: merge PR on GitHub]
  → @git "PR merged" → cleanup
  ⚠ broke badly? @git "drop this branch" → rerun /commander, fresh start

when all tasks done:
  → @git creates milestone PR
  ← [YOU: merge milestone to main]
  → @git "PR merged" → spec fully checked, branch cleaned
```

---

## Edge cases

**Small bugfix — skip Fire Keeper entirely:**
```
/tarnished
The login form crashes when email is empty. Write a fix plan.
```
Goes through `@tarnished`, not raw `/architect` — architect is a subagent and can't create the branch or write the plan itself once it's done thinking. Tarnished (primary) calls `@architect` for the plan content, creates the branch via `@git` if you're not already on one, then writes it via `@docs`. Then run `/commander` with the plan path.

**Trivial one-liner — skip both:**
```
/tarnished
Fix the typo in the error message on line 42 of auth.ts
```
Tarnished triages it as SMALL and implements directly.

**Reviewer feedback is wrong:**
Commander passes findings to developer which uses `receiving-code-review` — evaluates critically, pushes back on incorrect findings rather than blindly implementing.

**Standalone brainstorm (exploration only, not committing to implementation):**
```
/brainstorm
I'm thinking about switching from REST to tRPC. What are the tradeoffs for this project?
```

**Milestone QA / detective mode (all tasks done, not ready to ship yet):**

When git asks "all tasks complete, ready to merge milestone to main?" — say `not yet`. You're now on `feat/<milestone>`. Do your QA pass and fix what you find:

| What you found | Who |
|----------------|-----|
| Trivial (typo, 1-2 lines) | `/tarnished` — commits directly to milestone branch |
| Multi-step bug or enhancement | `/tarnished` (mediates `@architect` quick plan — you're already on `feat/<milestone>` so no new branch, architect writes its own plan file directly) → `/commander` |
| Several things at once | `/fire_keeper` — groups them into tasks, runs commander per task |

When satisfied, ship the milestone:
```
@git
Submit PR feat/<milestone> to main
```

---

## Security audit

On-demand, not part of the per-task pipeline — run it whenever, against any project:

```
/carter
Audit this app.
```

Read-only. Runs `dependency-vulnerability-scan` (CVE + staleness check across whatever package ecosystems are present) and `security-code-review` (injection, XSS, authz/IDOR, secrets, SSRF, deserialization, rate-limiting/DoS resilience, crypto, CSRF, file upload) — both skills are stack-agnostic, they detect what's actually in the repo rather than assuming a language. Writes a severity-ranked report to `docs/security/` (or `security-audit/` at repo root if the project has no `docs/`), with a `## Tasks` checklist — same milestone-detection shape any spec uses.

Hand-off depends on scope, printed at the end of the audit:
- **1-3 findings** → `@tarnished` with the findings pasted in; tarnished mediates `@architect` (quick plan) + `@git` + `@docs`.
- **4+ findings / multi-domain** → the report itself is spec-shaped. `@git` creates `feat/security-hardening-<date>`, then `@architect` in Milestone mode reads the report directly (same as any spec with a `## Tasks` checklist) and splits it into one plan per finding. Run `/commander` per plan from there.

`reviewer` also runs the two generalized skills below (`error-handling-consistency-check`, `hardcoded-endpoint-check`) conditionally on every normal task diff, not just during a dedicated audit — they catch narrower classes of the same bug families as they're introduced, rather than waiting for the next full audit to find them.

---

## Docs structure (fallback default)

`@docs` checks the project's own `AGENTS.md`/`CLAUDE.md` and existing `docs/` layout first. The layout below is the default for new projects — `project-scaffolding` scaffolds it automatically via `@well`.

```
docs/
├── scope.md              — vision, personas, goals, non-goals, explicit out-of-scope
├── functional-spec.md    — FR-numbered requirements, NFRs, phase/milestone checklists (LIVE)
├── architecture.md       — system design, layers, key boundaries, patterns
├── data-model.md         — entity definitions, relationships, enums (authoritative)
├── glossary.md           — terminology and domain concepts
├── DECISIONS.md          — ADRs inline: D-1, D-2, D-3... one per architectural decision
├── backlog.md            — uncommitted ideas, scope-creep items surfaced during dev
├── specs/                — active milestone specs (moved to archive/ when all tasks done)
├── plans/                — task plans (architect writes+commits+pushes directly; docs archives at Step 5.5, every task — never deleted)
├── manual-validation/    — spec-level E2E matrices (reviewer writes/extends directly on any `e2e`-scoped task's LGTM; no per-plan files, nothing to consolidate)
└── archive/
    ├── specs/            — completed specs + their final test matrices (permanent record)
    └── plans/             — every plan that shipped, archived (not deleted) at Step 5.5, right before PR
```

**Starting a new project?** Run `/well` first — it invokes the `project-scaffolding` skill, working through scope, architecture, data model, glossary, and functional-spec one gate at a time. Each doc is drafted inline, revised until approved, then committed. When `/well` finishes, `functional-spec.md` is your roadmap and `/fire_keeper` takes over for individual features, with a concrete Phase 1 `/fire_keeper` invocation handed to you directly (no re-typing what you just defined). `/fire_keeper` will hard-stop and redirect to `/well` if `functional-spec.md` is missing.

---

## Cloud model setup

All agents use cloud providers. No local runtime required. Strategy: MinMax subscription is spent ONLY where model quality changes real outcomes (developer implementation, reviewer quality gate) — every deterministic/gate-keeping/file-writing role runs on cheap OpenRouter pay-per-token models instead, so it never competes with developer/reviewer for the same subscription's rate limit.

| Agent | Model | Why |
|-------|-------|-----|
| architect | `openrouter/deepseek/deepseek-v4-pro` | plan reasoning needs full strength — errors cascade into every downstream task. Can't write files or touch git even if it wanted to (subagent restriction) — its tokens go entirely to thinking, fire_keeper/tarnished handle the mechanics |
| brainstorm | `openrouter/z-ai/glm-5.2` | creative + 1M-context exploration, leads quality benchmarks among affordable options. Was silently on DeepSeek V4 Flash (cheap, wrong tier) — fixed; now that it no longer burns tokens writing files, the token budget goes to actually thinking well |
| docs | `openrouter/deepseek/deepseek-v4-flash` | deterministic file writes (both content-dump write mode and diff-based update mode) — cheap, fast, low temp (0.3). Previously drifted onto a shared-subscription model at temp 0.5, which is the most likely cause of past "gets stuck / doesn't write files properly" symptoms — fixed |
| developer | `minimax-coding-plan/MiniMax-M2.7` | general purpose, strong instruction-following on plans; subscription model keeps quota usage predictable. Only agent besides reviewer left on the subscription pool |
| reviewer | `minimax-coding-plan/MiniMax-M3` | quality gate — best owned model catches more bugs per cycle |
| tarnished (builder) | `minimax-coding-plan/MiniMax-M2.7` | general purpose, moderate complexity |
| commander (orchestrator) | `openrouter/deepseek/deepseek-v4-flash` | holds hard E2E gate — needs reliable instruction following; M2.5 skipped the gate in practice |
| fire_keeper (planner) | `minimax-coding-plan/MiniMax-M2.5` | gate-keeping only, simpler gates than commander |
| git | `minimax-coding-plan/MiniMax-M2.5` | deterministic bash ops, no gates to hold. Now also creates milestone/quick-mode branches on fire_keeper/tarnished's behalf — still deterministic work, model choice unchanged |
| well (init) | `openrouter/google/gemini-2.5-flash` | large-context Q&A synthesis across five gated docs |
| carter (security) | `openrouter/deepseek/deepseek-v4-pro` | same reasoning tier as architect — triaging exploitability and severity needs real judgment, not just pattern-matching; run rarely (on-demand), so cost matters less than getting it right |
| opencode default | `openrouter/deepseek/deepseek-v4-pro` | general interactive sessions |

> **Historical note:** `qwen3-coder:latest` (Ollama/local) was the original developer model — dropped for cloud-only setup, now back as `openrouter/qwen/qwen3-coder` (same model, OR-hosted) as a fallback option. `openai/gpt-5.5` was a previous reasoning-tier model no longer used. Reviewer sits on M3 (best owned coding model) while developer stays on M2.7 — a deliberate two-tier split within the same subscription. docs and git were both found drifted from their documented models/temps during a July 2026 audit — this table now reflects the corrected, verified state. Primary agents were renamed (init→well, planner→fire_keeper, orchestrator→commander, builder→tarnished) plus a new security→carter agent added in the same pass — see "Agent names" at the top.

### Fallback models (manual)

opencode has no native model-fallback field (`AgentConfig.model` is a single string — confirmed against `https://opencode.ai/config.json` schema). If MiniMax subscription quota runs out or MiniMax infra is down, flip the affected agent's `model:` line by hand:

| Tier | Model | Covers |
|------|-------|--------|
| 1 | `openrouter/minimax/minimax-m3` or `openrouter/minimax/minimax-m2.7` | Subscription quota exhausted — same model, billed through OpenRouter instead. Zero prompt-tuning drift. |
| 2 | `openrouter/deepseek/deepseek-v3` | MiniMax infra itself down — different provider, cheap, strong instruction-following. |

Revert to `minimax-coding-plan/MiniMax-M*` once quota/infra recovers — tiers above are paid-per-token, not subscription.

**Automatic fallback exists via community plugin, not installed here:** `opencode-fallback` (youngbinkim0/opencode-fallback) and `opencode-rate-limit-fallback` (liamvinberg/opencode-rate-limit-fallback) both add chain-on-failure switching since opencode core doesn't. Not added — third-party code with full session access is worth reading before trusting. Worth revisiting now that developer/reviewer are the only agents left contending for MiniMax subscription quota — same exposure as before, just fewer agents sharing it.

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

Add files to `agents/`, `skills/`, or `commands/` and commit. Available on every machine using these dotfiles. New primary agents should follow the naming convention above — themed codename + `(functional name)` hint in the description; new subagents keep plain functional names.

## A hard platform constraint worth remembering

**opencode subagents cannot call other subagents — only primary agents (`well`, `fire_keeper`, `commander`, `tarnished`, `carter`) can dispatch to `@name` agents.** This shaped the design above more than anything else. It's a restriction on *agent-to-agent calls* specifically — not on a subagent's own tool use. Write/Edit and skill invocations (like `caveman-commit`) are plain tool use, not an agent dispatch, so a subagent can write and commit its own file without that counting as delegation:

- `brainstorm` and `architect` (both `mode: subagent`) can never call `@git` or `@docs` themselves, no matter how convenient that would be — `fire_keeper` (milestone mode) or `tarnished` (standalone quick mode) mediates branch creation. But once the branch exists and they've been handed a target path, they Write, commit (`caveman-commit`), and push their own spec/plan file directly — no relay through `@docs`. This changed from an earlier design where they returned content in chat for `@fire_keeper` to relay: that relay step was a real source of thinner, more compressed specs — being told "you're producing a draft for someone else to write" measurably encouraged the model to compress. Being told "you're writing the final file" doesn't.
- `developer` (also `mode: subagent`) can't call `@git` either — it commits and pushes directly, using the `caveman-commit` skill to keep messages conventional. Same shape brainstorm/architect now follow.
- `reviewer` (also `mode: subagent`) follows the same shape for exactly one file: it writes/extends the spec-level E2E matrix directly on an `e2e`-scoped task's LGTM, and commits/pushes it — everything else about its job stays read-only.
- Any future agent added to this system needs the same check before assuming it can delegate: if it's `mode: subagent`, it can use skills and Write/Edit its own designated file freely, but can never dispatch an `@mention` call onward — only report back to whatever called it.
- **The same restriction applies between two primary agents.** `commander` cannot dispatch `@tarnished` mid-turn either, even though both are `mode: primary` — opencode has no primary-to-primary call, only a human manually switching which agent their session is talking to. Every cross-primary handoff in this system (`commander` → `tarnished`, `carter` → `tarnished`/`architect`) follows the same shape: print the exact next command, stop completely, let the human run it. `commander`'s own "Resume gate for `<plan-file-path>`" re-entry logic exists specifically so coming back after one of these manual switches is a clean loop, not a special case.
- **opencode itself has no native timeout/recovery on a hung subagent call** (open upstream gap, confirmed via `anomalyco/opencode` issue tracker as of Aug 2026) — `commander`'s dead-agent detection can only react to a call that *returns* something (error or empty), not a true silent hang. The community plugin `Mte90/opencode-auto-resume` targets exactly this gap ("stops working if a model goes in timeout or there are errors") — worth evaluating as a session-level safety net underneath commander's own logic, not installed here yet (same "read third-party session-access code before trusting" bar the `opencode-fallback` note above already applies).
