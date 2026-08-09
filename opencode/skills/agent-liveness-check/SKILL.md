---
name: agent-liveness-check
description: Use to classify a subagent dispatch result as DEAD, WIP, or OK (real-time mode), or to scan a branch's commit range for any wip: commits (history-scan mode, e.g. for a lessons-learned pass). Single definition of the wip: commit convention — previously checked independently in two places with no shared definition.
---

Two modes. Same convention (a commit subject prefixed `wip:` means the previous call got cut mid-step by context/performance limits), different questions.

## Real-time mode — is this dispatch result usable?

Given a task_result from a subagent call:

1. **Empty, errored, or otherwise unusable** (including a genuinely empty result) → **DEAD**. Report:
   ```
   <agent> died mid-cycle. No usable response.
   ```
   Caller's next move: snapshot git state (branch/status/last commit) and report to the user — do not retry automatically. "Dead" means this loop stops calling the agent; there's no separate process to kill.

2. **Usable, and the branch's latest commit subject starts with `wip:`** → **WIP**. Report the wip commit's subject — this is the resume point, not a failure. Caller's next move: re-invoke the same agent with "resume from wip commit" framing, naming what the subject says was left unfinished.

3. **Usable, latest commit is not `wip:`-prefixed** → **OK**. Nothing further — proceed with the normal flow.

Check order matters: DEAD is about the call itself (did anything usable come back), WIP is about repo state (what's the latest commit) — always check DEAD first, since a dead call has no repo state worth trusting yet either.

## History-scan mode — were there any wip: commits on this branch, ever?

Given a commit range (e.g. `origin/<parent-branch>..<branch>`):

```bash
git log <range> --oneline --grep '^wip:'
```

Non-empty → each match is a signal that context overflow happened mid-task at some point on this branch, even if the final state is clean. Report the list — a caller doing a retrospective (lessons-learned, post-mortem) treats each one as "this step needed a resume, worth noting if it's a pattern," not as a current problem to fix.

Empty → report "No wip: commits on this branch" — nothing to note.

## Idempotent by nature

Both modes are read-only — safe to call repeatedly, always reflects current state.
