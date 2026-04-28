# opencode config

Global opencode configuration, agents, skills, and commands — tracked in dotfiles so any machine gets the same setup.

## What's here

| Path | Purpose |
|------|---------|
| `opencode.json` | Base config: schema, default model, Ollama provider + models |
| `agents/brainstorm.md` | GPT-5.3 Codex — explores approaches, writes design spec |
| `agents/architect.md` | MiniMax-M2.7 — writes implementation plan for developer |
| `agents/developer.md` | qwen3-coder (local) — executes plans, fixes reviews, creates PRs, cleans up |
| `agents/reviewer.md` | glm-4.7-flash (local) — reviews diffs, finds bugs, no edits |
| `agents/docs.md` | glm-4.7-flash (local) — updates docs, commits to branch |
| `agents/builder.md` | Active model — general-purpose, no agent restrictions |
| `skills/caveman/SKILL.md` | Cross-cutting: terse chat responses (~65% token reduction) |
| `skills/post-merge-cleanup/SKILL.md` | After PR merges: delete plan file, switch to main, pull, delete branch |
| `skills/test-failure-diagnosis/SKILL.md` | Diagnose test failures before investigating values |
| `commands/prompt.md` | `/prompt <text>` — optimizes a prompt using Claude best practices |

## Development flow

```
┌─────────────┬────────────────────┬────────────────────────────────────────────────────┐
│ Agent       │ Model              │ Skill(s) invoked                                   │
├─────────────┼────────────────────┼────────────────────────────────────────────────────┤
│ brainstorm  │ GPT-5.3 Codex      │ brainstorming (+frontend-design if UI work)        │
│ architect   │ MiniMax-M2.7       │ writing-plans (+using-git-worktrees for large feat)│
│ developer   │ qwen3-coder        │ executing-plans, tdd, verification-before-done     │
│ reviewer    │ glm-4.7-flash      │ requesting-code-review                             │
│ developer   │ qwen3-coder        │ receiving-code-review, verification-before-done    │
│ docs        │ glm-4.7-flash      │ documentation-writer                               │
│ docs        │ glm-4.7-flash      │ **CRITICAL: Do NOT invoke post-merge-cleanup or**
│ docs        │ glm-4.7-flash      │ **any skill that switches branches or merges.** 
│ docs        │ glm-4.7-flash      │ **Main is untouchable—only PRs merge to main.**    │
│ developer   │ qwen3-coder        │ finishing-a-development-branch → creates PR        │
│ developer   │ qwen3-coder        │ post-merge-cleanup → after PR is merged            │
└─────────────┴────────────────────┴────────────────────────────────────────────────────┘
```

---

## Example: adding ingredient search (single feature)

**Step 1 — switch to `brainstorm`**
```
I want to add ingredient search. Users type a name, get matching
ingredients filtered by dietary restriction. What are my options?
```
→ Invokes `brainstorming`. Returns 2-3 approaches with trade-offs.
  Writes spec to `docs/superpowers/specs/YYYY-MM-DD-ingredient-search-design.md`.
  You pick one.

**Step 2 — switch to `architect`**
```
Go with approach 2 — client-side fuzzy search with a preloaded index.
Turn this into a step-by-step implementation plan.
```
→ Checks current branch. If on main, creates `feat/ingredient-search` before writing anything.
  Invokes `writing-plans`. For a single task: outputs plan to chat only (no file).
  For a full feature: writes `docs/superpowers/plans/YYYY-MM-DD-ingredient-search.md`.
  No code written.

**Step 3 — switch to `developer`**
```
Execute the plan above.
```
→ Invokes `executing-plans`. If plan has parallel steps, invokes `subagent-driven-development`.
  Implements exactly what the plan says. One sentence when done.

**Step 4 — switch to `reviewer`**
```
Review the changes against the plan.
```
→ Runs tests first, then reads the diff. Invokes `requesting-code-review`.
  Returns numbered findings or "LGTM".

