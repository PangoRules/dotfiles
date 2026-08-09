---
name: roster-routing
description: Use whenever a request doesn't match the shape you're built for — a bug report, a new idea, a security concern, a cleanup request, anything off-script — to classify it against the full agent roster and dispatch directly to whichever one owns it. Single source of truth for "what goes where"; multiple primaries consult this instead of each keeping their own copy of the table (which drifts).
---

Classify the request, name the target and why in one line, dispatch directly via the Task tool. Don't do the specialist's job yourself — that's true for whichever agent invokes this skill, not just `@gandalf`.

## The roster

| Situation | Agent | Why |
|---|---|---|
| Brand new project, nothing scaffolded yet | `@the_well` | Defines scope/architecture/data model/glossary/functional-spec before anything's built |
| Have a functional spec, want to plan the next feature/phase | `@fire_keeper` | brainstorm → spec gate → architect → plan gate |
| Have an approved plan file, ready to build it | `@erwin` | Runs dev → review loop → docs → PR, autonomously to the E2E gate |
| Small, isolated task — bugfix, one-liner, quick question, or genuinely unsure | `@tarnished` | Triages itself: answers directly, implements small, or escalates to a plan |
| Adding a task to a milestone that's already in progress (some tasks done, feat branch active) | `@tarnished` | Reconciles the addition into the milestone's spec (`spec-task-append`) before planning it |
| Security or dependency audit | `@carter` | Read-only, severity-ranked report with remediation handoff |
| "Where is X" / need to understand unfamiliar code before deciding anything | `@strelok` | Read-only codebase mapping, no commitment to act |
| A specific bug that survived a normal fix cycle, or any bug you want hunted properly | `@mikasa` | Systematic root-cause hunt, narrow fix, no adjacent refactors |
| Abandon/scrap a branch, task, or whole milestone — cleanup, not implementation | `@hosea` | Asks for explicit confirmation before deleting anything, closes any open PR first |
| Resume something already started (a plan, a spec/plan gate, a milestone) | The same command that started it (`@erwin`/`@fire_keeper`/`@the_well`) with "resume" | Each already detects its own in-progress state |
| Revert a feature that already shipped to `main` | `@hosea` | `git-history-edit`'s revert operation, opened as a PR — never a direct push to `main` |
| "Where am I" / "what's the status" / "what's left" — no specific agent named | Handle inline, no dispatch | Invoke the `pipeline-status` skill yourself and report — this is a read of overall state, not a task any single agent owns |

## Rules

- Don't guess past genuine ambiguity — one targeted question beats a wrong dispatch that burns a full agent cycle.
- Say who you're sending it to and why, in one line, then dispatch directly via the Task tool — no relay through a third agent just to make the same call again.
- If the request is itself just a question about the system ("what does X agent do", "how does the review loop work") — answer directly, no dispatch needed.
- **A dispatch to `@mikasa` or `@tarnished`'s SMALL path is not done when the fix lands.** Neither of those routes goes through a plan file's normal Step 3/4 review loop, so nothing verifies the fix independently unless you make that happen — the fix author running their own tests is self-report, not verification. Whichever agent made that dispatch invokes the `post-fix-review` skill against the resulting branch before reporting anything as finished. This is already wired into `erwin.md` and `tarnished.md` directly; naming it here too so it can't quietly regress if either file changes.
- **If the dispatch call errors or returns nothing usable**, fall back to printing the exact command instead of silently failing:
  ```
  Direct dispatch to `@<agent>` didn't go through. Run this yourself:

  @<agent>
  <the request, verbatim>
  ```
  Treat this as the exception path, not the default — always attempt the direct call first.
