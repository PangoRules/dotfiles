# OpenCode Agent Setup Design

**Date:** 2026-04-26
**Status:** Implemented

## Context

Rafael has opencode configured with Ollama as the local provider (qwen3-coder, qwen3:30b,
qwen3:14b, gemma4) plus OpenAI (GPT-5.x) and Google (Gemini 2.5) as cloud providers.
The superpowers plugin is installed and injects skill awareness into every agent automatically.

The goal was to build a full development pipeline that:
- Uses cloud models only where they genuinely outperform local (brainstorm step)
- Wires superpowers skills into each agent to enforce structured workflows
- Replaces the native `plan` and `build` agents in practice

## Canonical Flow

```
1. brainstorm   → GPT-5.3 Codex   → explore approaches      (brainstorming skill)
2. architect    → qwen3:30b        → write implementation plan (writing-plans skill)
3. caveman      → qwen3-coder      → execute plan
4. reviewer     → qwen3:14b        → review diff              (requesting-code-review skill)
5. caveman      → qwen3-coder      → fix findings + verify
6. docs         → Gemini 2.5 Flash → update docs, commit      (documentation-writer skill)
7. caveman      → qwen3-coder      → create PR                (finishing-a-development-branch skill)
```

## Agent Design

### brainstorm
- **Model:** `openai/gpt-5.3-codex`
- **Mode:** primary (needs file write for spec output)
- **Mandatory skills:** `brainstorming`
- **Conditional skills:** `frontend-design` (UI-heavy tasks)
- **Output:** design spec written to `docs/superpowers/specs/`

### architect
- **Model:** `ollama/qwen3:30b`
- **Mode:** primary (needs file write for plan output)
- **Mandatory skills:** `writing-plans`
- **Conditional skills:** `using-git-worktrees` (new features), `dispatching-parallel-agents` (parallel steps)
- **Output:** implementation plan file read by caveman

### caveman
- **Model:** `ollama/qwen3-coder:latest`
- **Temperature:** 0.2 (strict execution)
- **Mandatory skills:** `executing-plans`, `verification-before-completion`
- **Conditional skills:** `test-driven-development`, `systematic-debugging`,
  `receiving-code-review` (when fixing feedback), `subagent-driven-development` (large plans),
  `finishing-a-development-branch` (after LGTM)

### reviewer
- **Model:** `ollama/qwen3:14b`
- **Temperature:** 0.1 (analytical, focused)
- **Mandatory skills:** `requesting-code-review`
- **Output:** numbered list of findings or "LGTM"

### docs
- **Model:** `google/gemini-2.5-flash`
- **Mandatory skills:** `documentation-writer`
- **Output:** updated docs committed to current branch

### builder
- **Model:** none locked — uses active model
- **Mode:** primary
- **Skills:** picks contextually (`using-git-worktrees`, `frontend-design`, `find-skills`)

## Token Cost Profile

| Step | Model | Cost |
|---|---|---|
| brainstorm | GPT-5.3 Codex | Paid (cloud) |
| architect | qwen3:30b | Free (local) |
| caveman | qwen3-coder | Free (local) |
| reviewer | qwen3:14b | Free (local) |
| docs | Gemini 2.5 Flash | Free (free tier) |
| builder | active model | Depends |

Cloud tokens are spent only on brainstorm — the one step where GPT-5 has a clear
quality advantage for creative ideation and product thinking.

## Alternatives Considered

**Approach B — Compressed 4-agent:** Collapsed architect+reviewer into one `thinker`.
Rejected because qwen3:30b reviewing its own plans has a blind-spot problem.

**Approach C — All-local:** Big Pickle for brainstorm instead of GPT-5.
Rejected because the brainstorm step is where cloud quality matters most.
