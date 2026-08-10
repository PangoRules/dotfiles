---
name: e2e-test-convention-detect
description: Use before writing a new end-to-end spec — detects the project's own selector strategy, wait strategy, and structural pattern (page objects vs inline) so new specs match what's already there, and enforces condition-based waiting over fixed sleeps. Framework-agnostic (Playwright, Cypress, WebdriverIO).
---

Do not assume a selector or wait strategy. Check first — a project's own existing specs always win over a generic pattern. This is the authoring half of what `playwright-e2e-verification` already verifies *passes*; this skill is how the spec gets written well in the first place.

## Step 1 — Detect the e2e framework

```bash
find . -maxdepth 3 \( -iname "playwright.config.*" -o -iname "cypress.config.*" -o -iname "wdio.conf.*" \) -not -path "*/node_modules/*"
```

None found → genuinely new e2e infra for this project. Skip to Step 4 — default to Playwright, the most common current choice and what `playwright-e2e-verification` already assumes.

## Step 2 — Extract the convention from 1-2 existing specs

- **Selector strategy** — a `data-testid` attribute convention (note the exact naming shape, e.g. `card-modal-desktop` — kebab-case, component-then-variant) vs role/label-based locators (`getByRole`, `getByLabel`) vs raw CSS. Match whichever the suite already committed to; mixing strategies in the same suite makes specs inconsistent to maintain.
- **Structural pattern** — page-object classes wrapping locators/actions vs specs calling `page.locator(...)` inline. Match it; introducing page objects into a suite that's inline-only (or vice versa) is a structural change bigger than one spec should make unasked.
- **Test data setup** — API-seeded fixtures vs UI-driven setup (e.g. a spec that signs up through the UI before testing the actual flow under test). Match the existing bias — UI-driven setup for everything is slow and brittle if the suite has already moved to API seeding, and vice versa.

## Step 3 — Wait strategy: condition-based only, no fixed sleeps

**Hard rule regardless of what Step 2 finds**, because a fixed-sleep wait has already caused a real regression in this exact class of project: a prior spec used a fixed sleep, which produced an intermittent failure that got misdiagnosed before the fix landed as `fix(e2e): replace fixed sleep with focused assertion and condition-based waits`. That fix is the standard to hold every new spec to from the start, not something to discover again in review:

- **Never**: `page.waitForTimeout(N)` / `cy.wait(N)` / any fixed-duration sleep.
- **Always**: condition-based assertions that poll until true or timeout — `await expect(locator).toBeVisible()`, `await expect(locator).toHaveText(...)`, `cy.get(...).should(...)`. These wait exactly as long as needed, never longer, and don't produce the "works most of the time" flakiness a fixed sleep does under load or on a slower CI runner.
- If a genuine wait for an async side-effect is needed (a toast that appears after a debounced save, a websocket push), wait on the *effect* (the toast becoming visible, the new row appearing) — never on a guessed duration.

## Step 4 — Fall back only if nothing established

No existing specs: default to Playwright, `data-testid` selectors (most resilient to markup/copy changes), inline locators (no page-object layer until the suite is large enough to justify one), API-seeded test data where the project has a seeding endpoint or script, and the condition-based wait rule from Step 3 applied from the first spec written.

## Step 5 — Report before writing

State which path was taken (matched convention from `<file>`, or fallback default) and the selector/wait strategy about to be used — one short paragraph.

## Common mistakes

- Reaching for a fixed sleep "just to get the flaky test passing" under time pressure — this is exactly the pattern that already caused a real incident; treat any temptation toward `waitForTimeout` as a sign the actual condition to wait on hasn't been identified yet, not a shortcut to take.
- Matching CSS-selector syntax from an existing spec without checking whether the suite has since moved to `data-testid` in newer specs — check recency, not just the first file found.
- Adding a page-object class for one spec in an otherwise-inline suite because it "feels cleaner" — that's an unrequested structural change, flag it as a suggestion instead of doing it unasked.

## Idempotent by nature

Read-only detection — safe to call repeatedly, always reflects the project's current e2e suite conventions.
