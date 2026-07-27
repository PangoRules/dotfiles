---
name: error-handling-consistency-check
description: Use during review of a diff touching business logic or API surfaces — detects the project's own error-handling convention (Result/Either type, thrown exceptions, or Go-style multi-return) and flags places that break it, plus universally-bad patterns like swallowed errors regardless of convention.
---

Error-handling review, generalized across whatever convention a project has actually chosen. Different codebases legitimately choose different conventions (exceptions vs `Result<T,Error>` vs Go's `(val, err)`) — this skill doesn't prefer one, it enforces whichever one the project already committed to, plus a small set of patterns that are bad under any convention.

## Step 1 — Detect the project's own convention

Check `CLAUDE.md`/`AGENTS.md` first — many projects state this explicitly ("expected failures return `Result<T, Error>`, exceptions are for the unexpected"). If undocumented, infer from majority pattern in the layer you're reviewing:
```bash
grep -rn "Result<\|Either<\|throw new\|raise \|return.*, err\b" <changed files>
```
Whichever shape dominates the existing surrounding code (not just the diff) is the convention in force for that layer — a diff introducing a different shape in the same layer is the finding, not a matter of taste.

## Step 2 — Convention-specific checks

**If the project uses a Result/Either return type for expected failures:**
- A function whose signature returns `Result<T, Error>` (or equivalent) but also `throw`s for a condition that's clearly an expected failure path (validation failure, not-found, conflict) — that's bypassing the type system's own guarantee. Callers checking `.isError`/`.match()` won't see it; it becomes an unhandled exception instead.
- A caller that receives a `Result`/`Either` and doesn't check it before using the value (unwraps without checking `isSuccess`/pattern-matching) — same failure class as an unchecked null.

**If the project uses thrown exceptions as the primary mechanism:**
- A catch block that's empty, or that logs and continues without either handling the condition or re-throwing with context — silent failure either way.
- A caught exception whose type is `Exception`/`Error` (catch-all) in a place with more than one distinct expected failure mode — masks which failure actually happened, makes the catch block impossible to reason about later.

**If the project uses Go-style multi-return `(value, err)`:**
- An `err` that's checked (`if err != nil`) but then only logged, not returned/handled — the caller up the stack doesn't know it happened.
- An `err` return value ignored entirely (`_ = doThing()` or the equivalent) on a call that can meaningfully fail.

## Step 3 — Universal bad patterns (flag regardless of convention)

- Empty catch/except blocks: `catch {}`, `catch (Exception e) {}`, `except: pass`, `except Exception: pass`.
- A caught error that's swallowed with no log, no rethrow, no user-facing signal — the operation silently no-ops instead of failing visibly.
- Stack traces or raw internal error messages returned directly to a client/API response instead of a sanitized message — an information-disclosure issue as much as an error-handling one, worth cross-referencing with a security review if this skill is run standalone.
- Inconsistent handling of the same failure condition in sibling call sites (one throws, one returns null, one logs and continues) for what is semantically the same error — this is what actually causes production incidents: callers can't build a reliable mental model of what happens when this fails.

## Output shape

```markdown
### [finding] <file:line>
- **Convention in force:** <what the surrounding code/docs establish>
- **Deviation:** what this code does instead
- **Risk:** what happens when this failure path is hit — silent no-op, unhandled crash, leaked internal detail, inconsistent caller behavior
```

Not a style nit — every finding here should describe a concrete failure mode a user or caller would actually hit, not just "doesn't match convention."
