---
name: post-merge-cleanup
description: Use after a PR is merged — handles plan/spec cleanup, branch deletion, and milestone completion detection. Covers both milestone task branches and quick feature branches.
---

The PR has been merged. Clean up the workspace now.

## Step 0 — Detect path and clean up plans

First, identify which path you're on:

```bash
git branch --show-current
ls docs/superpowers/plans/ 2>/dev/null
```

### Path A — Milestone task branch (`feat/<milestone>/task-N-<slug>`)

Find the matching task plan file in `docs/superpowers/plans/`. It will have a `**Parent spec:**` line.

**0a. Mark the task done in the spec:**
```bash
# Read the Parent spec: value from the task plan file
grep "Parent spec:" docs/superpowers/plans/<task-plan-file>.md
```
Open the spec file at `docs/superpowers/specs/<parent-spec-file>.md`.
Find the checkbox line matching this task. Change `- [ ]` to `- [x]`. Save.
```bash
git add docs/superpowers/specs/<parent-spec-file>.md
git commit -m "docs: mark task-N complete in <milestone-slug> spec"
git push
```

**0b. Delete the task plan file (if docs agent hasn't already):**
```bash
if [ -f docs/superpowers/plans/<task-plan-file>.md ]; then
  rm docs/superpowers/plans/<task-plan-file>.md
  git add docs/superpowers/plans/<task-plan-file>.md
  git commit -m "docs: remove completed task-N plan"
  git push
fi
```

**0c. Check if all tasks are done:**
```bash
grep "\- \[ \]" docs/superpowers/specs/<parent-spec-file>.md
```
- If output is empty → all tasks complete. Print: `"All tasks done. Creating milestone PR."`
  Then invoke `finishing-a-development-branch` to create PR: `feat/<milestone-slug>` → `main`.
- If output has remaining `[ ]` items → more tasks remain. Stop here.

---

### Path B — Milestone branch itself (`feat/<milestone-slug>`) merging to main

No plan file to delete. Spec is permanent — it lives on in main history.
Skip to Step 1 directly.

---

### Path C — Quick feature/fix branch (`feat/<slug>` or `fix/<slug>`)

Find and delete the matching plan file if one exists:
```bash
ls docs/superpowers/plans/
rm docs/superpowers/plans/<matching-plan-file>.md   # if exists
git add docs/superpowers/plans/
git commit -m "docs: remove completed plan for <slug>"
git push
```
If no plan file exists (task was chat-only), skip.

---

## Step 1 — Confirm the PR is merged

```bash
gh pr view --json state -q .state
```
Expected: `MERGED`. If not merged, stop and report back.

## Step 2 — Switch to parent branch and pull

**Milestone task:** parent is the milestone branch.
```bash
git checkout feat/<milestone-slug>
git pull origin feat/<milestone-slug>
```

**All other branches:** parent is `main`.
```bash
git checkout main
git pull origin main
```

## Step 3 — Delete the feature branch locally

```bash
git branch -d <branch-name>
```
Use `-D` only if the merge was a squash or rebase and you are certain it was merged.

## Step 4 — Delete the feature branch remotely

Skip if GitHub already deleted it automatically.
```bash
git ls-remote --heads origin <branch-name>   # if no output, already gone
git push origin --delete <branch-name>
```

## Step 5 — Confirm clean state

```bash
git status
git log --oneline -3
git branch
```
Expected: on parent branch, feature branch gone, working tree clean.

## Done

One sentence: which branch was deleted, which branch you're now on.
