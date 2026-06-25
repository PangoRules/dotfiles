---
name: nuxt-verification
description: Use before marking any Nuxt/Vue/TypeScript frontend task done — runs the standard typecheck, lint, and build checks.
---

# Nuxt Frontend Verification

Standard verification sequence for a Nuxt + TypeScript frontend. Run in order — typecheck catches type errors lint won't, lint catches style/unused-import issues build won't, build catches bundling/SSR issues neither will.

## Step 0 — Fresh checkout only

If `node_modules` or `.nuxt` is missing or stale (fresh clone, dependency bump):
```bash
pnpm install
pnpm exec nuxt prepare
```
Skipping this makes lint fail on a missing generated config — don't misdiagnose that as a real lint error.

## Step 1 — Typecheck

```bash
pnpm typecheck
```

## Step 2 — Lint

```bash
pnpm lint
```

## Step 3 — Build

```bash
pnpm build
```

## All three must pass before LGTM

A frontend diff isn't done because the dev server didn't crash — `pnpm dev` skips type errors and most lint rules. Run all three before signaling done.
