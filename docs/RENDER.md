# Deploy NavGo API on Render (Docker)

## Services

1. **PostgreSQL** — prefer a plan/image with **pgvector** (or enable the `vector` extension).
2. **Web Service** — Docker runtime from this repo.

## Dockerfile

Use [`deployments/Dockerfile`](../deployments/Dockerfile):

- Build context: repository root
- Dockerfile path: `deployments/Dockerfile`
- Port: `8080`

## Required env vars

| Variable | Notes |
|----------|--------|
| `DB_HOST` / `DB_PORT` / `DB_USER` / `DB_PASSWORD` / `DB_NAME` | From Render Postgres |
| `DB_SSLMODE` | `require` in production |
| `JWT_SECRET` | Strong random secret (never default) |
| `CORS_ALLOWED_ORIGINS` | Comma-separated frontend origins (Vercel URL) |
| `GOOGLE_MAPS_API_KEY` | Empty → mock Places/Directions adapters |
| `REDIS_HOST` / `REDIS_PORT` | Optional; API degrades if Redis missing |
| `KAFKA_ENABLED` | Keep `false` for MVP |

## Migrations

Run goose against Render Postgres before or on first deploy:

```bash
goose -dir internal/infrastructure/postgres/migrations postgres "$DATABASE_URL" up
```

Ensure `00013_enable_pgvector` succeeds (`CREATE EXTENSION vector`).

## Health

- Liveness: `GET /health/live`
- Readiness: `GET /health/ready`
