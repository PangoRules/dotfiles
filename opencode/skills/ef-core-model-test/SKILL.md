---
name: ef-core-model-test
description: Use when writing or reviewing Infrastructure-layer tests for EF Core entity configuration — verifying the model contract without a live database.
---

# EF Core Model Contract Tests

Infrastructure tests for entity mapping should assert against the compiled EF model (`context.Model`), not a live database. Fast, DB-independent, still catches real mapping mistakes (missing column, wrong index, dropped cascade rule).

## Pattern

```csharp
private static IEntityType GetEntityType<T>(DbContext context) =>
    context.Model.FindEntityType(typeof(T))!;

private static void AssertProperties(IEntityType entityType, params string[] expectedProperties)
{
    var actual = entityType.GetProperties().Select(p => p.Name).ToHashSet();
    foreach (var expected in expectedProperties)
        Assert.Contains(expected, actual);
}
```

## What to assert

- **Properties exist** — `AssertProperties(entityType, "Id", "ArchivedAt", ...)`.
- **Indices** — `entityType.GetIndexes()`, check property names and `IsUnique`.
- **Cascade rules** — `entityType.GetForeignKeys()`, check `DeleteBehavior`.
- **Special column types** — e.g. pgvector columns: `property.GetColumnType()` equals the expected type string (`vector(1536)`).

## When a live-database test IS warranted

Only when the behavior can't be observed from the model alone — actual query execution, concurrency, trigger behavior. Gate these behind an environment variable so the suite runs without a database by default. Never fall back to SQLite or a mock for behavior specified as provider-specific (vector extension, JSONB operators) — a passing SQLite test proves nothing about that provider's behavior.

## Pitfall: new constructor dependency breaks unrelated tests

Adding a property or relationship to an entity is a model-test concern. Adding a new injected port to a service that uses that entity is a different concern — every test factory that builds the service via DI now needs the new dependency stubbed, or the real implementation resolves in tests and fails with 500s, not DI errors. Check the project's AGENTS.md for which factories need updating.
