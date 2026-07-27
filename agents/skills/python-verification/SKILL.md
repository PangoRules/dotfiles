---
name: python-verification
description: Use before LGTM on a diff touching Python code — detects which lint/type/test tooling the project actually has configured and runs it. Does not assume ruff/mypy exist; reports the gap honestly if they don't.
---

Verification sequence for Python changes. Detection-based — don't assume a tool is installed just because it's common; check first.

## Step 1 — Detect configured tooling

```bash
cat pyproject.toml 2>/dev/null
cat setup.cfg 2>/dev/null
ls .flake8 mypy.ini pytest.ini tox.ini 2>/dev/null
```

Look for `[tool.ruff]`, `[tool.mypy]`, `[tool.black]`, `[tool.pytest.ini_options]` sections, or standalone config files. Also check for a pre-commit config (`.pre-commit-config.yaml`) — it's often the authoritative list of what actually gets enforced.

## Step 2 — Run what's configured, in this order

1. **Format check** (if `black`/`ruff format` configured): `black --check .` or `ruff format --check .`
2. **Lint** (if `ruff`/`flake8` configured): `ruff check .` or `flake8`
3. **Type check** (if `mypy`/`pyright` configured): `mypy .` or `pyright`
4. **Tests**: `pytest` (respect `testpaths` from config if set)

Run each only if its tool is actually configured. Do not install a tool that isn't already part of the project's setup just to run this check — that changes the project's dependencies as a side effect of verification, which isn't this skill's job.

## Step 3 — Report gaps, don't paper over them

If the project has no lint or type-check tooling configured at all, don't silently skip to "tests passed, LGTM" — say so explicitly:
```
No ruff/mypy/flake8 configured — only ran pytest. Static analysis coverage: none.
```
This is a real signal for the reviewer, not a footnote. A project with only tests and no static analysis has a different risk profile than one with both, and the review should reflect that.

## Step 4 — Async-specific check (if applicable)

If `pytest-asyncio` or `asyncio_mode = "auto"` is configured, confirm any new async test functions are actually `async def` and awaited correctly — a sync test silently passing on an unawaited coroutine is a common false-positive-pass pattern in async Python codebases.

## Pass criteria

All configured tools exit 0. If any tool isn't configured, that's a documented gap, not a failure — don't block on a check that doesn't exist. If a configured tool fails, that blocks LGTM same as any other verification skill in this system.
