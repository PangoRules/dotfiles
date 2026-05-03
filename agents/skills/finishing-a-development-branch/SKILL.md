---
name: finishing-a-development-branch
description: Use when completing implementation work and need to finalize changes by switching to base branch, pulling latest, and cleaning up feature branches
---

# Finishing a Development Branch

## Overview

Guide completion of development work by presenting clear options and handling chosen workflow for finalizing changes. ALWAYS ASK WHEN MAKING NON-REVERSIBLE CHANGES.

## When to Use

- After implementing features, fixes, tasks, etc in a development branch
- When ready to consolidate changes back to the base branch
- When need to clean up temporary feature branches
- After all tasks in a development workflow are complete
- When preparing for a pull request or merge

## Core Pattern

Verify tests → Present structured options → Execute choice → Clean up worktree

## Quick Reference

| Option | Merge | Push | PR | Cleanup Branch | Cleanup Worktree |
|--------|-------|------|----|----------------|------------------|
| 1. Merge locally | ✓ | - | - | ✓ (confirm) | ✓ |
| 2. Push + PR | - | ✓ | ✓ | - | ✓ |
| 3. Push/Sync | - | ✓ | - | - | - |

## Implementation

### Step 1: Verify Tests

Before presenting options, run project tests:

```bash
# Run project's test suite
npm test / cargo test / pytest / go test ./...
```

If tests fail, stop and report failures before proceeding. Do analize what are the tests suites to run depending on code testing, if unknown ask.

### Step 2: Determine Base Branch

Find the base branch this feature branch split from:

```bash
CURRENT=$(git branch --show-current)
if [[ "$CURRENT" == task/* ]]; then
  # task branches split from feat branches
  BASE=$(git for-each-ref --format='%(refname:short)' refs/heads/feat/ | \
    while read b; do git merge-base --is-ancestor "$b" HEAD 2>/dev/null && echo "$b" && break; done)
elif [[ "$CURRENT" == feat/* ]]; then
  BASE=main
else
  # fallback: use remote default or main
  BASE=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||' || echo main)
fi
BASE_COMMIT=$(git merge-base HEAD "$BASE")
```

### Step 3: Present Options

Smart default: `task/*` pre-selects 1, `feat/*` pre-selects 2.

```
Implementation complete. What would you like to do?

1. Merge to <base-branch>          [recommended for task/* branches]
2. Push and create PR              [recommended for feat/* branches]
3. Push/Sync (no PR)

Which option? (default: <1 or 2>)
```

### Step 4: Execute Choice

#### Option 1: Merge Locally

```bash
# Switch to base branch
git checkout <base-branch>

# Pull latest
git pull

# Merge feature branch
git merge <feature-branch>

# Verify tests on merged result
<test command>
```

If tests pass, ask before deleting branch:

```
Merge successful. Delete branch <feature-branch>? (y/N)
```

Only on confirmation:

```bash
git branch -d <feature-branch>
```

Then cleanup worktree.

#### Option 2: Push and Create PR

```bash
# Push branch
git push -u origin <feature-branch>

# Create PR
gh pr create --title "<title>" --body "$(cat <<'EOF'
## Summary
<2-3 bullets of what changed>

## Test Plan
- [ ] <verification steps>
EOF
)"
```

Then cleanup worktree.

#### Option 3: Push/Sync

```bash
# Push branch, no PR
git push -u origin <feature-branch>
```

Report: "Branch <name> pushed. No PR created."

Keep worktree. Branch stays active for continued work.

### Step 5: Cleanup Worktree

For Options 1 and 2 only:
```bash
git worktree list | grep $(git branch --show-current)
# If in worktree:
git worktree remove <worktree-path>
```

For Option 3: Keep worktree.

## Common Mistakes

**Skipping test verification**
- Problem: Merge broken code, create failing PR
- Fix: Always verify tests before offering options

**Open-ended questions**
- Problem: "What should I do next?" → ambiguous
- Fix: Present exactly 3 structured options with smart default

**Automatic worktree cleanup**
- Problem: Remove worktree when branch still active (Option 3)
- Fix: Only cleanup for Options 1 and 2

**Deleting branch without confirmation**
- Problem: Accidentally delete work
- Fix: Always ask before `git branch -d`, even after successful merge

## Red Flags

**Never:**
- Proceed with failing tests
- Merge without verifying tests on result
- Delete work without confirmation
- Force-push without explicit request

**Always:**
- Verify tests before offering options
- Present exactly 3 options with smart default
- Confirm before deleting any branch
- Clean up worktree for Options 1 & 2 only
