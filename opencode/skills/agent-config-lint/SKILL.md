---
name: agent-config-lint
description: Use after editing any file under agents/, skills/, opencode.json, or the README's routing tables — checks the roster for drift (dangling @mentions, skill invocations naming a skill that doesn't exist, an agent's stated hard rule contradicted by its opencode.json permission block, a primary agent whose file uses opencode's reserved built-in agent keys). Not part of any runtime dispatch — a maintenance check for whoever edits the roster.
---

Every "Known incidents" entry in `agents/erwin.md` is roster-config drift a human caught mid-session, not something the system caught itself: a reserved key (`explore`) silently shadowed, a `bash: ask` permission contradicting a "YOU DO NOT RUN SHELL COMMANDS" prose rule. This check exists to catch that class of bug before it ships, not after.

## Step 1 — Dangling references

```bash
grep -oE '@[a-z_]+' agents/*.md | grep -v '@erwin\|@fire_keeper\|@the_well\|@gandalf\|@armin\|@sokka\|@arthur\|@levi\|@iroh\|@hosea\|@carter\|@strelok\|@mikasa\|@tarnished'
```
Any hit is an `@mention` of an agent that doesn't exist in `agents/`. (Update the exclusion list in the command above whenever an agent is renamed or added — it's a roster snapshot, not a magic pattern.)

For skills:
```bash
for f in agents/*.md; do grep -oE '`[a-z-]+` skill' "$f"; done
```
Cross-check each name against `ls skills/` — a skill invocation naming something not present under `skills/` is a dangling reference.

## Step 2 — Permission/prose consistency

For every agent file with a hard rule like "YOU DO NOT RUN SHELL COMMANDS" / "STRICTLY READ-ONLY" / "cannot edit": open `opencode.json`'s `agent.<name>.permission` block and confirm the matching `bash`/`edit` key is actually `deny` (not `ask`, not absent — absent falls back to the top-level `allow` default, which contradicts a hard "never" rule stated in prose). A prose-only restriction with no matching permission block is not enforced, it's a suggestion the model can rationalize past under pressure.

## Step 3 — Reserved-key collision

Opencode reserves `plan`/`build`/`general`/`explore` as built-in agent keys (confirmed against `@opencode-ai/sdk`'s `AgentConfig` type, see `agents/erwin.md`'s "Known incidents" for the `explore`/`strelok` collision this already caused). Check no file under `agents/` uses one of those four as its filename/key unless `opencode.json` explicitly disables the built-in for that key (`"<key>": {"disable": true}`) as `strelok` does today.

## Step 4 — Report

List every hit from Steps 1-3, each with the file:line and what's wrong. No hits → say so plainly, don't pad with "looks good" filler.

## When to run

Manually, by whoever is editing `agents/*.md`, `skills/*/SKILL.md`, or `opencode.json` — not wired into any agent's runtime dispatch. Cheap enough to run after any roster edit, not just big ones.
