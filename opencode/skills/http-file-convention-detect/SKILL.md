---
name: http-file-convention-detect
description: Use before creating a new .http smoke-test file for an endpoint — detects the project's own existing .http file location, naming, variable/auth, and request-ordering conventions so new files are immediately usable with the project's REST Client tooling instead of a one-off guess. Stack-agnostic.
---

Do not assume a `.http` file layout. Check first — a project's own convention always wins over a generic template. This is the authoring half of what `@levi`'s Mandatory checks already verify the *existence* of for `http`-scoped tasks; this skill is how the file gets written well in the first place, not just confirmed present.

## Step 1 — Locate existing `.http` files

```bash
find . -iname "*.http" -not -path "*/node_modules/*" -not -path "*/bin/*"
```

None found → this is a genuinely new convention for the project; skip to Step 3.

## Step 2 — Extract the convention from 1-2 existing files

Read them and note, concretely:
- **Location/granularity** — one `.http` file per feature/controller (e.g. `http/presets.http`) vs a single monolithic file for the whole API. Match the existing split, don't introduce a new granularity.
- **Base URL / environment variables** — `@baseUrl = http://localhost:5000` inline, or a separate `http-client.env.json` / `.vscode/settings.json` REST Client environment block. Reuse the existing variable name, don't invent `@apiUrl` alongside an existing `@baseUrl`.
- **Auth pattern** — a login request whose response is captured and chained into subsequent requests' `Authorization` header (`Authorization: Bearer {{login.response.body.$.token}}`) is the common REST Client/IntelliJ HTTP Client idiom — check whether the project already names this chained variable something specific and reuse it exactly.
- **Request separation/naming** — `### <VERB> <route> — <one-line purpose>` comment headers between requests is the standard separator for both REST Client and IntelliJ HTTP Client; confirm the project's exact comment style (some use `# @name requestName` for named/chainable requests — needed if the new endpoint's smoke test must chain off an existing request like login or a create-then-fetch pair).
- **Ordering convention** — existing files commonly order CRUD requests create → list → get-by-id → update → delete; match it so a new endpoint's block reads the same way as its siblings.

## Step 3 — Fall back only if nothing established

No existing `.http` files: use this REST Client-compatible default, one file per feature under `http/<feature>.http`:

```http
@baseUrl = http://localhost:5000
@token = {{login.response.body.$.token}}

### Login
# @name login
POST {{baseUrl}}/api/auth/login
Content-Type: application/json

{
  "email": "test@example.com",
  "password": "password"
}

### Create <resource>
POST {{baseUrl}}/api/<resource>
Authorization: Bearer {{token}}
Content-Type: application/json

{
  "name": "example"
}

### Get <resource> by id
GET {{baseUrl}}/api/<resource>/{{id}}
Authorization: Bearer {{token}}
```

## Step 4 — Report before writing

State which path was taken (matched `<file>`'s convention, or fallback default) and the exact file path about to be written/extended — a caller checking this against the plan's Files list needs that path, not a description of the convention itself.

## Common mistakes

- Writing a raw `curl` block instead of a REST Client-compatible `.http` file — defeats the point, nobody can click-to-run it in the editor.
- Hardcoding a bearer token value instead of chaining it from a login request — breaks the moment the token expires, and it's a credential sitting in a committed file.
- Skipping the `### <purpose>` comment header — makes the file unreadable as a smoke-test checklist, which is its actual job.

## Idempotent by nature

Read-only detection — safe to call repeatedly, always reflects the project's current `.http` file conventions.
