---
name: api-contract-diff
description: Use when a diff changes a controller/route/endpoint and the project generates one or more API clients from a schema (OpenAPI/Swagger, GraphQL SDL, protobuf) — diffs the schema before vs after to catch breaking changes a same-repo compile won't, because a decoupled client (e.g. a TUI or mobile app with no ProjectReference to the server) never fails to build even when the contract breaks under it.
---

A removed field, renamed route, or newly-required parameter is invisible to the server's own build if nothing in the same compilation unit consumes it — the break only shows up at runtime, in whichever client wasn't in the same build. Diff the schema directly instead of trusting "it compiled."

## Step 1 — Detect the schema and how it's generated

| Signal | Schema source | Get before/after |
|---|---|---|
| ASP.NET Core `Microsoft.AspNetCore.OpenApi` / Swashbuckle | `<server>/openapi/v1.json` (or `/swagger/v1/swagger.json`) | run the server on the parent commit, `curl` the doc, then again on the current tip |
| `graphql-code-generator` config, `schema.graphql` | GraphQL SDL file | `git show <parent-sha>:<schema-path>` vs current file |
| `.proto` files + a codegen step | protobuf schema | `git show <parent-sha>:<file>.proto` vs current file |
| No schema/codegen setup found | — | skip, nothing to diff |

## Step 2 — Diff and classify

Compare the two schema snapshots. Breaking changes (always a finding):
- A path/operation/field present before and absent now
- A previously-optional request field now required, with no default
- A response field's type narrowed or removed (a client reading it now gets `undefined`/deserialization failure)
- A route path or HTTP method changed on an existing operation (not a new one added alongside)

Non-breaking (note, not a finding): new optional fields, new endpoints, new enum values appended at the end (unless the consuming language does exhaustive switch matching on that enum — check).

## Step 3 — Report

For each breaking change: what changed, which endpoint/field, and which generated client(s) in the repo actually consume it (grep the generated client dir for the affected operation/type name) — a break in an endpoint no client calls yet is lower urgency than one an existing screen depends on, say which is which.

## When to run

`@levi`, on any diff touching a controller action, resolver, or `.proto` service definition.
