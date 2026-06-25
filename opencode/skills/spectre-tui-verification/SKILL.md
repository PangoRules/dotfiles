---
name: spectre-tui-verification
description: Use before marking any Spectre.Console TUI task done — runs build, smoke check, and feature parity reminder. Companion to nuxt-verification and dotnet-verification for terminal UI layers.
---

# Spectre.Console TUI Verification

Projects with both a TUI and a web/API surface often have a feature parity requirement. A diff that adds something to one surface without a matching implementation on the other (or an explicit parity-deferred note in the plan) is incomplete.

## Step 1 — Build

```bash
dotnet build <tui-project>
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
dotnet run --project <tui-project>
```

Navigate to the affected screen. Verify:
- Layout renders without exceptions
- Color scheme consistent (no stray default colors mixed with themed ones)
- No truncated text from fixed-width columns that don't adapt to content length
- Keyboard navigation works as expected (if applicable)

Exercise only what the diff touched — no need to walk every screen.

## Step 4 — Feature parity check (if project has parity requirement)

If your project requires TUI and web/API to expose the same features, compare the diff:

```bash
# What the diff changed in TUI
git diff --name-only | grep -i tui

# Equivalent in web/frontend
git diff --name-only | grep -iv tui
```

For each new feature or behavior in the diff, confirm one of:
1. Equivalent implementation exists in this diff for the other surface, OR
2. Explicitly deferred in the plan ("TUI deferred to task N" or similar)

If neither: parity violation. Flag as a finding.

## Step 5 — Full solution test

After TUI-specific checks, run the full suite:

```bash
dotnet build
dotnet test
```

TUI changes often touch shared Application-layer code used by both the server and the TUI. Run the full suite, not just the TUI project — a shared use case change can break the server's tests without touching any server-specific file.

## Common Spectre.Console pitfalls

| Pitfall | Symptom | Fix |
|---------|---------|-----|
| `AnsiConsole.Write` on a non-ANSI terminal | Escape codes render as literal text | Use `AnsiConsole.Profile.Capabilities.Ansi` check or `--no-ansi` flag |
| Fixed-width table column with long dynamic content | Text truncated silently | Set `Expand()` or use `NoWrap()` deliberately |
| `Live` display + `AnsiConsole.Ask` in same session | Interleaved output corruption | Can't mix live renders with blocking prompts — split into separate phases |
| Markup with unescaped `[` in user content | `Markup` throws or renders wrong | Escape user strings: `Markup.Escape(userInput)` |
| Color that looks fine on dark terminal, invisible on light | Contrast failure | Test on both dark and light terminal backgrounds |
