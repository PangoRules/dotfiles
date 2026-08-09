---
name: git-stash
description: Use to stash, pop, list, or drop uncommitted working-tree changes. Idempotent — reports "nothing to stash"/"nothing to pop" instead of erroring against an empty stash.
---

Four operations. Never resolve a pop conflict automatically — stop and report it.

## Stash

```bash
git status --short
```
Nothing changed → report `Nothing to stash.` Stop.

Otherwise:
```bash
git stash push -u -m "<short label>"
```
`-u` includes untracked files. Label it so it's identifiable later. Report the stash ref (e.g. `stash@{0}`) and label.

## Pop

```bash
git stash list
```
Empty → report `Nothing to pop.` Stop.

Otherwise:
```bash
git stash pop [<stash-ref>]   # defaults to the most recent if not named
```
Conflict on pop → stop, report the conflict verbatim. Do not auto-resolve.

## List

```bash
git stash list
```
Report verbatim — it's already short.

## Drop

Confirm the ref if ambiguous (more than one stash and none named).
```bash
git stash drop <stash-ref>
```
Already gone → report gone, don't fail.
