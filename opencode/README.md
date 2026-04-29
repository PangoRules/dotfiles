# opencode config

Global opencode configuration, agents, skills, and commands — tracked in dotfiles so any machine gets the same setup.

## What's here

| Path | Purpose |
|------|---------|
| `opencode.json` | Base config: default model, Ollama provider + available models |
| `agents/brainstorm.md` | Explores approaches, writes design spec |
| `agents/architect.md` | Reads spec, writes step-by-step implementation plan |
| `agents/developer.md` | qwen3-coder (local) — executes plans, commits + pushes incrementally |
| `agents/reviewer.md` | glm-4.7-flash (local) — reviews diffs against plan, finds bugs |
| `agents/docs.md` | glm-4.7-flash (local) — updates project docs, commits to branch |
| `agents/git.md` | glm-4.7-flash (local) — creates PRs, runs post-merge cleanup |
| `agents/builder.md` | Active model — general-purpose, no agent restrictions |
| `skills/caveman` → `agents/skills/caveman` | Ultra-compressed responses — all agents run at ultra level |
| `skills/caveman-commit` → `agents/skills/caveman-commit` | Conventional commit messages — developer invokes before every commit |
| `skills/caveman-review` → `agents/skills/caveman-review` | One-line review findings — reviewer invokes per finding |
| `skills/caveman-compress` → `agents/skills/caveman-compress` | Compress .md files to caveman prose (`/caveman:compress <file>`) |
| `skills/caveman-help` → `agents/skills/caveman-help` | Quick-reference card for all caveman modes |
| `skills/graphify` → `agents/skills/graphify` | Knowledge graph — architect queries before planning; brainstorm on unfamiliar codebases |
| `skills/documentation-writer` → `agents/skills/documentation-writer` | Docs agent process — Diátaxis-guided writing |
| `skills/finishing-a-development-branch` → `agents/skills/finishing-a-development-branch` | Branch finalization options |
| `skills/post-merge-cleanup` | After PR merges: update spec, delete plan + branch |
| `skills/test-failure-diagnosis` | Diagnose test failures before investigating values |
| `skills/manual-validation-matrix` | Output a test matrix for manual validation |
| `commands/prompt.md` | `/prompt <text>` — optimizes a prompt using Claude best practices |

---

## Agent responsibilities

| Agent | Creates branches | Commits | Pushes | Creates PR | Cleanup |
|-------|-----------------|---------|--------|------------|---------|
| developer | Yes (task branches) | Yes | Yes (after each commit) | **No** | **No** |
| git | No | No | Yes (PR branch) | **Yes** | **Yes** |
| reviewer | No | No | No | No | No |
| docs | No | Yes (docs only) | No | No | No |

**Main is read-only.** No agent merges to main directly. Only PRs merge to main.

---

## The full flow

### Phase 1 — Create the spec

**Who:** `brainstorm`
**What:** Explores the problem, writes a design spec.
**Output:** `docs/superpowers/specs/YYYY-MM-DD-<slug>-design.md`
**You:** Read it. Approve an approach or ask for changes. This is your first checkpoint.

```
/brainstorm
I want to add ingredient search — users type a name and get matching
inventory items filtered by dietary restriction. What are my options?
```

```
/brainstorm
Milestone 2 is the frontend. Based on docs/01-Architecture.md and
docs/02-DataModel.md, design the component structure, routing, and state management.
```

> **Do NOT hand the spec to the reviewer.** The reviewer reviews code, not prose.
> You are the reviewer of the spec — read it, approve it, then move on.

---

### Phase 2 — Create the tasks

**Who:** `architect`
**What:** Reads the spec, writes a step-by-step implementation plan.
**Output:** `docs/superpowers/plans/YYYY-MM-DD-<task-slug>.md` (one file per task for milestones)
**You:** Read each plan. Approve or send back to architect. This is your second checkpoint.

```
/architect
Go with approach 2 from the spec. Turn this into an implementation plan.
```

For a milestone with multiple tasks:
```
/architect
Spec is at docs/superpowers/specs/2026-04-27-milestone-2-frontend-design.md.
Break it into individual task plans. One file per task.
```

> **Architect creates the branch.** If you're on main, architect creates `feat/<slug>` automatically.
> For milestone tasks, branches follow: `feat/<milestone-slug>/task-N-<slug>`

> **Do NOT hand the plan to the reviewer.** Plans are yours to approve, not the reviewer's job.

---

### Phase 3 — Get the tasks done

Repeat this cycle for each task:

