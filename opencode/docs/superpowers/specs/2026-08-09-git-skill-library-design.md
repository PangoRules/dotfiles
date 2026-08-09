# Git skill library for hosea — design

## Motivation

Hosea ("git" subagent) already owns branch creation, PR creation, post-merge cleanup, branch abandonment, and read-only git-state queries — but every one of those lives as inline prose inside `agents/hosea.md`, except `post-merge-cleanup`, the one skill that exists today. Two problems:

1. **Coverage gaps.** No task covers stash, tag, revert, cherry-pick, or amend. "Everything git entails" isn't true yet.
2. **Everything's welded to hosea's prompt.** A recent incident (see parent conversation) showed the cost: `caveman-commit` only drafts message text, but because that fact lived in a skill file nobody re-read mid-task, hosea's own prompt line ("invoke caveman-commit and commit them") quietly under-specified who actually runs `git commit`. Mechanics buried in agent prose are harder to audit, harder to reuse, and harder to keep idempotent than a skill with a single stated contract.

## Goals

- Hosea can perform the full range of everyday git operations, not just branch/PR/cleanup.
- Every mechanical git sequence lives in its own skill file: a single stated contract, testable in isolation.
- Each skill works standalone in *any* repo (generic mode) and additionally recognizes this roster's own conventions when they're present (project mode) — same "detect the convention, fall back generically" shape already used by `dependency-vulnerability-scan` and `error-handling-consistency-check`.
- Every skill is idempotent: re-running it against state it already produced reports the current state instead of erroring or duplicating work.
- `hosea.md` keeps only what's actually judgment or a hard safety rule (voice, confirmation gates, "never merge/rebase/reset," "never push main without confirm," lingering-work preflight) plus a dispatch table pointing at skills.

## Non-goals

- Not changing what hosea is *allowed* to do to `main` (still: never commit/push there without explicit confirmation) or the existing merge/rebase/reset ban.
- Not building a general-purpose git CLI wrapper for arbitrary future commands — scope is the operations named here.
- Not touching how other agents (`erwin`, `fire_keeper`, `tarnished`) address hosea; their calls stay natural-language triggers, same as today.

## Architecture

Eight skill files under `opencode/skills/`, each pure mechanics — no confirmation gates, no voice, no branch-naming judgment calls:

| Skill | Replaces | Status |
|---|---|---|
| `git-branch-setup` | hosea Tasks D + F | new (extracted) |
| `git-pr-create` | hosea Task A | new (extracted) |
| `git-commit` | hosea Task G | new (extracted) |
| `git-abandon-branch` | hosea Task C | new (extracted) |
| `git-state-query` | hosea Task E | new (extracted) |
| `git-post-merge-cleanup` | `skills/post-merge-cleanup` (rename) | renamed + extended |
| `git-stash` | — | net-new |
| `git-history-edit` | — | net-new (tag / revert / cherry-pick / amend) |

`hosea.md` keeps: the `## Voice` section, the hard rules block (merge/rebase/reset ban, main-push confirmation, lingering-uncommitted-work preflight), Branch Detection prompt shape, and a dispatch table: trigger phrase → skill → what to hand it (plan-file-path if hosea has one in hand, else bare branch names/commit shas). Skills assume the preflight already ran before they're invoked — they don't re-implement confirmation gates.

## Per-skill contracts

### git-branch-setup
- **Generic:** create or resume `<branch>` off `<base>`.
- **Project mode:** given a plan-file-path, read `**Branch:**` / `**Parent branch:**` from it instead of taking them as raw args.
- **Idempotent:** `git ls-remote --heads origin <branch>` first. Exists → checkout + pull, report "resumed." Not exists → create off latest base, push, report "created." Never errors on a second run.

