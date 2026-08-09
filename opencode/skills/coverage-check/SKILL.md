---
name: coverage-check
description: Use to get a real business-logic coverage number for a diff when none of the dedicated stack-verification skills (dotnet-verification, nuxt-verification, python-verification) trigger — detects whichever native test/coverage tool the repo actually has (tsc+vitest/jest, go test -cover, cargo tarpaulin, etc.) and runs it. "No coverage check ran at all" is never an acceptable silent outcome; this skill's job is to make sure something always reports a number, or an explicit reason there isn't one.
---

Stack-agnostic, same detection-first shape as `dependency-vulnerability-scan`: figure out what's actually in the repo, run its own native tool, never assume a framework.

## Step 1 — Detect the stack

Check for, in order (first match wins — a repo with multiple should already have a dedicated stack-verification skill trigger instead of reaching this fallback):
- `package.json` with `typescript` + (`vitest` or `jest`) → Node/TS backend
- `go.mod` → Go
- `Cargo.toml` → Rust
- Anything else recognizable with a native coverage tool → use it, following the same pattern

No recognizable test tooling at all → skip to Step 3 with the explicit "not measurable" outcome.

## Step 2 — Run it

- **Node/TS:** `tsc --noEmit && vitest run --coverage` (or `jest --coverage` if that's the configured runner)
- **Go:** `go build ./... && go test ./... -cover`
- **Rust:** `cargo build && cargo tarpaulin`
- Equivalent native invocation for whatever else matched Step 1.

Capture the actual percentage reported, scoped to what this diff touched where the tool supports that; otherwise report the whole-suite number and say so explicitly (don't imply diff-scoping that didn't happen).

## Step 3 — Report

- Tool ran → report the real percentage, plus which tool produced it.
- No test runner found in the repo at all → report explicitly: `Coverage not measurable — no test runner found in repo.` This is a finding to surface, never a silent gap the caller has to notice is missing.

Boilerplate exclusion (DTOs, auto-properties, generated code, thin pass-through plumbing) is the caller's judgment to apply against the number this skill reports — this skill reports the raw tool output, it doesn't decide what counts as boilerplate for a stack it wasn't specifically written for.
