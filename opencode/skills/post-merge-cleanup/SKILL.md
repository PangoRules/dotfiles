---
name: post-merge-cleanup
description: Use after a PR is merged — switches to main, pulls latest, deletes the feature branch locally and remotely, and confirms the workspace is clean.
---

The PR has been merged. Clean up the workspace now.

## Steps

1. **Confirm the PR is merged** before doing anything destructive.
   ```bash
   gh pr view --json state -q .state
   ```
   Expected: `MERGED`. If not merged, stop and report back.

2. **Switch to main and pull**
   ```bash
   git checkout main
   git pull origin main
   ```

3. **Delete the feature branch locally**
   ```bash
   git branch -d <branch-name>
   ```
   Use `-D` only if the merge was a squash or rebase (no merge commit) and you are certain it was merged.

4. **Delete the feature branch remotely** — skip if GitHub already deleted it automatically.
   ```bash
   git push origin --delete <branch-name>
   ```
   Check first: `git ls-remote --heads origin <branch-name>` — if no output, already gone.

5. **Check for lingering files**
   ```bash
   git status
   ```
   Working tree must be clean. If not, investigate before touching anything.

6. **Confirm final state**
   ```bash
   git log --oneline -3
   git branch
   ```
   Expected: on `main`, feature branch gone, working tree clean.

## Done

One sentence: which branch was deleted and current HEAD commit.
