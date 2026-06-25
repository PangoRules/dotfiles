---
name: docker-preflight
description: Use at the start of any dev task or when tests fail with connection errors — verifies docker-compose services are up and healthy before assuming code is broken.
---

# Docker Preflight

Missing or unhealthy Docker services produce errors that look like code bugs: connection refused, no such host, migration failures, file storage errors. Run this first before debugging any infrastructure-related failure.

## Step 1 — Services running

```bash
docker compose ps
```

All services should show `running` or `healthy`. If any show `exited` or `starting`:

```bash
docker compose up -d
```

Wait a few seconds, then re-check `docker compose ps`.

## Step 2 — Database reachable

```bash
pg_isready -h localhost -p <port>
```

Expected: `localhost:<port> - accepting connections`

If `pg_isready` isn't on PATH:
```bash
docker compose exec <postgres-service-name> pg_isready -U <user>
```

Check your `docker-compose.yml` for the actual port — many projects use a non-default port (e.g. `5433`) to avoid conflicts with a local Postgres install.

## Step 3 — pgvector extension installed (if project uses pgvector)

```bash
docker compose exec <postgres-service-name> psql -U <user> -d <database> -c \
  "SELECT installed_version FROM pg_available_extensions WHERE name = 'vector';"
```

Expected: a version string (e.g. `0.7.0`). If `NULL`: extension not in the image.

Verify the image in `docker-compose.yml`:
```bash
grep "image:" docker-compose.yml | grep -i postgres
```

Must be `pgvector/pgvector:pg<version>` (e.g. `pgvector/pgvector:pg16`), not plain `postgres:<version>`. If wrong: update the image and recreate the container:

```bash
docker compose down
# update image in docker-compose.yml
docker compose up -d
```

## Step 4 — Object storage reachable (if project uses MinIO/S3)

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:<minio-port>/minio/health/live
```

Expected: `200`. Check your `docker-compose.yml` for the actual port.

## Step 5 — Environment file sanity

```bash
grep -i "connection\|port\|host\|endpoint" .env
```

Confirm the ports and credentials in `.env` match what's in `docker-compose.yml`. Stale `.env` from a different branch is a common source of connection failures after a branch switch.

## When to run

- Start of any task touching database, migrations, or file/object storage
- When `dotnet test` or any test suite fails with `connection refused` or `no such host`
- When EF Core `database update` fails unexpectedly
- When file upload/download tests fail without a clear code reason
- After switching branches (`.env` or `docker-compose.yml` may have changed)

## This is not a code bug if

- `docker compose ps` shows a service is down → `docker compose up -d`, not a code fix
- pgvector extension missing → wrong Docker image tag, not a migration bug
- `.env` has wrong port or credential → configuration drift, not a code bug
- Service shows `starting` → wait for health check, not a code bug
