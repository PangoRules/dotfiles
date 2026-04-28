---
name: finishing-a-development-branch
description: Use when completing implementation work and need to finalize changes by switching to base branch, pulling latest, and cleaning up feature branches
---

# Finishing a Development Branch

## Overview

Guide completion of development work by presenting clear options and handling chosen workflow for finalizing changes.

## When to Use

- After implementing features or fixes in a development branch
- When ready to consolidate changes back to the base branch
- When need to clean up temporary feature branches
- After all tasks in a development workflow are complete
- When preparing for a pull request or merge

## Core Pattern

Verify tests → Present structured options → Execute choice → Clean up worktree

## Quick Reference

| Option | Merge | Push | Keep Worktree | Cleanup Branch |
|--------|-------|------|---------------|----------------|
| 1. Merge locally | ✓ | - | - | ✓ |
| 2. Create PR | - | ✓ | ✓ | - |
| 3. Keep as-is | - | - | ✓ | - |
| 4. Discard | - | - | - | ✓ (force) |

## Implementation

### Step 1: Verify Tests

Before presenting options, run project tests:

```bash
# Run project's test suite
npm test / cargo test / pytest / go test ./...
```

If tests fail, stop and report failures before proceeding.

### Step 2: Determine Base Branch

Find the base branch this feature branch split from:

```bash
# Try common base branches
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

### Step 3: Present Options

Show exactly these 4 structured options:

```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
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

# If tests pass
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

#### Option 3: Keep As-Is

Report: "Keeping branch <name>. Worktree preserved at <path>."

Don't cleanup worktree.

#### Option 4: Discard

Confirm first:
```
This will permanently delete:
- Branch <name>
- All commits: <commit-list>
- Worktree at <path>

Type 'discard' to confirm.
```

After confirmation:
```bash
git checkout <base-branch>
git branch -D <feature-branch>
```

Then cleanup worktree.

### Step 5: Cleanup Worktree

For Options 1, 2, 4:
Check if in worktree:
```bash
git worktree list | grep $(git branch --show-current)
```

If yes:
```bash
git worktree remove <worktree-path>
```

For Option 3: Keep worktree.

## Common Mistakes

**Skipping test verification**
- Problem: Merge broken code, create failing PR
- Fix: Always verify tests before offering options

**Open-ended questions**
- Problem: "What should I do next?" → ambiguous
- Fix: Present exactly 4 structured options

**Automatic worktree cleanup**
- Problem: Remove worktree when might need it (Option 2, 3)
- Fix: Only cleanup for Options 1 and 4

**No confirmation for discard**
- Problem: Accidentally delete work
- Fix: Require typed "discard" confirmation

## Red Flags

**Never:**
- Proceed with failing tests
- Merge without verifying tests on result
- Delete work without confirmation
- Force-push without explicit request

**Always:**
- Verify tests before offering options
- Present exactly 4 options
- Get typed confirmation for Option 4
- Clean up worktree for Options 1 & 4 only