---
name: model-preflight
description: Use at the start of a planning/dev session, or when a local-model agent (arthur/hosea/fire_keeper/tarnished/iroh) returns an empty or suspiciously thin response — verifies ollama is reachable and its context window is configured correctly before assuming an agent died.
---

An unset or too-small `OLLAMA_CONTEXT_LENGTH` makes ollama silently truncate the prompt (system prompt + tool schemas + history get cut, keeping only a head+tail sliver) instead of erroring — the model then "completes" with nothing usable, and it looks exactly like a dead agent. This already happened once (see dotfiles opencode `README.md`, "Incident: `opencode.json`'s `limit.context` does nothing to ollama"). Check this before treating a thin response as a dead-agent case.

## Step 1 — Ollama reachable

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:11434/api/version
```
Expected: `200`. Non-200 or connection refused → ollama isn't running, not a model problem. Start it (`systemctl status ollama` / `ollama serve`) before continuing.

## Step 2 — Models actually pulled

```bash
ollama list
```
Confirm every model referenced in `opencode.json`'s `agent.*.model` / individual `agents/*.md` frontmatter is present. Missing → `ollama pull <tag>` before dispatching to that agent.

## Step 3 — Context truncation check

```bash
journalctl -u ollama --since "-1 hour" | grep -i "truncating input prompt"
```
Any match → context window is too small for what's actually being sent. Confirm the override is in place:
```bash
systemctl cat ollama | grep OLLAMA_CONTEXT_LENGTH
```
Missing entirely, or present but the truncation log still fires → bump the value (see dotfiles opencode `README.md`'s "Local model ops" section for the full override block and sizing guidance — each doubling costs roughly another ~1.6GB VRAM at a 30B-class model's size).

## When to run

- Once per planning/dev session start (fire_keeper's Step 0), cheap and idempotent.
- Diagnostically, the moment any local-model agent (one running on `ollama/*`) returns empty or clearly incomplete — check this **before** concluding the agent is dead. A real dead-agent case (call errors or truly empty) still gets reported as dead per the caller's own liveness check; this just rules out the "silently truncated, not actually dead" cause first.
