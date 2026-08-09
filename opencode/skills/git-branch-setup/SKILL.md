---
name: git-branch-setup
description: Use to create or resume a git branch off a base branch. Reads a plan file's **Branch:**/**Parent branch:** headers when given a plan-file-path (project mode); takes plain branch names directly otherwise (generic mode). Idempotent — resumes instead of failing if the branch already exists on remote.
---

Create or resume a branch. Caller is expected to have already handled any lingering-uncommitted-work check before invoking this — this skill assumes a clean tree to check out from.

## Step 1 — Resolve inputs

**Project mode:** given a plan-file-path, read it and extract:
- `**Branch:**` → target branch name
- `**Parent branch:**` → base branch to create from

**Generic mode:** given `<branch>` and `<base>` directly. If no base was named, default to `main`.

## Step 2 — Check remote

```bash
git fetch origin
git ls-remote --heads origin <branch>
```

## Step 3 — Exists → resume

```bash
git checkout <branch>
git pull origin <branch>
```
Report: `Resumed <branch>. On latest commit.`

## Step 4 — Does not exist → create fresh off latest base

```bash
git checkout <base>
git pull origin <base>
git checkout -b <branch>
git push -u origin <branch>
```
Report: `Created <branch> off latest <base>.`

## Step 5 — Stop

Do not write any spec/plan content — that's a docs job. Do not call a developer agent — the caller handles what comes next.
