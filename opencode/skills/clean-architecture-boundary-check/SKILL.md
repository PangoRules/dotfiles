---
name: clean-architecture-boundary-check
description: Use when reviewing a diff in a Clean Architecture codebase (Domain → Application → Infrastructure → presentation) — verifies no inner layer imports an outer layer.
---

# Clean Architecture Boundary Check

The Dependency Rule: dependencies point inward only. Domain knows nothing about Application, Infrastructure, HTTP, EF Core, or any framework. Application knows nothing about Infrastructure or presentation. A violation here is a structural bug, not a style nit — it locks the inner layer to a specific framework and blocks testing it in isolation.

## Step 1 — Identify the layers

Confirm project boundaries (read the solution file or folder layout if unsure):
- Domain — pure logic, zero framework references
- Application — orchestration, depends only on Domain (+ interfaces it defines)
- Infrastructure — implements Application's interfaces, depends on Domain + Application
- Presentation (Server/Web/Api) — depends on all, but only through Application's interfaces

## Step 2 — Grep for violations

Against every touched file in the Domain layer:
```bash
grep -rlE "using (Microsoft\.EntityFrameworkCore|Microsoft\.AspNetCore|System\.Net\.Http)" <DomainProjectPath>
```
Expected: no output. Any hit is a violation — EF Core, ASP.NET, or HTTP types leaking into Domain.

Against the Application layer:
```bash
grep -rlE "using .*\.Infrastructure" <ApplicationProjectPath>
```
Expected: no output. Application depends on its own interfaces, never the concrete Infrastructure implementation.

## Step 3 — Check the .csproj references too

Grep catches imports, not an unused `ProjectReference` someone added "just in case." Check `<ProjectReference>` entries in `Domain.csproj` and `Application.csproj` — Domain should reference nothing outward; Application should reference Domain only.

## Step 4 — Report

A violation is a blocking finding: name the file, the forbidden import, which layer it violates. Don't design the fix — that's the architect's (missing interface defined inward) or developer's (implementation moved outward) job.
