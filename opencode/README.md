# opencode config

Global opencode configuration, agents, skills, and commands — tracked in dotfiles so any machine gets the same setup.

## Agent names

Primary agents (the ones you can switch to / invoke directly, shown in chat) are themed — dark fantasy and adventure fiction pulled from Lovecraft, Murakami, Attack on Titan, Dark Souls, Elden Ring, S.T.A.L.K.E.R., Red Dead Redemption 2, and now LOTR, one codename per universe (a couple of universes cover two roles each — AoT gives us Commander, the debugger, and now brainstorm; RDR2 gives us git and developer). Every reference includes the old functional name in parentheses as a hint, e.g. **The Well (init)**, since the codename alone doesn't tell you what it does. Mention/slash-command form is always lowercase, no spaces, underscores for multi-word names: `@the_well`, `@fire_keeper`, `@erwin`, `@tarnished`, `@carter`, `@strelok`, `@mikasa`, `@gandalf`.

**The four you live in day to day:** `@the_well` (new project), `@fire_keeper` (plan the next feature), `@erwin` (build an approved plan), `@tarnished` (quick task, no ceremony). `@carter`, `@strelok`, `@mikasa` are on-demand specialists you reach for by name when the situation calls for them. `@gandalf` is the fifth touchpoint for when you don't know which of the above you need — see "Not sure where to start?" below.

Subagents (`brainstorm`, `architect`, `developer`, `reviewer`, `docs`, `git`) keep their plain functional names — they aren't user-switchable and don't show up in the chat picker, so a codename would only add indirection with no payoff. Every subagent now carries a `## Voice` section too (same pattern as the primaries) — it colors prose only, never the file formats, commit messages, or checklist conventions those agents produce.

**Correction (2026-08-08):** an earlier pass here had `brainstorm` reusing The Well's voice. Wrong — The Well is `init` only, the one-time project-from-zero agent. Brainstorm now has its own character (Armin Arlert) below.

| Codename | Formerly / role | Universe | Why |
|---|---|---|---|
| **The Well** | `init` | Murakami | descent into stillness to define the world before anything's built — project creation only, not reused elsewhere |
| **Fire Keeper** | `planner` | Dark Souls | tends the flame between two checkpoints, turns raw intent into the structured thing others follow — calls brainstorm then architect when starting a new phase |
| **Commander (Erwin)** | `orchestrator` | Attack on Titan | sends the squad into the loop, holds every hard gate, doesn't flinch when the review loop runs long — knows the difference between stuck and just thorough |
| **Tarnished** | `builder` | Elden Ring | no fixed path, wanders in and does whatever the moment needs — the driver for quick tasks and implementations |
| **Carter** | `security` | Lovecraft (Randolph Carter) | investigator who goes looking for what's hidden and shouldn't be |
| **Gandalf** | `router` (new) | LOTR | knows every member of the roster by their strengths, sends you to the one built for what you actually need |
| **Sokka** | `architect` (subagent) | Avatar: The Last Airbender | the plan guy — three steps ahead, writes it down before anyone swings |
| **Arthur Morgan** | `developer` (subagent) | Red Dead Redemption 2 | rides out and does the job while the planning happens elsewhere |
| **Captain Levi** | `reviewer` (subagent) | Attack on Titan | zero tolerance for sloppy work, respects competence when he sees it |
| **Uncle Iroh** | `docs` (subagent) | Avatar: The Last Airbender | patient teacher, cares more that the next person understands than being impressive |
| **Hosea Matthews** | `git` (subagent) | Red Dead Redemption 2 | scouts the road, checks the saddles, minds what nobody else remembers to |
| **Armin Arlert** | `brainstorm` (subagent) | Attack on Titan | sees the whole board — the plan survives because he questioned it from every side first |
| **Strelok** | `explore` | S.T.A.L.K.E.R. | maps hostile terrain, leaves markers, reports without changing anything |
| **Mikasa Ackerman** | `debugger` | Attack on Titan | closes distance on a bug one eliminated possibility at a time, doesn't stop until it's dead |

### Not sure where to start?

```
/gandalf
<describe what you're trying to do, however roughly>
```
Gandalf knows the whole roster, asks one clarifying question if genuinely unclear, and hands back the exact next command — it doesn't do the work itself, same primary-can't-dispatch-primary restriction as everyone else.

---

## What's here

