---
name: spectre-tui-verification
description: Use before marking any Spectre.Console TUI task done — runs build, smoke check, and feature parity reminder. Companion to nuxt-verification and dotnet-verification for the TUI layer.
---

# Spectre.Console TUI Verification

Hydra-forge's TUI lives at `src/Tui/`. Feature parity with the web UI is a hard requirement (see AGENTS.md). A diff that adds something to the web without a matching TUI implementation (or an explicit parity-deferred note in the plan) is incomplete.

## Step 1 — Build

```bash
dotnet build src/Tui
```

Spectre.Console layout errors (invalid panel nesting, missing required constructor args) surface here.

## Step 2 — Unit tests

```bash
dotnet test --filter "Tui|TUI|Console|Spectre"
```

If nothing matches, note it — TUI logic is untested. Flag as a finding if the diff adds TUI behavior without a test.

## Step 3 — Smoke run

For any diff that touches live rendering (tables, progress bars, panels, prompts, menus):

```bash
dotnet run --project src/Tui
```

Navigate to the affected screen. Verify:
- Layout renders without exceptions
- Color scheme consistent (no stray default colors mixed with themed ones)
- No truncated text from fixed-width columns that don't adapt to content length
- Keyboard navigation works as expected (if applicable)

Abort after confirming the affected surface — don't need to exercise every screen, just what the diff touched.

## Step 4 — Feature parity check

Compare the diff against the web-ui equivalent:

```bash
# What the diff added/changed in TUI
git diff --name-only | grep -i tui

# Equivalent in web-ui
git diff --name-only | grep -i "web-ui\|frontend"
```

For each new feature or behavior in the diff, confirm one of:
1. TUI equivalent exists in this diff, OR
2. Web-only feature with explicit "TUI deferred" note in the plan

If neither: parity violation. Flag as a finding.

## Step 5 — Full dotnet verification

After TUI-specific checks, run the standard .NET sequence:

```bash
dotnet build
dotnet test
```

TUI changes can break shared Application-layer code used by both Server and TUI. Run the full suite, not just the TUI project.

## Reviewer note

The TUI and web UI share Application-layer use cases. A TUI change that adds a new use case or modifies an existing one will affect the web too — and vice versa. Treat any Application-layer change as touching both surfaces, even if only one of them is in the diff.