#### Step 1 — Implement `/dev`
```
Work from docs/superpowers/plans/2026-04-27-task-04-dashboard.md
```
Developer branches off the milestone branch, implements step by step, commits and pushes after each meaningful unit. One sentence when done.

#### Step 2 — Review `/reviewer`
```
Review this branch against docs/superpowers/plans/2026-04-27-task-04-dashboard.md
```
Reviewer runs tests, reads the diff, returns numbered findings or "LGTM".

#### Step 3 — Fix (if needed) `/dev`
```
Fix the reviewer findings.
```
Developer evaluates feedback critically, fixes, verifies before signalling done.

#### Step 4 — Update docs `/docs`
```
Reviewer gave LGTM on this branch. Update docs.
```
Docs agent updates `03-RepoStructure.md`, `04-Roadmap.md`, and the milestone spec. Does NOT touch plan files.

#### Step 5 — Submit PR `/git`
```
Submit PR feat/milestone-2-frontend/task-04-dashboard to feat/milestone-2-frontend
```
Or just:
```
Submit PR
```
Git agent detects current branch and suggests source/target — you confirm before it proceeds.

#### Step 6 — Merge on GitHub
Review the PR yourself. Merge it.

#### Step 7 — Cleanup `/git`
```
PR merged
```
Git agent: pulls target branch, deletes task branch (local + remote), removes plan file, updates spec.
If all milestone tasks are now done, asks:
> "All tasks complete. Ready to merge feat/milestone-2-frontend to main?"

You say yes → milestone PR created. You say no → stops.

---

## Flow at a glance

```
brainstorm → [you approve spec]
    → architect → [you approve plan(s)]
        → for each task:
            dev → reviewer → [fix if needed] → docs → git (PR) → [merge] → git (cleanup)
        → git asks: merge milestone to main?
```

---

## Edge cases

**Small task / bugfix — skip brainstorm:**
```
/architect
The login form crashes when email is empty. Write a fix plan.
```
Architect reads the relevant files, writes a concise plan. For trivial fixes, plan may be chat-only (no file).

**Reviewer finds nothing:**
Skip the fix step. Go straight to docs:
```
/docs
Reviewer gave LGTM on this branch. Update docs.
```

**Reviewer feedback is wrong:**
Developer uses `receiving-code-review` which evaluates findings critically. It will push back on incorrect or unnecessary feedback rather than blindly implementing it.

**Large milestone with parallel tasks:**
When architect flags steps as independent, developer invokes `subagent-driven-development` to run them concurrently.

---

## Docs structure (all projects)

```
docs/
├── 00-Overview.md        — project purpose, goals, non-goals
├── 01-Architecture.md    — system design, layers, key boundaries
├── 02-DataModel.md       — entity definitions, relationships
├── 03-RepoStructure.md   — folder layout, entry points, API reference
├── 04-Setup.md           — local dev setup, env vars, prerequisites
├── 04-Roadmap.md         — milestones, current state, what's next
└── decisions/            — one ADR per architectural decision
```

Specs and plans live in `docs/superpowers/` — managed by the agent flow, deleted after merge.

---

## Local model requirements

```bash
ollama pull qwen3-coder:latest   # developer + builder default
ollama pull glm-4.7-flash        # reviewer + docs + git
```

Optional upgrade for developer:
```bash
ollama pull qwen3.6:27b          # better coding, fits in 24GB VRAM
```

On a machine without Ollama, agents with `model: ollama/...` will error.
Fix: replace with a cloud model ID or comment out the `model:` line to use the opencode default.

---

## Per-machine setup

1. Run `bash ~/dotfiles/bootstrap.sh`
2. Pull required Ollama models (see above)
3. Set API keys for cloud agents via `/connect` inside opencode or in your environment

### Current provider config

```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "ollama/qwen3-coder:latest",
  "plugin": ["superpowers@git+https://github.com/obra/superpowers.git"],
  "provider": {
    "ollama": {
      "name": "Ollama",
      "npm": "@ai-sdk/openai-compatible",
      "options": { "baseURL": "http://127.0.0.1:11434/v1" },
      "models": {
        "qwen3-coder:latest": { "name": "qwen3-coder:latest" },
        "glm-4.7-flash":      { "name": "glm-4.7-flash" },
        "qwen3.6:27b":        { "name": "qwen3.6:27b" }
      }
    }
  }
}
```

---

## Adding new agents, skills, or commands

Add files to `agents/`, `skills/`, or `commands/` and commit. Available on every machine using these dotfiles.
