---
name: git-state-query
description: Use for read-only git/gh state lookups on behalf of a caller that can't or shouldn't run bash itself — last commit, diff between shas, PR URL/comments, commits-ahead counts. Returns raw output verbatim; this is the one git skill where verbatim IS the contract, since callers parse it programmatically.
---

Read-only. No commit, no push, no branch mutation — just report what's on disk.

## Step 1 — Switch branch if named

If a branch is named and isn't the current one, check it out and pull it. Caller is expected to have already handled any lingering-uncommitted-work check before invoking this — don't silently switch over someone's work.

## Step 2 — Run the requested command

Run exactly the git/gh command the query implies. Common ones:
- Last commit subject: `git log -1 --format=%s`
- Full diagnostic snapshot: `git status --short` + `git log -1 --format='%H %s'`
- Commits ahead of parent: `git log origin/<parent-branch>..<branch> --oneline`
- Diff between two commits: `git diff <sha1> <sha2>`
- PR URL for a branch: `gh pr list --head <branch> --json url --jq '.[0].url'`
- PR review comments: `gh pr view <pr-url> --comments`

## Step 3 — Return verbatim

Return the raw command output verbatim — the caller parses this, so the data itself stays exact. A short sentence of framing around it is fine; the output inside is never paraphrased or summarized away.
