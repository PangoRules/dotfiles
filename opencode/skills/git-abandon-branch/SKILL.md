---
name: git-abandon-branch
description: Use to permanently delete a branch, local and remote, for a scrapped task or feature — or a whole milestone (feat branch + every task branch spawned from it) via cascade mode. Checks for and asks about any open PR before deleting a branch. Idempotent — reports already-gone instead of failing when a branch is missing on one or both sides.
---

Delete a branch for good. Never infer the branch name silently — confirm it if ambiguous. Never delete anything without the confirmations below — this is destructive and not easily undone.

## Single-branch mode

### Step 1 — Check for an open PR first

```bash
gh pr list --head <branch> --json url,state -q '.[] | select(.state=="OPEN") | .url'
```
Open PR found → ask: "This branch has an open PR: `<url>`. Close it too, or leave it?" Wait for the answer. "Close it" → `gh pr close <url>` before continuing. "Leave it" → continue; note in the final report that an open PR was left behind (GitHub may auto-close it on branch deletion depending on repo settings, but don't assume that silently).

### Step 2 — Remote

```bash
git ls-remote --heads origin <branch>
```
Exists → `git push origin --delete <branch>`. Already gone → skip, note it.

### Step 3 — Local

```bash
git branch --list <branch>
```
Exists → `git branch -D <branch>`. Already gone → skip, note it.

### Step 4 — Report

State what was actually deleted vs. already-gone on each side, and whether a PR was closed or left.

Project mode: leave any matching plan file untouched — rerunning branch setup against the same plan recreates the branch fresh off the latest parent.

## Cascade mode — abandon a whole milestone

Triggered when the caller names a milestone/feat branch and means the whole thing, not just itself — "scrap this feature," "drop the whole milestone," not just one task.

### Step 1 — Enumerate the full set

```bash
git branch -r --list 'origin/task/*'
```
Cross-reference against `docs/plans/*.md` files whose `**Parent branch:**` matches the milestone's `feat/<slug>` — those are the child task branches. Include the `feat/<slug>` branch itself.

### Step 2 — Confirm before touching anything

List every branch found and any open PRs on any of them (single-branch mode Step 1, run per branch). Present the full list and ask explicitly:
```
About to abandon <N> branches for milestone <slug>:
- feat/<slug>
- task/<slug>-1
- task/<slug>-2 (open PR: <url>)
...

Confirm — delete all of these (and close the PR above)? This cannot be undone.
```
Wait for explicit confirmation. Anything short of a clear yes → stop, change nothing.

### Step 3 — Execute

Confirmed → run single-branch mode's Step 1-3 for every branch in the list, feat branch last (so a mid-cascade failure leaves the milestone's own branch as the last thing standing, not orphaned task branches with no parent).

### Step 4 — Report

One summary: how many branches deleted, how many PRs closed, anything that was already gone. Leave the spec and any plan files untouched — same as single-branch mode, they're a permanent record regardless of what happened to the branches.
