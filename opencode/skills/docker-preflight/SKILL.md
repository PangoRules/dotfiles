---
name: docker-preflight
description: Use at the start of any dev task or when tests fail with connection errors — verifies docker-compose services are up and healthy before assuming code is broken.
---

# Docker Preflight

Hydra-forge dev requires three services: PostgreSQL 16 (port 5433), MinIO, and pgvector extension loaded. Missing or unhealthy services produce errors that look like code bugs. Run this first before debugging any database or file-storage failure.

## Step 1 — Services running

```bash
docker compose ps
```

All services should show `running` or `healthy`. If any show `exited` or `starting`:

```bash
docker compose up -d
```

Wait ~5 seconds, then re-check `docker compose ps`.

## Step 2 — PostgreSQL reachable

```bash
pg_isready -h localhost -p 5433 -U postgres
```

Expected: `localhost:5433 - accepting connections`

If `pg_isready` isn't on PATH:
```bash
docker compose exec postgres pg_isready -U postgres
```

## Step 3 — pgvector extension installed

```bash
docker compose exec postgres psql -U postgres -d hydraforge -c \
  "SELECT installed_version FROM pg_available_extensions WHERE name = 'vector';"
```

Expected: a version string (e.g. `0.7.0`). If `NULL`: extension not installed in the image. The `docker-compose.yml` should use `pgvector/pgvector:pg16` — verify the image:

```bash
grep "image:" docker-compose.yml | grep -i postgres
```

If it's plain `postgres:16` without pgvector: replace with `pgvector/pgvector:pg16` and recreate the container.

## Step 4 — MinIO reachable

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:9000/minio/health/live
```

Expected: `200`. If not, MinIO container is down or misconfigured.

## Step 5 — .env sanity

```bash
grep "ConnectionStrings\|MINIO\|Port" .env
```

Confirm `Port=5433` (not default 5432) and MinIO credentials match docker-compose values. Stale `.env` from a different branch is a common source of connection failures after branch switches.

## When to run

- Start of any task that touches database, migrations, or file storage
- When `dotnet test` fails with `connection refused` or `no such host`
- When EF migrations fail on `database update`
- When file upload/download tests fail unexpectedly

## Not a code problem if

- `docker compose ps` shows a service is down → start it, not a bug
- pgvector extension missing → wrong Docker image, not a migration bug
- `.env` has wrong port → configuration drift, not a code bug
