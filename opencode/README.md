# opencode config

Global opencode configuration, agents, and commands — tracked in dotfiles so any machine gets the same setup.

## What's here

| Path | Purpose |
|------|---------|
| `opencode.json` | Base config: schema + superpowers plugin |
| `agents/brainstorm.md` | GPT-5.3 Codex — explores approaches, writes design spec |
| `agents/architect.md` | qwen3:30b — writes implementation plan for caveman |
| `agents/caveman.md` | qwen3-coder — executes plans, fixes reviews, creates PRs |
| `agents/reviewer.md` | qwen3:14b — reviews diffs, finds bugs, no edits |
| `agents/docs.md` | Gemini 2.5 Flash — updates docs, commits to branch |
| `agents/builder.md` | Active model — general-purpose, no restrictions |
| `agents/prompt-optimizer.md` | Prompt optimizer agent — invoked via `/prompt` command |
| `commands/prompt.md` | `/prompt <text>` — optimizes a prompt using Claude's best practices |

## Development flow

```
┌─────────────┬──────────────────┬────────────────────────────────────────────┐
│ Agent       │ Model            │ Skill(s)                                   │
├─────────────┼──────────────────┼────────────────────────────────────────────┤
│ brainstorm  │ GPT-5.3 Codex    │ brainstorming (+frontend-design if UI)     │
│ architect   │ qwen3:30b        │ writing-plans (+using-git-worktrees)       │
│ caveman     │ qwen3-coder      │ executing-plans, verification-before-done  │
│ reviewer    │ qwen3:14b        │ requesting-code-review                     │
│ caveman     │ qwen3-coder      │ receiving-code-review, verification        │
│ docs        │ Gemini 2.5 Flash │ documentation-writer                       │
│ caveman     │ qwen3-coder      │ finishing-a-development-branch → PR        │
└─────────────┴──────────────────┴────────────────────────────────────────────┘
```

### Example: adding ingredient search to a project

**Step 1 — switch to `brainstorm`**
```
I want to add ingredient search. Users type a name, get matching
ingredients filtered by dietary restriction. What are my options?
```
→ Invokes `brainstorming` skill. Returns 2-3 approaches with trade-offs.
  Writes spec to `docs/superpowers/specs/YYYY-MM-DD-topic-design.md`. You pick one.

**Step 2 — switch to `architect`**
```
Go with approach 2 — client-side fuzzy search with a preloaded index.
Turn this into a step-by-step implementation plan.
```
→ Reads codebase, invokes `writing-plans`. Writes numbered plan file. No code written.

**Step 3 — switch to `caveman`**
```
Execute the plan above.
```
→ Invokes `executing-plans`. Implements exactly what the plan says. One sentence when done.

**Step 4 — switch to `reviewer`**
```
Review the changes against the plan.
```
→ Invokes `requesting-code-review`. Returns numbered findings or "LGTM".

**Step 5 — switch back to `caveman`** (if issues found)
```
Fix the reviewer findings.
```
→ Invokes `receiving-code-review` (evaluates feedback critically), fixes, then
  `verification-before-completion`.

**Step 6 — switch to `docs`**
```
Summarise what changed for the README and PR description.
```
→ Invokes `documentation-writer`. Updates docs, commits them to the branch.

**Step 7 — switch back to `caveman`**
```
Reviewer gave LGTM. Create the PR.
```
→ Invokes `finishing-a-development-branch`. Validates tests pass, creates PR via `gh`.

---

For quick/ad-hoc tasks that don't need the full flow, use `builder` — it picks
whatever model you have active and has no restrictions.

## Local model requirements

Agents `architect`, `caveman`, and `reviewer` require local Ollama models:

```
ollama pull qwen3:30b
ollama pull qwen3:14b
ollama pull qwen3-coder:latest
ollama pull gemma4:latest
```

On a machine without Ollama, these agents will show a model-not-found error when selected.
To fix: comment out the `model:` line in the agent frontmatter to fall back to the opencode
default, or replace it with a cloud model ID.

## Symlinks (managed by bootstrap.sh)

```
~/.config/opencode/opencode.json  →  ~/dotfiles/opencode/opencode.json
~/.config/opencode/agents         →  ~/dotfiles/opencode/agents/
~/.config/opencode/commands       →  ~/dotfiles/opencode/commands/
```

## Per-machine configuration

`opencode.json` only includes the superpowers plugin. You need to add your local provider and model after pulling on a new machine.

### Ollama (local)

Add to `~/.config/opencode/opencode.json` — but since that file is a symlink to dotfiles, create a local override instead by editing it directly OR add the provider config as a local layer. The simplest approach: temporarily unlink, edit, re-link.

Actually the easiest flow on a new machine:
1. Run `bash ~/dotfiles/bootstrap.sh` — symlinks are created
2. Open `~/dotfiles/opencode/opencode.json` and append your provider locally (don't commit it)
3. OR: break the symlink and keep a machine-local copy: `cp --remove-destination $(readlink ~/.config/opencode/opencode.json) ~/.config/opencode/opencode.json`

### Example provider blocks

**Ollama:**
```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "ollama/qwen3-coder:latest",
  "small_model": "ollama/gemma4:latest",
  "plugin": ["superpowers@git+https://github.com/obra/superpowers.git"],
  "provider": {
    "ollama": {
      "name": "Ollama",
      "npm": "@ai-sdk/openai-compatible",
      "options": { "baseURL": "http://127.0.0.1:11434/v1" },
      "models": {
        "gemma4:latest":       { "name": "gemma4:latest" },
        "qwen3-coder:latest":  { "name": "qwen3-coder:latest" }
      }
    }
  }
}
```

**Anthropic (cloud):**
```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "anthropic/claude-sonnet-4-5",
  "plugin": ["superpowers@git+https://github.com/obra/superpowers.git"]
}
```
Set `ANTHROPIC_API_KEY` in your environment or run `/connect` inside opencode.

## Adding new agents or commands

Add files to `agents/` or `commands/` in this repo and commit. They'll be available on every machine that uses these dotfiles.
