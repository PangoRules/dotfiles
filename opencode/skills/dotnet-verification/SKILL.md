---
name: dotnet-verification
description: Use before marking any .NET/EF Core task done, or when reviewing a diff that touches Domain entities, DbContext, or EF configuration — runs the standard build, test, and migration-drift checks.
---

# .NET Verification

Standard verification sequence for a change to a .NET solution using EF Core. Run all of it — partial checks miss migration drift, which fails later in CI or prod, not now.

## Step 1 — Build

```bash
dotnet build
```
Expected: success.

## Step 2 — Test

```bash
dotnet test
```
Run the full suite, not just the touched project — EF model changes can break Infrastructure tests in unrelated test projects (see `ef-core-model-test`).

## Step 3 — EF migration drift check

Required whenever the change touches an entity class, `DbContext`, or any `IEntityTypeConfiguration`.

```bash
dotnet ef migrations has-pending-model-changes --project <Infrastructure project> --startup-project <Server project>
```
Expected: no pending changes. If `dotnet ef` isn't on PATH: `PATH="$PATH:$HOME/.dotnet/tools" dotnet ef ...`

**Pending changes found** → a migration is missing. Add it in the same commit as the entity change:
```bash
dotnet ef migrations add <Name> --project <Infrastructure project> --startup-project <Server project>
```
Never ship an entity change without its migration — the gap surfaces as a runtime schema mismatch, not a build error.

## Reviewer note

Tests passing does not prove the schema is current — Step 2 can pass against a stale local schema. If a diff touches Domain entities or `DbContext` and Step 3 wasn't run, that's a finding, not an assumption to wave through.