| Path | Purpose |
|------|---------|
| `opencode.json` | Base config: default model (DeepSeek V4 Pro), plugins |
| `agents/the_well.md` | **The Well (init)** — thin wrapper around the `project-scaffolding` skill: scope → architecture → data model → glossary → functional-spec, one gate each |
| `agents/fire_keeper.md` | **Fire Keeper (planner)** — brief expansion → brainstorm → spec gate → architect → plan gate. Resume-aware (detects an in-progress spec/plan gate and re-opens it instead of restarting blind) |
| `agents/erwin.md` | **Commander (orchestrator)** — branch setup → dev → review loop → docs → docs recheck → E2E gate → PR. Anything that isn't a plan-execution request (bug report, new idea, question) gets routed straight to `@gandalf` instead of improvised |
| `agents/armin.md` | Explores approaches, writes the finished design spec itself (callable standalone). `@fire_keeper` creates the branch and hands it the target path first — brainstorm Writes, commits (`caveman-commit`), and pushes its own file; still can't call `@hosea`/`@iroh` itself (subagents can't call other subagents in opencode). Reports a short goal recap alongside the committed path, not just the filename |
| `agents/sokka.md` | Reads spec, writes step-by-step task plan file(s) itself, one per task, flagged `**Test scope:** unit\|http\|e2e` (callable standalone). `@fire_keeper` (milestone mode) or `@tarnished` (standalone quick mode) creates the branch first and hands it the target path; architect Writes, commits, pushes its own file(s). Milestone mode asks upfront whether to checkpoint after each plan or batch the whole set for one review; either way, reports a goal recap alongside each path |
| `agents/arthur.md` | Executes plans. Implements, ticks plan checkboxes, commits and pushes directly using the `caveman-commit` skill (can't call `@hosea` itself — same subagent restriction) |
| `agents/levi.md` | Captain Levi — reviews diffs against plan. Mandatory pre-LGTM checks: lint/format, new compiler warnings, CVEs on touched manifests, DRY, 75% business-logic coverage (boilerplate excluded via the language's own tag). LGTM output branches on the plan's `**Test scope:**`: `unit` = nothing more, `http` = requires a `.http` file, `e2e` = writes/extends the single spec-level regression matrix directly |
| `agents/iroh.md` | **Write mode** (dormant — general-purpose content+path writer, no current caller since brainstorm/sokka write their own files now) and **update mode**, split into two commander-triggered calls: post-LGTM (docs update, mark task done, lessons learned — no archiving) and recheck-mode at Step 5.5 (drift check + archive plan + archive spec/matrix if milestone complete, all in one commit) |
| `agents/hosea.md` | Thin dispatcher over the `git-*` skills below — branch creation (milestone/quick/task, called by `@fire_keeper`/`@tarnished`/`@erwin`), commit, stash, tag/revert/cherry-pick/amend, PR creation, post-merge cleanup, read-only state query for `@erwin`. Keeps only the judgment calls and hard rules itself (voice, confirmation gates, never merge/rebase/reset, never push `main` without confirmation, lingering-uncommitted-work preflight). Plan archiving is `@iroh`'s job (Step 5.5) — the PR-create skill's own archive step is a defensive fallback only |
| `agents/tarnished.md` | **Tarnished (builder)** — triage: small → implement, complex → escalate to plan (reconciling into the milestone's spec first via `spec-task-append` if it's a mid-milestone addition), scope creep → backlog |
| `agents/carter.md` | **Carter (security)** — read-only, finds exploitable gaps + vulnerable/outdated deps, writes a severity-ranked report with a `## Tasks` checklist, hands off to `@tarnished`/`@sokka` for remediation |
| `agents/strelok.md` | **Strelok (explorer)** — read-only codebase mapping, on demand or as a manual hand-off target from `@erwin`/`@fire_keeper`. Never edits, never writes a report unless explicitly asked |
| `agents/mikasa.md` | **Mikasa Ackerman (debugger)** — systematic bug hunter, on demand or as a manual hand-off target when a `@erwin` review cycle goes STUCK. Reproduces, isolates root cause, fixes it, commits — narrow scope, no adjacent refactors |
| `agents/gandalf.md` | **Gandalf (router)** — entry point for "not sure what I need." Classifies the request against the full roster (including mid-milestone additions, abandon/cleanup, resume, and reverting a shipped feature), asks one clarifying question if unclear, hands back the exact next command. Never does the work itself |
| `skills/project-scaffolding` | Gate-by-gate logic for `@the_well` — scope/architecture/data-model/glossary/functional-spec, folder scaffold, handoff to `@fire_keeper` |
| `skills/dependency-vulnerability-scan` | SCA — detects whichever package ecosystems are present (npm/pnpm/yarn, NuGet, pip, Go, Cargo, Bundler) and runs the right CVE audit for each. Stack-agnostic |
| `skills/security-code-review` | OWASP-style manual review: injection, XSS, broken authz/IDOR, secrets exposure, SSRF, insecure deserialization, weak crypto, missing rate-limiting/DoS resilience, CSRF, unsafe file upload. Stack-agnostic |
| `skills/python-verification` | Detects configured ruff/mypy/black/pytest and runs what's there — flags missing static analysis honestly instead of assuming tooling exists |
| `skills/playwright-e2e-verification` | Detects an existing Playwright config and runs it — no-ops if a project has no E2E infra, doesn't scaffold one |
| `skills/error-handling-consistency-check` | Detects a project's own error-handling convention (Result/Either, exceptions, Go-style multi-return) and flags deviations + universally-bad patterns (swallowed errors, empty catches) |
| `skills/hardcoded-endpoint-check` | Detects a centralized API-route-constants convention if one exists and flags inline URL literals bypassing it |
| `skills/git-branch-setup` | Create or resume a branch off a base — generic (bare names) or project mode (reads a plan file's Branch/Parent branch headers). Idempotent |
| `skills/git-pr-create` | Open a PR, pull Plan:/Spec: refs + real commits into the body in project mode. Idempotent — returns the existing PR's URL instead of duplicating |
| `skills/git-commit` | Draft a Conventional Commits message via `caveman-commit`, then actually stage and commit it — the draft skill never runs git itself |
| `skills/git-abandon-branch` | Delete a branch local + remote for a scrapped task — checks for and asks about any open PR first. Cascade mode abandons a whole milestone (feat branch + every child task branch) with one confirmed list. Idempotent on already-gone branches |
| `skills/spec-task-append` | Reconciles a mid-milestone task addition into that spec's `## Tasks` checklist before it's planned — keeps `milestone-completion-check` honest. Idempotent — skips a matching existing checkbox |
| `skills/git-state-query` | Read-only git/gh lookups for callers (like `@erwin`) with no bash of their own — output stays verbatim |
| `skills/git-post-merge-cleanup` | After PR merges: mark spec checkbox, archive plan file, delete branch, `git fetch --prune`, detect milestone completion |
| `skills/git-stash` | Stash/pop/list/drop uncommitted changes. Idempotent against an empty stash |
| `skills/git-history-edit` | Tag, revert, cherry-pick, amend — amend only on unpushed commits, revert/cherry-pick never target `main` directly, no force-push without the literal request |
| `skills/plan-shape-check` | Validates a plan file's header + `- [ ]`/`- [x]` checklist shape. Used by `@sokka` right after drafting (catch at source) and `@erwin` before trusting a plan it didn't write |
| `skills/agent-liveness-check` | Classifies a subagent dispatch result DEAD/WIP/OK (real-time mode, `@erwin`'s dead-agent/resume checks), or scans a commit range for `wip:` commits (history-scan mode, `@iroh`'s Lessons Learned) — one definition of the `wip:` convention instead of two |
| `skills/review-cycle-diff` | Classifies a review cycle REPEAT/NO-PROGRESS/NEW-ISSUES against the previous cycle's findings/fix-commit — `@erwin`'s stuck-loop detection |
| `skills/coverage-check` | Generic native-tool coverage fallback (tsc+vitest/jest, go test -cover, cargo tarpaulin) for stacks with no dedicated verification skill — `@levi` never gets a silent "no coverage check ran" |
| `skills/milestone-completion-check` | Single definition of "is this spec's `## Tasks` checklist fully checked" — used by both `git-post-merge-cleanup` and `@iroh`'s Recheck Mode, previously two independent grep patterns that could disagree |
| `skills/docs-convention-detect` | Detects a project's own doc layout (AGENTS.md/CLAUDE.md, `ls docs/`) before `@iroh` writes anything, falls back to the standard layout only if nothing established exists |
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
| fire_keeper (planner) | **Mediates** (calls `@hosea`) | No — brainstorm/sokka write their own | No | No | No | No | No |
| tarnished (builder) | **Mediates** (calls `@hosea`, standalone quick-plan only) | No — architect writes its own | No | No | No | No | No |
| armin (brainstorm) | No | **Yes** (direct, via Write + `caveman-commit`) | Yes | Yes | No | No | No |
| sokka (architect) | No | **Yes** (direct, via Write + `caveman-commit`) | Yes | Yes | No | No | No |
| erwin (orchestrator) | No | No | No | No | No | No | No |
| hosea (git) | **Yes** (milestone/quick/task, called by fire_keeper/tarnished/erwin) | No | No | Yes | Yes | Defensive fallback only | Yes |
| arthur (developer) | No | No | **Yes** (direct, via `caveman-commit` skill) | Yes | No | No | No |
| levi (reviewer) | No | No (matrix file is the one exception — writes directly on `e2e`-scoped LGTM) | Yes (matrix only) | Yes (matrix only) | No | No | No |
| iroh (docs) | No | **Yes** (write mode — dormant, no current caller) | Yes (both modes) | Yes | No | **Yes** (recheck mode, Step 5.5 — sole primary owner) | No |
| carter (security) | No | Its own report only (writes + commits directly, like well) | Yes (report only) | Yes | No | No | No |
| strelok (explore) | No | No | No | No | No | No | No |
| mikasa (debugger) | No | No | Yes (fix only) | Yes | No | No | No |
| gandalf (router) | No | No | No | No | No | No | No |

> Git agent owns all branch operations. `@iroh` owns archiving (plan + spec, both at Step 5.5 — git's own archive step is a defensive fallback for the rare case docs got skipped). Neither `brainstorm` nor `architect` nor `developer` can call another agent directly — opencode subagents can't call other subagents — but Write/commit/push on their own file is a plain tool/skill use, not an agent call, so brainstorm and architect now write their own spec/plan files instead of relaying content through `@iroh`. `fire_keeper`/`tarnished` (primary agents) still mediate branch creation, since that's a real platform restriction; developer falls back to committing directly via a skill instead of an agent call, same pattern. Main is read-only — only PRs merge to main, and no agent commits directly to `main` without explicit user confirmation.

---

## The full flow

### Your only touchpoints

```
?. /gandalf        → not sure which of the below fits? ask here first
0. /the_well          → new project only: scope → arch → data model → glossary → roadmap
1. /fire_keeper    → read spec → "approved" → read plans → "approved"
2. /erwin      → one call per task, runs autonomously until E2E gate
3. E2E gate        → smoke test → "ready" (or give findings to @tarnished)
4. GitHub          → review + merge each PR
5. @hosea            → "PR merged" → cleanup → repeat
```

---

### Phase 1 — Plan with `/fire_keeper`

```
/fire_keeper
I want to add ingredient search — users type a name and get matching
inventory items filtered by dietary restriction.
```

Fire Keeper derives a slug from your brief and creates the milestone branch via `@hosea` first, then calls `@armin` with the target spec path. Brainstorm explores the approaches, asks you whenever a design decision has more than one reasonable path (it no longer silently picks — that was a real bug), then writes the finished spec file itself, commits, and pushes — no relay through `@iroh`, which used to be where specs quietly got thinner than they should. Fire Keeper stops and asks:

```
Spec written: docs/specs/YYYY-MM-DD-<slug>-design.md
Read it. "approved" to proceed, or give feedback to revise.
```

You review. Reply `approved` or give feedback. Fire Keeper then calls `@sokka` with the spec path; before drafting anything, architect asks whether you want a checkpoint after each plan or the whole batch drafted for one review (shown below is the batch shape — one-by-one just means this same gate repeats per plan instead of once at the end). Architect drafts, writes, commits, and pushes one plan file per task itself (no new branch — the milestone branch already exists). Each plan is flagged `**Test scope:** unit | http | e2e` — decides later whether the task needs unit tests only, a `.http` file, or an entry in the E2E regression matrix. When plans are committed, Fire Keeper stops again:

```
Plans written:
- docs/plans/YYYY-MM-DD-task-1-<slug>.md
- docs/plans/YYYY-MM-DD-task-2-<slug>.md

Read them. "approved" to start work, or give feedback to revise.
```

You review. Reply `approved`. Fire Keeper outputs the exact `/erwin` calls to run.

---

### Phase 2 — Execute with `/erwin`

Run one call per task (in order, or parallel if tasks are independent):

```
/erwin
Work from docs/plans/YYYY-MM-DD-task-1-<slug>.md
```

Commander runs autonomously until the E2E gate:

```
@hosea        → git-branch-setup: creates task/<slug> off latest feat/<milestone>,
              or resumes it if already exists on remote (lingering
              uncommitted work on the current branch? stops and asks first)
@arthur  → confirms it's on the right branch (stops if not),
              checks plan checkboxes, resumes from first unchecked step,
              implements, ticks each plan checkbox in the same commit as
              its code, commits + pushes incrementally itself (via the
              caveman-commit skill — can't call @hosea directly, same
              subagent restriction as brainstorm/sokka)
              → about to get cut for context? pushes a wip: checkpoint
              commit — commander detects wip: prefix and re-invokes
              developer to resume automatically
@levi   → Captain Levi. Receives branch name + full commit list for
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
  ↺ if findings: @arthur fixes → @levi re-reviews
      commander watches for STUCK (same finding survives a fix cycle, or
      the fix diff is a no-op vs its own previous attempt → stop, report
      both cycles and suggest switching to @mikasa — Mikasa — with the
      branch and finding pasted in, since a repeat like this usually means
      the symptom's being patched, not the root cause) and DEAD (a call to
      @arthur/@levi errors or returns nothing usable → stop,
      snapshot git status/log, report — "dead" means commander stops
      calling it, there's no separate process to kill). Every 10th cycle
      with no repeat/no dead-agent: a soft checkpoint asks you "still
      finding new things, keep going?" instead of silently running
      forever or hard-stopping
@iroh       → updates project docs (per project's own AGENTS.md/CLAUDE.md
              convention), marks spec task checkbox done (- [ ] → - [x]),
              scans git history for lessons not yet in CLAUDE.md/AGENTS.md
              (wip: commits, multi-cycle review findings, WORKAROUND
              comments) and appends them — all in one docs: commit.
              Plan file stays in place, nothing archived yet.

← [YOU: E2E GATE — smoke test or manual validation]
  → "ready" → @iroh rechecks (git log since its last commit — catches
              anything the E2E/tarnished loop below changed), archives
              the plan (always) and the spec + matrix (if the milestone's
              last task just closed) in one commit → PR created
  → describe findings → erwin dispatches @tarnished directly (Task tool,
              no manual switch needed — fallback to printing the command
              only if the dispatch itself errors). Tarnished triages:
              SMALL fix directly on branch, COMPLEX escalates to @sokka
              for a new plan on the same feat branch, SCOPE CREEP
              appended to docs/backlog.md. Erwin re-opens the same E2E
              gate block once tarnished reports back

@hosea        → creates PR: task/<slug> → feat/<milestone>
              body includes Plan: + Spec: refs + bullet list from git log
              (plan/spec archiving already done by @iroh at Step 5.5 —
              this is a defensive re-check only, for the rare case it
              got skipped)
→ outputs PR URL, stops
```

You get interrupted if the review loop gets stuck or an agent dies mid-cycle, every 10th cycle if it's still finding genuinely new things, an agent hits a hard error, or the E2E gate fires.

**Something broke badly mid-task?** `@hosea` → "drop this branch" → branch deleted (local + remote), plan file untouched. Rerun the same `/erwin` call later — git agent rebuilds the branch fresh off the feat branch's current tip.

---

### Phase 3 — Merge and cleanup

1. Review the PR on GitHub. Merge it.
2. Switch to `@hosea` in opencode and type:
   ```
   PR merged
   ```
3. Git agent: deletes task branch (local + remote); plan file was already archived to `docs/archive/plans/` at PR creation (defensive re-check via `git-post-merge-cleanup` skill if that step somehow got skipped). Checks if any unchecked tasks remain in the milestone spec.
4. If all milestone tasks done, git asks:
   > "All tasks complete. Ready to merge feat/\<milestone\> to main?"
5. You say yes → milestone PR created → you review + merge on GitHub → `PR merged` to `@hosea` → done.

---

## Flow at a glance

```
/fire_keeper
  → fire_keeper: @hosea creates feat/<slug> off main
  → @armin thinks (asks when ambiguous), writes+commits+pushes spec itself
  ← [YOU: approve spec]
  → @sokka writes+commits+pushes plan files itself, each flagged Test scope
  ← [YOU: approve plans]

for each task:
  /erwin
    → @hosea sets up task/<slug> (create or resume off latest feat branch;
                  lingering uncommitted work → stops and asks first)
    → @arthur confirms branch, implements, ticks plan checkboxes live,
                  commits + pushes directly via caveman-commit skill,
                  wip-checkpoints on context cutoff (auto-resumed)
    ↺ @levi (Captain Levi) until LGTM — no cycle cap. Every cycle:
                  lint/format, new compiler warnings, CVEs, DRY, 75%
                  business-logic coverage, plus stack checks. Commander
                  watches for STUCK (repeated finding / no-progress diff)
                  and DEAD (agent call errors/empty) → stops + reports;
                  soft checkpoint every 10 cycles if still finding new things
    → @iroh: update docs + mark spec task done + lessons learned (no archive yet)
  ← [YOU: E2E gate — smoke test, give findings or say "ready"]
      any finding → switch to @tarnished yourself (commander can't
                    dispatch it — no primary-to-primary calls), it fixes
                    SMALL directly, escalates COMPLEX to a new plan, parks
                    SCOPE CREEP in backlog.md → you resume the gate
    → @iroh rechecks for drift + archives plan (always) + spec/matrix
                  (if milestone complete) — single commit, single place
    → @hosea creates PR (Plan: + Spec: refs in body); archive step here is
                  a defensive no-op, docs already did it
  ← [YOU: merge PR on GitHub]
  → @hosea "PR merged" → cleanup
  ⚠ broke badly? @hosea "drop this branch" → rerun /erwin, fresh start

when all tasks done:
  → @hosea creates milestone PR
  ← [YOU: merge milestone to main]
  → @hosea "PR merged" → spec fully checked, branch cleaned
```

---

## Edge cases

**Small bugfix — skip Fire Keeper entirely:**
```
/tarnished
The login form crashes when email is empty. Write a fix plan.
```
Goes through `@tarnished`, not raw `/sokka` — architect is a subagent and can't create the branch or write the plan itself once it's done thinking. Tarnished (primary) calls `@sokka` for the plan content, creates the branch via `@hosea` if you're not already on one, then writes it via `@iroh`. Then run `/erwin` with the plan path.

**Trivial one-liner — skip both:**
```
/tarnished
Fix the typo in the error message on line 42 of auth.ts
```
Tarnished triages it as SMALL and implements directly.

**Reviewer feedback is wrong:**
Commander passes findings to developer which uses `receiving-code-review` — evaluates critically, pushes back on incorrect findings rather than blindly implementing.

**A small related idea pops up while `@arthur` is mid-plan:**
Developer can append it as a new checkbox on the *same* plan file, same branch, if it's tightly scoped — same file(s) already being touched, no new external surface or architectural decision, finishable in-session (see "Small related idea discovered mid-implementation" in `agents/arthur.md`). Anything bigger or unrelated still goes to `docs/backlog.md`, same as `@tarnished`'s SCOPE CREEP path. This exists specifically so a real related improvement doesn't force a whole new plan+branch cycle for something that would've been one extra checkbox.

**Standalone brainstorm (exploration only, not committing to implementation):**
```
/armin
I'm thinking about switching from REST to tRPC. What are the tradeoffs for this project?
```

**Milestone QA / detective mode (all tasks done, not ready to ship yet):**

When git asks "all tasks complete, ready to merge milestone to main?" — say `not yet`. You're now on `feat/<milestone>`. Do your QA pass and fix what you find:

| What you found | Who |
|----------------|-----|
| Trivial (typo, 1-2 lines) | `/tarnished` — commits directly to milestone branch |
| Multi-step bug or enhancement | `/tarnished` (mediates `@sokka` quick plan — you're already on `feat/<milestone>` so no new branch, architect writes its own plan file directly) → `/erwin` |
| Several things at once | `/fire_keeper` — groups them into tasks, runs commander per task |

When satisfied, ship the milestone:
```
@hosea
Submit PR feat/<milestone> to main
```

---

## Known gaps & hardening (2026-08-08 pass)

Real issues found in practice — a manual Claude second-pass after reviewer LGTM kept catching things reviewer should have caught itself. Fixed in `agents/levi.md`, documented here so the "why" doesn't get lost:

1. **Type errors slipping past LGTM.** The old "new compiler/typecheck warnings" check only diffed *warnings* between parent and current branch tip — it never ran an absolute build/typecheck on its own. A type hole that didn't happen to trigger a *new* warning (e.g. extending an already-loose generic, or a stack with no dedicated verification skill) sailed through. Fixed: reviewer now runs a full build/typecheck on the current branch tip and treats **any error as always a finding**, never "pre-existing debt" — only warnings get the pre-existing exemption.
2. **Missing business-logic unit tests, silently.** The 75% coverage rule existed, but it only had a path to an actual number through `dotnet-verification`/`nuxt-verification`/`python-verification`. A plain Node/TS backend, a Go service, anything outside those three stacks had **no skill that reports coverage at all** — the rule was unenforceable by construction for those stacks. Fixed: reviewer now runs the language's native tool directly (`tsc --noEmit` + `vitest`/`jest --coverage`, `go test -cover`, `cargo tarpaulin`, etc.) when no stack skill triggers. "No coverage check ran" is no longer a silently acceptable outcome — it's either a real number or an explicit "not measurable" finding.
3. **E2E matrix entries for untestable infrastructure.** Reviewer wrote matrix entries for whatever `**Test scope:** e2e` said, without checking whether the task was actually reachable by a real user/client. A migration or background-job task mislabeled `e2e` by architect got a matrix entry nobody could actually walk through by hand. Fixed: reviewer now sanity-checks reachability before writing anything — genuinely infra-only work gets flagged back as a scope mismatch instead of a bogus matrix entry.

**Also real, not yet hardened — worth watching:** `dotnet-verification` only triggers on Domain-entity/`DbContext`/`IEntityTypeConfiguration` changes, so a .NET diff that's pure service/business logic with no EF touch point currently gets no stack-specific typecheck pass at all — it now falls through to the new generic build/typecheck step above, but hasn't been battle-tested the way the EF-triggered path has.

---

## Local model ops (ollama)

RTX 4090 (24GB VRAM) + 32GB system RAM rig. Ollama had zero tuning before 2026-08-08 — default `OLLAMA_NUM_PARALLEL`/`OLLAMA_MAX_LOADED_MODELS` reserve more memory than a single-user sequential agent loop needs, and KV cache runs full fp16 unless told otherwise. Editing `/etc/systemd/system/ollama.service.d/override.conf` needs `sudo` with an interactive password — blocked both by the permission classifier and by no cached credential/TTY when run from here. Run this yourself:

```bash
sudo tee /etc/systemd/system/ollama.service.d/override.conf > /dev/null <<'EOF'
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
Environment="OLLAMA_FLASH_ATTENTION=1"
Environment="OLLAMA_KV_CACHE_TYPE=q8_0"
Environment="OLLAMA_MAX_LOADED_MODELS=1"
Environment="OLLAMA_NUM_PARALLEL=1"
Environment="OLLAMA_KEEP_ALIVE=15m"
Environment="OLLAMA_CONTEXT_LENGTH=65536"
EOF
sudo systemctl daemon-reload
sudo systemctl restart ollama
```

What each does and why, for this specific rig/workflow:

| Setting | Value | Why |
|---|---|---|
| `OLLAMA_FLASH_ATTENTION` | `1` | Cuts attention-computation memory overhead — frees VRAM for context instead of scratch space. RTX 4090 supports it natively, no downside here. |
| `OLLAMA_KV_CACHE_TYPE` | `q8_0` | Quantizes the KV cache to 8-bit instead of fp16 — roughly halves per-token context memory for ~no measurable quality loss (q4_0 exists and is smaller, but the quality tradeoff is sharper — not worth it on a card with room to spare). Requires flash attention on, which is set above. |
| `OLLAMA_MAX_LOADED_MODELS` | `1` | Only one local model is ever actually in use at a time in the opencode flow — `git`/`developer`/`fire_keeper`/`tarnished` never run concurrently, commander calls them sequentially. Capping at 1 guarantees no two models fight over the same 24GB and forces clean eviction instead of an OOM crash. |
| `OLLAMA_NUM_PARALLEL` | `1` | Default reserves multiple parallel request slots (extra KV cache reservations) even for a single-user sequential workload — wasted VRAM for capacity nothing here uses. |
| `OLLAMA_KEEP_ALIVE` | `15m` | Default is 5m. A commander review loop can call `@arthur` back-to-back across several fix cycles within minutes — 15m avoids reload thrash mid-loop while still releasing VRAM back to the browser/services during idle stretches between tasks. |
| `OLLAMA_CONTEXT_LENGTH` | `65536` | **Load-bearing, added after a real incident (below) — do not omit.** Explicit context window, applies globally to whichever model is loaded. |

### Incident: `opencode.json`'s `limit.context` does nothing to ollama

The first tuning pass (above table minus the last row) shipped without `OLLAMA_CONTEXT_LENGTH`. Result: `developer` (on Devstral, then qwen3-coder) started dying mid-cycle — commander reported "claimed done, zero commits landed" across three consecutive calls. Root cause, confirmed from `journalctl -u ollama`:

```
msg="vram-based default context" total_vram="24.0 GiB" default_num_ctx=32768
...
msg="truncating input prompt" limit=32768 prompt=33856 keep=4 new=32768
```

**When `OLLAMA_CONTEXT_LENGTH` is unset, ollama 0.22.1 auto-computes `num_ctx` from available VRAM — 32768 for this card — completely independent of `opencode.json`'s per-model `limit.context` field.** That field is advisory to opencode's own token-budgeting only; it is never forwarded to ollama as `num_ctx`. Proof: qwen3-coder was registered with `limit.context: 65536` and still ran (and truncated) at 32768. A real request hit 33856 tokens (tool schemas + file contents + plan + history — not unusual for a `developer` call) and ollama silently truncated it to 32768, keeping only the first 4 tokens plus a sliding tail — almost certainly gutting the system prompt / tool-calling instructions sitting in the middle. The model then had no idea what it was supposed to do, "completed" nothing, and opencode saw an empty/unusable response.

**Fix:** the explicit `OLLAMA_CONTEXT_LENGTH=65536` row above. It overrides the auto-detection outright. At 65536, qwen3-coder's KV cache roughly doubles (~3.2GB on top of 17.1GB weights) — leaves ~3.5GB headroom on the 24GB card, still safe for browser/services alongside it. **If `journalctl -u ollama` shows `"truncating input prompt"` again, that's the exact signal to bump this value further** — each doubling costs roughly another ~1.6GB VRAM at qwen3-coder's size, less for lighter models. Do not diagnose a "bad model" or "broken config" without checking this log line first — it's the single most direct signal of this failure mode, and looked exactly like a flaky/dead agent from the commander side.

`opencode.json`'s per-model `limit.context` values are kept anyway — not decorative, they still shape how much history/context opencode itself packs into a request before it starts compacting — but they are a ceiling on opencode's side, not a floor or override on ollama's.

**If you want more VRAM headroom on `git`/`fire_keeper`/`tarnished`:** the `glm-4.7-flash:latest` tag pulled at 19GB — heavier than the smallest available quant. `ollama pull glm-4.7-flash:q4_K_M` gets a ~5GB version if you want more room to run other GPU work alongside it; re-tag the `model:` line in the three agent files + `opencode.json` if you switch.

---

## Security audit

On-demand, not part of the per-task pipeline — run it whenever, against any project:

```
/carter
Audit this app.
```

Read-only. Runs `dependency-vulnerability-scan` (CVE + staleness check across whatever package ecosystems are present) and `security-code-review` (injection, XSS, authz/IDOR, secrets, SSRF, deserialization, rate-limiting/DoS resilience, crypto, CSRF, file upload) — both skills are stack-agnostic, they detect what's actually in the repo rather than assuming a language. Writes a severity-ranked report to `docs/security/` (or `security-audit/` at repo root if the project has no `docs/`), with a `## Tasks` checklist — same milestone-detection shape any spec uses.

Hand-off depends on scope, printed at the end of the audit:
- **1-3 findings** → `@tarnished` with the findings pasted in; tarnished mediates `@sokka` (quick plan) + `@hosea` + `@iroh`.
- **4+ findings / multi-domain** → the report itself is spec-shaped. `@hosea` creates `feat/security-hardening-<date>`, then `@sokka` in Milestone mode reads the report directly (same as any spec with a `## Tasks` checklist) and splits it into one plan per finding. Run `/erwin` per plan from there.

`reviewer` also runs the two generalized skills below (`error-handling-consistency-check`, `hardcoded-endpoint-check`) conditionally on every normal task diff, not just during a dedicated audit — they catch narrower classes of the same bug families as they're introduced, rather than waiting for the next full audit to find them.

---

## Codebase exploration and debugging

Both on-demand, same shape as `@carter` — read-only or narrowly-scoped, not part of the per-task pipeline unless you route them there manually.

**Explore** — map unfamiliar terrain before touching it:
```
/strelok
Where does the invite-link flow validate expiry?
```
Strictly read-only, chat output by default. Useful before `/fire_keeper` on an unfamiliar codebase, or any time you need "where is X" answered without committing to a task yet.

**Debugger** — hunt one bug to its root cause and fix it:
```
/mikasa
Login silently fails for users with an apostrophe in their email. Find it.
```
Narrow scope — fixes the root cause only, no adjacent refactors. This is also where a STUCK `@erwin` review loop can go: if the same reviewer finding survives a fix cycle, erwin offers to dispatch `@mikasa` directly with the branch and finding — say "mikasa" to confirm (deliberately not automatic; a stuck loop can mean the plan itself is wrong, not just that the bug needs a specialist). Erwin resumes the review loop once mikasa reports the fix.

---

## Docs structure (fallback default)

`@iroh` checks the project's own `AGENTS.md`/`CLAUDE.md` and existing `docs/` layout first. The layout below is the default for new projects — `project-scaffolding` scaffolds it automatically via `@the_well`.

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

**Starting a new project?** Run `/the_well` first — it invokes the `project-scaffolding` skill, working through scope, architecture, data model, glossary, and functional-spec one gate at a time. Each doc is drafted inline, revised until approved, then committed. When `/the_well` finishes, `functional-spec.md` is your roadmap and `/fire_keeper` takes over for individual features, with a concrete Phase 1 `/fire_keeper` invocation handed to you directly (no re-typing what you just defined). `/fire_keeper` will hard-stop and redirect to `/the_well` if `functional-spec.md` is missing.

---

## Model setup — local + cloud

Mixed local/cloud since 2026-08-08. Strategy: MiniMax subscription is spent ONLY where model quality changes real outcomes (reviewer quality gate). Deterministic/gate-keeping roles (`git`, `fire_keeper`, `tarnished`) and implementation (`developer`) moved to local ollama on the RTX 4090 rig — they were burning MiniMax subscription quota for work that doesn't need a frontier-tier model, and the shared pool (5 agents deep before this change) was the real driver of hitting caps. `docs`/`architect`/`brainstorm`/`well`/`carter`/`explore` stay on cheap OpenRouter — deterministic writes and rare on-demand reasoning respectively, neither contributes to the MiniMax cap problem, no reason to move them.

| Agent | Model | Why |
|-------|-------|-----|
| sokka (architect) | `openrouter/deepseek/deepseek-v4-pro` | plan reasoning needs full strength — errors cascade into every downstream task. Can't write files or touch git even if it wanted to (subagent restriction) — its tokens go entirely to thinking, fire_keeper/tarnished handle the mechanics |
| armin (brainstorm) | `openrouter/z-ai/glm-5.2` | creative + 1M-context exploration, leads quality benchmarks among affordable options |
| iroh (docs) | `openrouter/deepseek/deepseek-v4-flash` | deterministic file writes (both content-dump write mode and diff-based update mode) — cheap, fast, low temp (0.3) |
| **developer** | `ollama/qwen3-coder:latest` | **local.** Devstral tried first (68% SWE-bench, purpose-built agentic model) but died mid-cycle repeatedly — root cause was the missing `OLLAMA_CONTEXT_LENGTH` incident below, not the model itself, but qwen3-coder has the longer local track record on this rig so it's the default while re-testing Devstral is optional. Was the single biggest MiniMax consumer before the local move — every commander review cycle re-invokes it |
| levi (reviewer) | `minimax-coding-plan/MiniMax-M3` | quality gate — best owned model catches more bugs per cycle. Stays cloud on purpose, this is exactly where README's own strategy says spend the subscription |
| **tarnished** (builder) | `ollama/glm-4.7-flash:latest` | **local.** Triage/small-fix work — MoE, fast, plenty of headroom left on the card |
| erwin (orchestrator) | `openrouter/deepseek/deepseek-v4-flash` | holds hard E2E gate — needs reliable instruction following; M2.5 skipped the gate in practice |
| **fire_keeper** (planner) | `ollama/glm-4.7-flash:latest` | **local.** Pure gate-keeping, no implementation reasoning needed |
| **git** | `ollama/glm-4.7-flash:latest` | **local.** Deterministic bash/PR mechanics — was drawing MiniMax quota for work with zero real judgment calls |
| well (init) | `openrouter/google/gemini-2.5-flash` | large-context Q&A synthesis across five gated docs |
| carter (security) | `openrouter/deepseek/deepseek-v4-pro` | same reasoning tier as architect — triaging exploitability and severity needs real judgment, not just pattern-matching; run rarely (on-demand), so cost matters less than getting it right |
| strelok (explore) | `openrouter/google/gemini-2.5-flash` | same large-context/cheap tier as well — reading a lot of code and reporting back doesn't need frontier reasoning, it needs context room |
| mikasa (debugger) | `minimax-coding-plan/MiniMax-M2.7` | same tier developer used to sit at — finding and fixing a root cause is real implementation work, not a gate-keeping pass. Kept cloud since it's on-demand only, not a per-cycle cost driver like developer was |
| gandalf (router) | `openrouter/deepseek/deepseek-v4-flash` | same tier as commander — classification/dispatch needs reliable judgment, not raw power, and it's a light per-call cost |
| opencode default | `openrouter/deepseek/deepseek-v4-pro` | general interactive sessions |

Registered but not wired to any agent by default — pulled locally, available for manual experimentation on `developer` or `@gandalf`: `devstral-small-2:latest` (15GB, dropped from `developer` after the context incident below, worth re-testing now that it's fixed), `gpt-oss:20b` (13GB), `gemma4:26b` (17GB), `gemma4:e4b` (9.6GB). Flip any agent's `model:` line to `ollama/<tag>` to try one.

> **Historical note:** `qwen3-coder:latest` was the original local developer model, dropped for cloud-only, briefly readded as an OpenRouter-hosted fallback, then reinstated as the local `developer` default on 2026-08-08 after Devstral (tried first in the same pass) hit the `OLLAMA_CONTEXT_LENGTH` incident documented under "Local model ops" below — `glm-4.7-flash` and `gpt-oss:20b` were also pulled in that pass and are available to swap in (see "Registered but not wired" below the table). `openai/gpt-5.5` was a previous reasoning-tier model no longer used. docs and git were both found drifted from their documented models/temps during a July 2026 audit — the pre-2026-08-08 table reflected that corrected state, since superseded by the local-model move above. Primary agents were renamed (init→well, planner→fire_keeper, orchestrator→commander, builder→tarnished) plus security→carter, explore→Strelok, debugger→Mikasa, and router→Gandalf added across two later passes — see "Agent names" at the top.

### Fallback models (manual)

opencode has no native model-fallback field (`AgentConfig.model` is a single string — confirmed against `https://opencode.ai/config.json` schema). Flip the affected agent's `model:` line by hand for either failure mode below. Fallbacks are picked cost-efficient-but-competent, not cheapest-possible — a fallback that quietly tanks review/implementation quality defeats the point of having one.

**Local ollama unavailable** (fresh machine with no models pulled yet, or GPU busy with something else) — these are the exact cloud models `developer`/`git`/`fire_keeper`/`tarnished` ran on before the 2026-08-08 local move, proven-good, not a new guess:

| Agent | Fallback | Notes |
|-------|----------|-------|
| arthur (developer) | `minimax-coding-plan/MiniMax-M2.7` | its pre-local model — same tier reviewer expects findings to be fixed at |
| git, fire_keeper | `minimax-coding-plan/MiniMax-M2.5` | deterministic/gate-keeping tier |
| tarnished | `minimax-coding-plan/MiniMax-M2.7` | matches developer's tier since it does the same class of work standalone |

**MiniMax subscription quota exhausted or MiniMax infra down** (affects `reviewer`, `debugger`, and any agent temporarily flipped back to MiniMax above):

| Tier | Model | Covers |
|------|-------|--------|
| 1 | `openrouter/minimax/minimax-m3` or `openrouter/minimax/minimax-m2.7` | Subscription quota exhausted — same model, billed through OpenRouter instead. Zero prompt-tuning drift. |
| 2 | `openrouter/deepseek/deepseek-v3` | MiniMax infra itself down — different provider, cheap, strong instruction-following. |

Revert to `minimax-coding-plan/MiniMax-M*` once quota/infra recovers — tiers above are paid-per-token, not subscription. Revert local agents to `ollama/*` once the GPU/models are available again — cloud fallback costs real money per call, local is free once pulled.

**Automatic fallback exists via community plugin, not installed here:** `opencode-fallback` (youngbinkim0/opencode-fallback) and `opencode-rate-limit-fallback` (liamvinberg/opencode-rate-limit-fallback) both add chain-on-failure switching since opencode core doesn't. Not added — third-party code with full session access is worth reading before trusting. Less urgent now that only `reviewer`/`debugger` still depend on MiniMax day-to-day.

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
    "superpowers@hosea+https://github.com/obra/superpowers.git",
    "opencode-vibeguard@hosea+https://github.com/inkdust2021/opencode-vibeguard",
    "opencode-dynamic-context-pruning@hosea+https://github.com/Opencode-DCP/opencode-dynamic-context-pruning",
    "opencode-shell-strategy@hosea+https://github.com/JRedeker/opencode-shell-strategy",
    "type-inject@hosea+https://github.com/nick-vi/type-inject",
    "opencode-notifier@hosea+https://github.com/mohak34/opencode-notifier"
  ],
  "agent": {
    "developer": { "steps": 30 }
  }
}
```

---

## Adding new agents, skills, or commands

Add files to `agents/`, `skills/`, or `commands/` and commit. Available on every machine using these dotfiles. New primary agents should follow the naming convention above — themed codename + `(functional name)` hint in the description; new subagents keep plain functional names.

## Platform constraints — corrected 2026-08-09

**Correction:** this section previously claimed primary agents can never dispatch other primary agents — that was wrong, an unverified assumption never actually checked against source. Verified 2026-08-09 against opencode's actual Task tool implementation (`anomalyco/opencode`, `packages/opencode/src/tool/task.ts`): **there is no mode-based filtering on the Task tool's target agent.** It looks up the requested agent by name, checks depth limits and permissions, and dispatches — a `mode: primary` agent is a perfectly valid target, same as a subagent. `gandalf` and `erwin` (in `agents/gandalf.md` and `agents/erwin.md`) now dispatch directly instead of printing a command and stopping. Kept as a documented fallback in both, since this wasn't battle-tested across every opencode version/config before shipping it here — if a direct dispatch ever errors or returns nothing usable, both agents fall back to the old print-and-manual-switch pattern rather than failing silently.

**Subagent-to-subagent dispatch is a separate, still-unverified question — not changed here.** Nothing in this pass confirmed or denied whether a `mode: subagent` agent can dispatch another subagent (the source check above only covered the primary-to-primary case, since that was the actual disputed claim). The existing subagent design — write/commit/push your own designated file directly instead of relaying through another agent — stays as-is regardless; it's a good pattern on its own merits, not just a workaround:

- `brainstorm`/`armin` and `architect`/`sokka` (both `mode: subagent`) Write, commit (`caveman-commit`), and push their own spec/plan file directly once handed a target path — no relay through `@iroh`. This changed from an earlier design where they returned content in chat for `@fire_keeper` to relay: that relay step was a real source of thinner, more compressed specs — being told "you're producing a draft for someone else to write" measurably encouraged the model to compress. Being told "you're writing the final file" doesn't.
- `developer`/`arthur` (also `mode: subagent`) commits and pushes directly too, using the `caveman-commit` skill to keep messages conventional.
- `reviewer`/`levi` (also `mode: subagent`) follows the same shape for exactly one file: it writes/extends the spec-level E2E matrix directly on an `e2e`-scoped task's LGTM, and commits/pushes it — everything else about its job stays read-only.
- Branch creation still routes through `fire_keeper`/`tarnished` calling `@hosea` rather than `brainstorm`/`architect` doing it themselves — not because it's blocked, but because those two are deliberately kept read-only-except-their-own-file; no reason to widen their blast radius just because the platform would allow it.
- `commander`/`erwin`'s STUCK-loop hand-off to `@mikasa` is a deliberate exception to "always dispatch directly": a stuck review loop can mean the plan itself is wrong, not just that the bug needs a specialist, so `erwin` reports and offers the dispatch rather than doing it unprompted. The E2E gate itself (smoke-test, "ready" or give feedback) is an intentional human checkpoint too, unrelated to any platform restriction — what changed is only the mechanics of what happens to your feedback once you give it.
- **opencode itself has no native timeout/recovery on a hung subagent call** (open upstream gap, confirmed via `anomalyco/opencode` issue tracker as of Aug 2026) — `commander`/`erwin`'s dead-agent detection can only react to a call that *returns* something (error or empty), not a true silent hang. The community plugin `Mte90/opencode-auto-resume` targets exactly this gap ("stops working if a model goes in timeout or there are errors") — worth evaluating as a session-level safety net underneath erwin's own logic, not installed here yet (same "read third-party session-access code before trusting" bar the `opencode-fallback` note above already applies).