### git-pr-create
- **Generic:** `gh pr create` from current branch to a named target, conventional title, plain body.
- **Project mode:** given a plan-file-path, pull `**Parent spec:**` and real commit log into the PR body (Plan:/Spec: refs + bullets from `git log`, never invented content).
- **Idempotent:** `gh pr list --head <branch> --json url` first. Open PR already exists → report its URL, don't create a duplicate.

### git-commit
- **Generic:** `git status`/`git diff` → draft message via `caveman-commit` skill (message text only) → `git add` → `git commit -m "<message>"` → report `Committed <sha>: <subject>`.
- **Idempotent:** nothing staged/unstaged → report "nothing to commit," not an error.
- Never surfaces the full diff or the skill's raw draft upstream as the deliverable — that was the exact bug that started this conversation.

### git-abandon-branch
- **Generic:** delete `<branch>` local + remote by name.
- **Project mode:** leave the matching plan file untouched if the branch name matches one (rerunning the same plan recreates the branch fresh).
- **Idempotent:** branch already gone locally and/or remotely → report gone, don't fail on the missing side.

### git-state-query
- **Generic:** run the exact named read-only git/gh command, return output verbatim (this is the one skill where verbatim IS the contract — a caller like `erwin` parses the raw output).
- **Hard boundary carried over from hosea.md:** git/gh plumbing only, never build/test/lint.
- **Idempotent by nature** (read-only).

### git-post-merge-cleanup (rename of `post-merge-cleanup`)
- Same Path A/B/C branch-type detection, spec-checkbox marking, plan archiving as today.
- **Addition:** `git fetch --prune` runs inside the skill itself (Step 5, alongside the existing clean-state check) — today this only happens in hosea.md's Task B wrapper *after* the skill returns, so a caller invoking the skill directly (outside hosea) would silently skip it. Folding it in makes the skill idempotent and complete standalone.
- **Idempotent:** already-deleted branch / already-archived plan / already-marked checkbox → skip that step, don't fail (existing behavior, kept).

### git-stash (new)
- **Generic:** stash / pop / list / drop, by name or index.
- **Idempotent:** nothing to stash → report clean. Pop with empty stash list → report nothing to pop, don't error.

### git-history-edit (new)
- **Generic:** tag (lightweight/annotated + push), revert, cherry-pick, amend.
- **Guardrails (matches the user's existing global git-safety protocol, not a new preference):**
  - Amend only if the target commit is unpushed (`git log @{u}..HEAD` includes it). Otherwise refuse, suggest `revert` instead.
  - Revert/cherry-pick never target `main` directly — only feature/task branches (same "main is read-only" principle as the rest of this roster).
  - No force-push, ever, unless the request contains the literal words "force push."
- **Idempotent:** tag already exists → report it, don't reclobber. Commit already reverted/cherry-picked onto this branch (detected via `git log --grep`) → report it, don't duplicate.

## Migration notes

Renaming `post-merge-cleanup` → `git-post-merge-cleanup` requires updating every reference to the old name: `agents/hosea.md`, `agents/armin.md`, `agents/iroh.md`, `README.md` (confirmed via grep — these are the only 4 files naming it besides the skill file itself).

`hosea.md`'s dispatch table replaces Tasks A/C/D/E/F/G's step-by-step bodies with one-line pointers to the corresponding skill; the hard-rule prose (Voice, lingering-work preflight, merge/rebase/reset ban) is untouched. Tasks B (now dispatches to `git-post-merge-cleanup`) keeps its own extra step of asking about milestone-PR readiness, since that's a judgment call, not mechanics.

## Validation approach

These are prompt/skill files, not code — "testing" means dry-running each skill's trigger phrase against hosea and confirming: (a) it picks the right skill, (b) the skill's generic-vs-project-mode detection matches which inputs were actually handed to it, (c) idempotency holds on a second run against unchanged state, (d) the guardrails in `git-history-edit` actually refuse the disallowed cases (amend-on-pushed-commit, revert/cherry-pick targeting main, force-push without the literal trigger phrase).
