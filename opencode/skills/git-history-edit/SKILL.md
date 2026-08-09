---
name: git-history-edit
description: Use for tag, revert, cherry-pick, or amend — the git operations that touch published or shared history. Guardrails baked in — not a preference, matches standard git safety practice: amend only on unpushed commits, revert/cherry-pick never target main directly, no force-push without the literal words "force push" in the request. Idempotent — detects already-applied tags/reverts/cherry-picks and reports instead of duplicating.
---

Four operations, each touching history — none of them get to guess when in doubt. Stop and report on any conflict; never auto-resolve.

## Tag

```bash
git tag -l <name>
```
Exists → report it, stop. Don't reclobber an existing tag.

Not exists:
```bash
git tag -a <name> -m "<message>"   # annotated by default
# or: git tag <name>                # lightweight, only if the caller explicitly wants it
```
Push only if asked: `git push origin <name>`. Report tag created, and whether it was pushed.

## Revert

Refuse if the current branch is `main` — this operation only runs on feature/task branches, same "main is read-only" principle as everything else in this roster.

```bash
git log --grep "This reverts commit <sha>" --oneline
```
Already reverted → report it, stop.

```bash
git revert <sha>   # add --no-commit if the caller wants to batch multiple reverts
```
Conflict → stop, report it verbatim. Do not auto-resolve. Report the new revert commit's sha + subject.

## Cherry-pick

Refuse if the current branch is `main`.

```bash
git log --grep "cherry picked from commit <sha>" --oneline
```
Already applied → report it, stop.

```bash
git cherry-pick <sha>
```
Conflict → stop, report it verbatim. Do not auto-resolve. Report the new commit's sha.

## Amend

```bash
git log @{u}..HEAD --oneline
```
Target commit not in this list (i.e. already pushed) → refuse: "That commit's already pushed — amending would rewrite shared history. Use revert instead." Stop.

Unpushed:
```bash
git commit --amend -m "<new message>"   # or --no-edit to keep the existing message
```
Report the amended sha + subject.

## Force-push

Only reachable as a consequence of the operations above (e.g. amend already pushed once before, cherry-pick/revert rewriting a branch someone else pulled). Never run `git push --force` / `--force-with-lease` unless the caller's request contains the literal words "force push" — and even then, never target `main`.
