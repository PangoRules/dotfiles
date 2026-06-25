---
name: pgvector-migration-safety
description: Use when a diff adds or modifies vector columns, vector indexes, or pgvector extension setup — EF Core migrations have specific pitfalls with pgvector that cause silent runtime failures not caught by build or test.
---

# pgvector Migration Safety

EF Core wraps migrations in transactions by default. Several pgvector operations cannot run inside a transaction. These fail at migration apply time, not at build or test time — the error surface is `dotnet ef database update` or first startup, not CI.

## The three pgvector pitfalls

### Pitfall 1 — Index creation inside a transaction

`CREATE INDEX CONCURRENTLY` (required for HNSW and IVFFlat indexes on large tables) cannot run in a transaction. EF wraps every migration in `BEGIN` / `COMMIT`.

**Fix:** mark the migration as not using a transaction:

```csharp
public partial class AddVectorIndex : Migration
{
    protected override bool SuppressTransaction => true;  // EF Core 8+

    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql(
            "CREATE INDEX CONCURRENTLY idx_embeddings_vector ON embeddings USING hnsw (embedding vector_cosine_ops)",
            suppressTransaction: true);
    }
}
```

Without `SuppressTransaction`, the migration applies but the index is never created — no error, silent failure.

### Pitfall 2 — pgvector extension not created first

`CREATE EXTENSION IF NOT EXISTS vector` must run before any `vector(N)` column can be created. If it's missing from the earliest migration, the deployment fails on a clean database.

**Check:**
```bash
grep -rn "vector" src/Infrastructure/Migrations/ | grep -i "extension\|CREATE EXTENSION"
```

Expected: at least one migration creates the extension before any migration creates a vector column. If missing, add it to the first migration that uses vectors:

```csharp
migrationBuilder.Sql("CREATE EXTENSION IF NOT EXISTS vector");
```

### Pitfall 3 — Column type not recognized by EF

EF Core doesn't know the `vector(N)` type natively. Without explicit configuration, it generates a migration with the wrong column type.

**Required configuration in `IEntityTypeConfiguration<T>`:**
```csharp
builder.Property(e => e.Embedding)
    .HasColumnType("vector(1536)");  // dimension must match your model's output
```

**Check:**
```bash
grep -rn "HasColumnType.*vector" src/Infrastructure/
```

If a vector property exists without `HasColumnType("vector(N)")`, the column will be created as `text` or `bytea` — no error at build time, silent corruption.

## Verification sequence

Run these in order whenever a diff touches vector columns or indexes:

### Step 1 — Extension present
```bash
grep -rn "CREATE EXTENSION" src/Infrastructure/Migrations/ | grep vector
```
Must exist in a migration that runs before any vector column migration.

### Step 2 — Column types explicit
```bash
grep -rn "HasColumnType.*vector" src/Infrastructure/
```
Every vector property must have explicit `HasColumnType`.

### Step 3 — Index migration transaction-safe
```bash
grep -rn "SuppressTransaction\|suppressTransaction" src/Infrastructure/Migrations/
```
Every migration that creates a vector index must suppress the transaction.

### Step 4 — Migration drift check
```bash
PATH="$PATH:$HOME/.dotnet/tools" dotnet ef migrations has-pending-model-changes \
  --project src/Infrastructure \
  --startup-project src/Server
```
No pending changes expected.

### Step 5 — Apply to local dev DB
```bash
PATH="$PATH:$HOME/.dotnet/tools" dotnet ef database update \
  --project src/Infrastructure \
  --startup-project src/Server
```
This is the only check that catches transaction-incompatible operations. Must succeed without errors.

## Reviewer note

Build passing, tests passing, and even migration drift check passing do NOT catch Pitfalls 1–3 above. Step 5 (actual `database update`) is the only reliable gate. If a diff adds vector columns or indexes and Step 5 was not run, that is a finding.
