---
name: hardcoded-endpoint-check
description: Use during review of frontend/client code that calls an API — detects whether the project has a centralized route/endpoint constants convention, and if so flags inline URL/path literals that bypass it. No-ops cleanly if no such convention exists.
---

Checks for endpoint-string drift, generalized across whatever centralization convention (if any) a project has chosen. Doesn't invent a requirement that isn't already the project's own rule.

## Step 1 — Detect whether a centralized convention exists

```bash
find . -maxdepth 4 \( -iname "routes.ts" -o -iname "*routes.ts" -o -iname "endpoints.ts" -o -iname "*endpoints.ts" -o -iname "api-routes.*" -o -iname "urls.py" \) -not -path "*/node_modules/*"
```
Also check `CLAUDE.md`/`AGENTS.md` for an explicit rule ("all API paths live in `lib/routes.ts`" or similar).

**No such file and no documented rule** → this skill doesn't apply to this project. Stop here — don't invent the convention as a finding; a project with no centralization rule isn't violating one.

**Convention found** → read the file to know the actual exported constant/function names before grepping for violations (so you can tell a legitimate reference apart from a bypass).

## Step 2 — Grep for bypasses

Search the changed files (or the whole client-side codebase for a full audit) for inline path/URL literals passed directly to the HTTP client, that don't go through the centralized constants:
```bash
grep -rn "fetch(\|axios\.\|\.get(\|\.post(\|\.put(\|\.delete(\|useApi(" <target files> | grep -v "<the centralized import/constant names from Step 1>"
```
Refine per what the HTTP client actually looks like in this project (raw `fetch`, `axios`, a custom `useApi()`/`apiClient` wrapper, openapi-typescript-generated client, etc.) — the grep above is a starting shape, not a fixed command.

A hit is a real finding only if:
1. It's a literal path string (`'/api/projects/' + id`, `` `/api/cards/${cardId}` ``) built inline, not a call to the centralized helper.
2. The centralized file has (or plausibly should have) an equivalent entry for that resource.

Don't flag genuinely one-off URLs that aren't part of the app's own API surface (external links, documentation URLs, CDN asset paths) — the convention is about this app's own endpoints, not every string that looks like a path.

## Step 3 — Report

```markdown
### [finding] <file:line>
- **Inline literal:** `<the hardcoded path found>`
- **Should use:** `<the centralized constant/function this should call instead, or "add one" if the resource has no entry yet>`
```

If a resource has no centralized entry at all yet (this is the first call site for it), the fix is "add it to the routes file," not just "use an existing one" — say which.
