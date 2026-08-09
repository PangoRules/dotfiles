---
name: lint-format-detect
description: Use whenever a diff needs lint/format checking — detects which linter and formatter a project actually has configured (per language, per project) and runs those, instead of assuming a default tool per language. Stack-agnostic.
---

Assuming "the" formatter for a language is wrong more often than it looks — .NET alone splits across `dotnet format`, CSharpier, and StyleCop depending on the project. Detect what's actually configured before running anything.

## Step 1 — Detect configured tools

Check for signal files, most-specific first. A repo can have more than one tool per language (e.g. ESLint + Prettier) — run every match, don't stop at the first hit.

| Signal | Tool | Lint command | Format-check command |
|---|---|---|---|
| `.config/dotnet-tools.json` contains `"csharpier"` | CSharpier (.NET) | — | `dotnet csharpier check .` |
| `.csharpierrc`/`.csharpierrc.json` present, no tool-manifest entry found | CSharpier (.NET) | — | `dotnet csharpier check .` |
| `.editorconfig` + `*.csproj`/`*.sln`, **no CSharpier signal above** | dotnet format | — | `dotnet format --verify-no-changes` |
| `.eslintrc*` / `eslint.config.*` | ESLint | `<pkg-manager> lint` (or `eslint .` if no script) | — |
| `.prettierrc*` / `prettier.config.*` / `"prettier"` key in `package.json` | Prettier | — | `prettier --check .` |
| `pyproject.toml` has `[tool.ruff]` | Ruff | `ruff check .` | `ruff format --check .` |
| `pyproject.toml` has `[tool.black]`, no ruff format section | Black | — | `black --check .` |
| `.golangci.yml` | golangci-lint | `golangci-lint run` | `gofmt -l .` |
| `Cargo.toml` (Rust default) | rustfmt/clippy | `cargo clippy -- -D warnings` | `cargo fmt --check` |
| `.rubocop.yml` | RuboCop | `rubocop` | — |

**.NET priority rule:** if both a CSharpier signal and a bare `.editorconfig` exist, CSharpier wins — it's the explicitly-installed tool, `.editorconfig` alone is just IDE hints. Say which one you picked and why so it's never a silent guess.

## Step 2 — Run every matched command

Each command's non-zero exit / non-empty diff-check output is a finding: file:line (or file list if the tool doesn't give lines), rule/rule-set, fix (usually "run the format command locally").

## Step 3 — Nothing configured

No signal file for a language present in the diff → skip silently, do not invent a style opinion no tool backs. Report as "no linter/formatter configured for `<language>`" only if asked, not as a finding.

## When to run

- `@levi`, every review cycle, as the Mandatory lint/format check — replaces guessing a single tool per language.
- `@arthur`, before each commit — catches format issues before they ever reach review, cheaper than burning a review cycle on whitespace.