**Step 5 — switch back to `developer`** (if findings)
```
Fix the reviewer findings.
```
→ Invokes `receiving-code-review` (evaluates feedback critically, doesn't blindly implement).
  Fixes, then `verification-before-completion` before signalling done.

**Step 6 — switch to `docs`**
```
Summarise what changed. Update the relevant docs and commit.
```
→ Invokes `documentation-writer`. Knows the standard docs layout — updates the right
  existing file instead of creating a new one. Commits docs to the current branch.

**Step 7 — switch back to `developer`**
```
Reviewer gave LGTM. Create the PR.
```
→ Invokes `finishing-a-development-branch`. Validates tests pass, creates PR via `gh`.

**Step 8 — switch back to `developer`** (after PR is merged)
```
PR was merged. Clean up.
```
→ Invokes `post-merge-cleanup`. Deletes the plan file, switches to main, pulls,
  deletes the feature branch locally and remotely.

---

## Example: starting a full milestone (e.g. Milestone 2 — Frontend)

A milestone is multi-step work. Architect writes a feature plan file (not chat-only)
and flags independent steps for parallel execution.

**Step 1 — switch to `brainstorm`**
```
Milestone 2 is the Frontend. Based on docs/01-Architecture.md and
docs/02-DataModel.md, explore what the component structure, routing,
and state management should look like.
```
→ Invokes `brainstorming` + `frontend-design` (UI work detected automatically).
  Writes spec to `docs/superpowers/specs/YYYY-MM-DD-milestone-2-frontend-design.md`.

**Step 2 — switch to `architect`**
```
Go with approach 2. This is the full frontend milestone — write a feature plan.
Flag any steps that can run in parallel.
```
→ Creates `feat/milestone-2-frontend` if on main.
  Writes plan to `docs/superpowers/plans/YYYY-MM-DD-milestone-2-frontend.md`.
  Parallel steps are flagged for developer to use `subagent-driven-development`.

**Steps 3–8:** same as single-feature flow above.

---

## Edge cases

**Small task / bugfix — skip brainstorm:**
If the answer is obvious (fix a null check, rename a field, small config change),
go straight to `architect`. Architect outputs the plan to chat only — no file needed.
```
architect → "The login form crashes when email is empty. Fix it."
```
Architect reads the relevant file(s), writes a concise plan in chat, no branch needed
if you're already on a feature branch.

**Architect creates the branch:**
Architect always checks your current branch before writing the plan. If you're on
`main` or `master`, it creates `feat/<slug>` automatically before outputting anything.
You don't need to create the branch yourself.

**Reviewer finds nothing:**
If reviewer returns "LGTM", skip step 5 entirely. Go straight to docs (step 6).
```
developer → "Reviewer gave LGTM. Create the PR."
```

**Reviewer findings need discussion:**
Developer uses `receiving-code-review` which means it evaluates findings critically.
If a finding is wrong or debatable, developer will say so rather than blindly fixing it.
Trust this — it prevents unnecessary churn.

**Feature too large for one plan:**
Architect invokes `using-git-worktrees` for large features that need full isolation
from the current workspace. It creates an isolated worktree, then developer works there.

**Parallel plan steps:**
When architect flags steps as independent, developer invokes `subagent-driven-development`
to run them concurrently. Faster for milestones with many independent components
(e.g. multiple unrelated UI pages, separate API endpoints).

**Post-merge on a squash/rebase merge:**
`post-merge-cleanup` uses `git branch -d` (safe delete). If the PR was squash-merged,
the local branch won't show as merged — use `git branch -D` instead and confirm first
that `gh pr view --json state` returns `MERGED`.

---

## Docs structure (all projects)

Every project follows this layout. `docs` agent is aware of it and updates existing
files rather than creating new ones:

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

Write an ADR in `decisions/` when introducing a new architectural pattern,
replacing a system, or making a cross-cutting choice. Filename: `YYYY-MM-DD-<slug>.md`.
Specs and plans live in `docs/superpowers/` (managed by the agent flow, deleted on merge).

---

## Local model requirements

Both `developer` and `reviewer`/`docs` agents require local Ollama models:

```bash
ollama pull qwen3-coder:latest   # developer + builder default
ollama pull glm-4.7-flash        # reviewer + docs
```

On a machine without Ollama, agents with a `model: ollama/...` line will show a
model-not-found error. Fix: comment out the `model:` line in the agent frontmatter
to fall back to the opencode default, or replace with a cloud model ID.

---

## Per-machine configuration

`opencode.json` in dotfiles includes the full Ollama provider config. On a new machine:

1. Run `bash ~/dotfiles/bootstrap.sh` — symlinks are created
2. The active config at `~/.config/opencode/opencode.json` is **not** a symlink —
   it's a standalone file. Copy it from dotfiles after bootstrap:
   ```bash
   cp ~/dotfiles/opencode/opencode.json ~/.config/opencode/opencode.json
   ```
3. Pull the required Ollama models (see above)
4. Set API keys for cloud agents (`OPENAI_API_KEY`, MiniMax credentials) via `/connect`
   inside opencode or in your environment

### Global Safety Rules

- **Main branch is read-only** for all agents unless via PR
- **No auto-merging to main**—only PRs merge to main
- **No automatic branch switching** by documentation or any other agents outside of PR flow

### Current provider config (opencode.json)

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
        "glm-4.7-flash":      { "name": "glm-4.7-flash" }
      }
    }
  }
}
```

### Anthropic (cloud fallback)

```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "anthropic/claude-sonnet-4-6",
  "plugin": ["superpowers@git+https://github.com/obra/superpowers.git"]
}
```
Set `ANTHROPIC_API_KEY` in your environment or run `/connect` inside opencode.

---

## Adding new agents, skills, or commands

Add files to `agents/`, `skills/`, or `commands/` in this repo and commit.
They'll be available on every machine that uses these dotfiles.
