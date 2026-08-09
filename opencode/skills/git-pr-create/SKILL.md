---
name: git-pr-create
description: Use to open a PR from a source branch to a target branch. Pulls Plan:/Spec: refs and real commit history into the body when given a plan-file-path (project mode); takes bare branch names otherwise (generic mode). Idempotent — returns the existing open PR's URL instead of creating a duplicate.
---

Open a PR. Never merge, never rebase — divergence from target is a stop condition, not something this skill resolves.

## Step 1 — Resolve branches

From args, or a plan file's `**Branch:**`/`**Parent branch:**`.

## Step 2 — Idempotency check

```bash
gh pr list --head <source> --json url,state -q '.[] | select(.state=="OPEN") | .url'
```
Non-empty output → report that URL, stop. Do not create a duplicate PR.

## Step 3 — Confirm branch, commit state

Confirm you are on the source branch — `git checkout <source>` if not.

`git status` — unstaged or uncommitted changes → invoke the `git-commit` skill first. Never skip uncommitted work.

## Step 4 — Check divergence — do NOT merge

```bash
git fetch origin <target>
git log origin/<target>..<source> --oneline  # commits ahead
git log <source>..origin/<target> --oneline  # commits behind
```
Behind → stop, report. Tell the caller to rebase manually. Do not proceed.

## Step 5 — Commit history for the body

```bash
git log origin/<target>..<source> --oneline
```
Use actual commits only — never invent content.

## Step 6 — GitHub CLI auth

```bash
gh auth status
```
Not authenticated → stop, report. Do not proceed.

## Step 7 — Project mode only: defensive plan-archive fallback

Plan archiving is normally already done upstream by the time this runs. Defensive re-check:
```bash
git mv <plan-file-path> docs/archive/plans/<plan-filename> 2>/dev/null && git commit -m "docs: archive plan <plan-slug>" && git push || true
```
Already gone → expected, skip silently. Still there → this catches it as a safety net. Never `git rm` a plan — it's a permanent record once archived.

## Step 8 — Push and create

```bash
git push -u origin <source>
```

```bash
gh pr create --base <target> --head <source> \
  --title "<conventional title>" \
  --body "$(cat <<'EOF'
Plan: <plan-file-path>
Spec: docs/specs/<spec-file>

- <commit 1 from git log>
- <commit 2 from git log>
...
EOF
)"
```
- Title: short, conventional prefix (`feat:`, `fix:`, `docs:`, `chore:`).
- Body: plan + spec refs first (project mode only), then bullet points from actual commits. No invented content.
- Generic mode / no plan file: omit the Plan/Spec lines, bullets only.

## Step 9 — Output the PR URL. Stop.
