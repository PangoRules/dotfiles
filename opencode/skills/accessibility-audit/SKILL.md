---
name: accessibility-audit
description: Use when reviewing a frontend diff on a project that states an accessibility requirement (WCAG, ARIA, "keyboard-navigable" in scope.md/CLAUDE.md) — detects whatever automated a11y tooling the project already has and runs it, falls back to a manual checklist pass if none exists.
---

Automated a11y tools catch maybe half of real issues (contrast, missing labels, landmark structure) — the rest (focus order, meaningful keyboard nav, screen-reader announcement of dynamic content) still needs a manual pass. Run both, don't stop at whichever is cheaper.

## Step 0 — Confirm this project actually requires it

Check `docs/scope.md`/`CLAUDE.md`/`AGENTS.md` for an explicit accessibility requirement (WCAG level, "keyboard-navigable is a settled requirement", ARIA mention). None found → skip silently, don't invent a requirement the project never stated.

## Step 1 — Automated tooling, if present

| Signal | Tool | Run |
|---|---|---|
| `@axe-core/playwright` in `package.json` | axe + Playwright | run the existing E2E suite with axe injected, or a dedicated a11y spec if one exists |
| `eslint-plugin-jsx-a11y` / `eslint-plugin-vuejs-accessibility` in eslint config | lint-time a11y rules | already covered by the diff's normal lint pass (`lint-format-detect`) — just confirm the plugin is actually enabled, not just installed |
| `cypress-axe` | axe + Cypress | run against the affected route(s) |
| None of the above | — | no automated pass available — say so explicitly, go straight to Step 2 |

## Step 2 — Manual checklist (always run, regardless of Step 1 tooling)

Against every new/changed interactive component in the diff:
- Every actionable element reachable by keyboard alone (Tab/Shift+Tab), visible focus indicator present
- Every image/icon-only button has an accessible name (`alt`, `aria-label`, or visible text — not `title` alone)
- Form inputs have an associated `<label>` (not just placeholder text)
- Color is never the only signal (error states, required fields) — check for a second cue (icon, text)
- Dynamic content updates (toasts, live-updating lists) use an `aria-live` region or equivalent, not silent DOM changes
- Modal/dialog components trap focus while open and restore it on close

## Step 3 — Report

Findings same shape as any Levi finding: what, where (file:line/component), why it matters, fix. Automated-tool findings and manual-checklist findings go in the same list, not split into two tiers of severity.

## When to run

`@levi`, on any diff touching frontend components, when Step 0's project-level requirement check passes.
