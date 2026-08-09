---
name: git-abandon-branch
description: Use to permanently delete a branch, local and remote, for a scrapped task or feature. Idempotent — reports already-gone instead of failing when a branch is missing on one or both sides.
---

Delete a branch for good. Never infer the branch name silently — confirm it if ambiguous.

## Step 1 — Remote

```bash
git ls-remote --heads origin <branch>
```
Exists → `git push origin --delete <branch>`. Already gone → skip, note it.

## Step 2 — Local

```bash
git branch --list <branch>
```
Exists → `git branch -D <branch>`. Already gone → skip, note it.

## Step 3 — Report

State what was actually deleted vs. already-gone on each side.

Project mode: leave any matching plan file untouched — rerunning branch setup against the same plan recreates the branch fresh off the latest parent.
