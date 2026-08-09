---
name: git-post-merge-cleanup
description: Use after a PR is merged — handles plan/spec cleanup, branch deletion, remote-ref pruning, and milestone completion detection. Covers both milestone task branches and quick feature branches. Idempotent — already-deleted branches, already-archived plans, and already-marked checkboxes are skipped, not treated as failures.
---

The PR has been merged. Clean up the workspace now.

## Step 0 — Detect path and clean up plans

First, identify which path you're on:

```bash
git branch --show-current
```

### Path A — Milestone task branch (`task/<slug>`)

Current branch matches `task/*` pattern.

**0a. Find parent branch from merged PR:**
```bash
gh pr list --state merged --head $(git branch --show-current) --json baseRefName -q '.[0].baseRefName'
```
This returns the milestone branch (e.g. `feat/milestone2-1-frontend-improvements`). Store it — needed for Step 2.

**0b. Mark the task done in the spec:**

Find the spec file in `docs/specs/`. It matches the milestone slug from the parent branch name.
Find the checkbox line matching this task branch name. Change `- [ ]` to `- [x]`. Save. Already `- [x]` → skip, already done.
```bash
git checkout <parent-branch>
git pull origin <parent-branch>
git add docs/specs/<parent-spec-file>.md
git commit -m "docs: mark <task-slug> complete in spec"
git push
```

**0c. Archive the task plan file (defensive — normally already done at PR creation; only fires if that step somehow got skipped):**
```bash
if [ -f docs/plans/<task-plan-file>.md ]; then
  mkdir -p docs/archive/plans
  git mv docs/plans/<task-plan-file>.md docs/archive/plans/<task-plan-file>.md
  git commit -m "docs: archive completed task plan"
  git push
fi
```
Already archived (file not found) → skip silently, expected case. Never `rm` a plan file — it's a permanent record once archived, same as `docs/archive/specs/`.

**0d. Check if all tasks are done:**

Invoke the `milestone-completion-check` skill against `docs/specs/<parent-spec-file>.md`.
- Complete → print: `"All tasks done. Creating milestone PR."`
  Then invoke the `git-pr-create` skill: source `feat/<milestone-slug>`, target `main`. Never a local `git merge` — a PR is the only path to `main`.
- Tasks remain → stop here, report which ones (the skill names them).

---

### Path B — Milestone branch itself (`feat/<milestone-slug>`) merging to main

No plan file to delete. Spec is permanent — it lives on in main history.
Skip to Step 1 directly.

---

### Path C — Quick feature/fix branch (`feat/<slug>` or `fix/<slug>`)

Find and archive the matching plan file if one exists (defensive — normally already done at PR creation):
```bash
ls docs/plans/
mkdir -p docs/archive/plans
git mv docs/plans/<matching-plan-file>.md docs/archive/plans/<matching-plan-file>.md   # if exists
git commit -m "docs: archive completed plan for <slug>"
git push
```
No plan file exists (task was chat-only, or already archived) → skip, expected case.

---

## Step 1 — Confirm the PR is merged

```bash
gh pr view --json state -q .state
```
Expected: `MERGED`. If not merged, stop and report back.

## Step 2 — Switch to parent branch and pull

**Milestone task (`task/*`):** use the parent branch resolved in Step 0a.
```bash
git checkout <parent-branch>
git pull origin <parent-branch>
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
Already gone → skip, note it. Use `-D` only if the merge was a squash or rebase and you are certain it was merged.

## Step 4 — Delete the feature branch remotely

```bash
git ls-remote --heads origin <branch-name>   # if no output, already gone
git push origin --delete <branch-name>
```
Already gone (GitHub auto-deleted it, or a prior run already did this) → skip, note it.

## Step 5 — Prune and confirm clean state

```bash
git fetch --prune
git status
git log --oneline -3
git branch
```
Expected: on parent branch, feature branch gone, working tree clean, no stale remote-tracking refs.

## Done

One sentence: which branch was deleted, which branch you're now on.
