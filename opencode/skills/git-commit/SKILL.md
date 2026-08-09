---
name: git-commit
description: Use to stage and commit working changes with a Conventional Commits message. Drafts the message via the caveman-commit skill, then actually stages and commits it — caveman-commit only writes text, it never runs git itself. Idempotent — reports "nothing to commit" instead of erroring against a clean tree.
---

Stage and commit. The message draft is internal working material — never the deliverable.

## Step 1 — See what actually changed

```bash
git status --short
git diff
```
Nothing staged or unstaged → report `Nothing to commit.` Stop.

## Step 2 — Draft the message

Invoke the `caveman-commit` skill to draft the subject/body from the actual diff — never invent content. **It only writes text — it does not stage or commit anything.** Staging and committing are this skill's job, always.

## Step 3 — Stage and commit

```bash
git add <relevant paths>   # all changed paths unless the caller named specific ones
git commit -m "<message>"
```

## Step 4 — Report

One line: `Committed <short-sha>: <subject>.` That's the deliverable — not the drafted message, not the diff, not the full body. If the commit body carries something worth knowing (breaking change, migration note), name that it exists in a half-sentence — don't paste it. The caller can `git show <sha>` for the rest.
