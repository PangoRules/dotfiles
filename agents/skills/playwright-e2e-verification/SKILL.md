---
name: playwright-e2e-verification
description: Use before LGTM on a diff that touches a feature covered by an existing Playwright E2E suite — detects the project's E2E setup and runs it. Skip if no Playwright config exists; this is not a mandate to add E2E infra.
---

Run existing Playwright E2E coverage before sign-off. Detection-based — this skill verifies what's already there, it doesn't scaffold new E2E infrastructure.

## Step 1 — Detect E2E setup

```bash
find . -maxdepth 3 -iname "playwright.config.*" -not -path "*/node_modules/*"
```

No config found → this skill doesn't apply. Stop here, don't report a failure for infra that doesn't exist.

Config found → read it for:
- `testDir` — where specs live
- `webServer` block — does Playwright auto-start the dev server, or does it expect one already running?
- `baseURL` — what the tests target

## Step 2 — Check whether the diff touches covered ground

```bash
grep -rl "<feature/route/component name from the diff>" <testDir>
```
If the diff touches a page/flow with no matching spec, that's worth noting in the review but isn't this skill's job to fix — flag it as a coverage gap, not a blocker.

## Step 3 — Get the stack running

Check `package.json` scripts for the project's own dev-server and E2E commands rather than guessing generic ones:
```bash
cat package.json | grep -A2 '"scripts"'
```
Common shape: a `dev` script for the frontend, a separate backend start command, then a `test:e2e` script. If `webServer` is configured in `playwright.config.*`, Playwright may start the server itself — don't manually start a second instance on the same port if so.

## Step 4 — Run

```bash
<the project's test:e2e script, e.g. pnpm test:e2e / npm run test:e2e>
```

If tests require seeded data or specific env vars (check the E2E spec files' setup blocks or a project README/CLAUDE.md section on E2E), ensure those are met before running — a failure caused by missing test fixtures is a setup problem, not a regression, and should be reported as such rather than blocking LGTM on a false positive.

## Step 5 — Report

- All green → note it passed, proceed.
- Failures → paste the actual failing assertion output, not just "E2E failed." A screenshot/trace path from Playwright's own failure report (`test-results/`) is more useful than a summary if one was generated.
- Flaky test (passes on retry) → note it as flaky, don't silently ignore — flag for the plan/backlog, don't let it block this LGTM if the underlying feature clearly works and the flake is pre-existing.
