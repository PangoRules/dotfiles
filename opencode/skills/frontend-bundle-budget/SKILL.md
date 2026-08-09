---
name: frontend-bundle-budget
description: Use when a frontend diff adds a dependency, a route, or a large asset — builds the app and compares output size against the parent branch, flags regressions past a threshold. Relevant on any mobile-first or bandwidth-sensitive project.
---

A dependency bump or an unlazy-loaded import can silently double a route's shipped JS with no functional test catching it — bundle size only regresses visibly to a user on a slow connection, which nothing in a normal test suite simulates.

## Step 1 — Build both tips

```bash
git stash -u  # or worktree — don't lose in-progress changes
git checkout <parent-branch> && pnpm build && du -sh .output/public 2>/dev/null || du -sh .nuxt/dist/client 2>/dev/null
git checkout <branch> && pnpm build && du -sh .output/public 2>/dev/null || du -sh .nuxt/dist/client 2>/dev/null
```
Adjust the output dir for the actual framework (Nuxt: `.output/public`; plain Vite: `dist/`; Next: `.next/`).

## Step 2 — Compare

Report both sizes and the delta as a percentage. Flag as a finding if the increase exceeds **10%** on a diff that isn't itself a large new feature route (a genuinely new page/route shipping meaningful new JS is expected to grow the bundle — that's not a regression, say so explicitly rather than flagging every new feature).

## Step 3 — If flagged, check the obvious causes first

- New dependency imported at the top level instead of lazy/dynamic-imported for a route only some users hit
- A large library imported in full instead of its tree-shakeable named exports (`import _ from 'lodash'` vs `import debounce from 'lodash/debounce'`)
- An image/asset that should be in `public/` (served as-is) but landed in the JS bundle instead

## When to run

`@levi`, on a frontend diff whose `package.json`/lockfile changed, or that adds a new route/page. Skip on diffs that only touch existing component internals with no dependency or route changes — not worth the build-twice cost for every diff.
