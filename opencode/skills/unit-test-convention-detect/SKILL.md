---
name: unit-test-convention-detect
description: Use before writing any new unit test file — detects the project's own existing test naming, structure, fixture/builder, and mocking conventions so new tests match what's already there instead of each writer guessing from whatever sibling file they happened to skim. Stack-agnostic.
---

Do not assume a testing framework or house style. Check first, every time — a project's own existing tests always win over a generic default. Same "detect the convention, don't assume a framework" shape as `docs-convention-detect` and `lint-format-detect`.

## Step 1 — Detect the test framework/runner

Look for the manifest signal, not a guess:

| Signal | Framework |
|---|---|
| `vitest.config.*`, `"vitest"` in `package.json` | Vitest |
| `jest.config.*`, `"jest"` in `package.json` | Jest |
| `*.csproj` referencing `xunit`/`nunit`/`MSTest.TestFramework` | .NET (xUnit/NUnit/MSTest) |
| `pytest.ini`, `pyproject.toml` `[tool.pytest]`, `conftest.py` | pytest |
| `go.mod` + `_test.go` files | Go `testing` (+ `testify` if imported) |
| `Cargo.toml` + `#[cfg(test)]` modules | Rust built-in |

No signal found and no existing tests → this is a genuinely greenfield suite; skip to Step 3.

## Step 2 — Extract the convention from 1-2 existing test files

Find tests near the code being touched first; fall back to any test file in the suite if none are nearby:

```bash
find . -iname "*test*" -o -iname "*spec*" -not -path "*/node_modules/*" -not -path "*/bin/*" -not -path "*/obj/*" | head -5
```

Read 1-2 and extract, concretely:
- **File naming/location** — `*.test.ts` colocated vs `__tests__/` dir vs `*Tests.cs` in a mirrored `tests/` tree vs `test_*.py`.
- **Test naming** — `MethodName_Scenario_ExpectedBehavior`, `should_do_x`, `it('does x')`, `Test_X_When_Y` — match the exact pattern already in use, don't invent a new one.
- **Structure markers** — explicit `// Arrange / Act / Assert` comments, blank-line separation between the three phases, or `Given/When/Then` — whichever the existing suite actually uses.
- **Fixture/builder pattern** — a `Builders/`, `Fixtures/`, or `TestData/` folder; a fluent builder (`UserBuilder.Default().WithEmail(...).Build()`); factory functions; inline object literals. Match what's already there rather than introducing a second pattern into the same suite.
- **Mock/stub style** — `jest.mock`/`vi.mock` module-level vs constructor-injected fakes, `Moq`/`NSubstitute` conventions, `unittest.mock.patch`, `testify/mock`. Note whether the suite prefers real collaborators over mocks (per `superpowers:test-driven-development`'s own "real code, no mocks unless unavoidable" default) or mocks liberally — match the existing bias.

## Step 3 — Fall back only if nothing established

No existing tests to pattern-match: use the framework detected in Step 1 (or the language's most idiomatic default if Step 1 also found nothing) with:
- One behavior per test, arrange/act/assert as three visually separated blocks
- Descriptive name stating the scenario and expected outcome
- Real collaborators over mocks unless a genuine external boundary (network, filesystem, clock) forces one

## Step 4 — Report before writing

State which path was taken (matched convention from `<file>`, or fallback default) and the concrete naming/structure you're about to use — one short paragraph, not a re-explanation of this skill.

## Common mistakes

- Copying whatever test file was open in context instead of actually checking the suite's dominant pattern — one file can be the outlier.
- Introducing a second builder/fixture pattern alongside an existing one because it wasn't searched for first.
- Matching syntax but not the mocking philosophy — a suite that avoids mocks and one that mocks everything look similar file-by-file but diverge hard on `TestFixture` design.

## Idempotent by nature

Read-only detection — safe to call repeatedly, always reflects the project's current test suite.
