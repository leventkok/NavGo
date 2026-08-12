# Deploy NavGo API on Render (Docker)

## Services

1. **PostgreSQL** — prefer a plan/image with **pgvector** (or enable the `vector` extension). Shared/staging data lives here.
2. **Web Service** — Docker runtime from this repo (Go API).
3. **Ollama (optional, private)** — CPU inference for Gemma. Same Render account, **private service** (not public). Expect ~15–40s per LLM call on CPU.

Local dev DB remains `deployments/docker-compose.yml` → `navgo-postgres`.

## Dockerfile (API)

Use [`deployments/Dockerfile`](../deployments/Dockerfile):

- Build context: repository root
- Dockerfile path: `deployments/Dockerfile`
- Port: `8080`

## Ollama private service (LLM)

Suggested setup:

1. Create a **Private Service** from Docker image `ollama/ollama` (or [`deployments/ollama/Dockerfile`](../deployments/ollama/Dockerfile)).
2. Attach a **persistent disk** at `/root/.ollama` (models survive restarts).
3. Prefer **≥4 GB RAM** for `gemma2:2b`.
4. After boot, pull once (Render shell / one-off job):

```bash
ollama pull gemma2:2b
```

5. Point the Web Service at the private hostname (example):

```env
LLM_BASE_URL=http://navgo-ollama:11434/v1
LLM_MODEL=gemma2:2b
LLM_API_KEY=
SERVER_WRITE_TIMEOUT_SECONDS=120
```

Do **not** expose Ollama publicly. Flutter talks only to the Go API.

CPU latency is acceptable for MVP; later swap `LLM_BASE_URL` to a GPU host or managed OpenAI-compatible API without changing mobile code.

## Required env vars

| Variable | Notes |
|----------|--------|
| `DB_HOST` / `DB_PORT` / `DB_USER` / `DB_PASSWORD` / `DB_NAME` | From Render Postgres |
| `DB_SSLMODE` | `require` in production |
| `JWT_SECRET` | Strong random secret (never default) |
| `CORS_ALLOWED_ORIGINS` | Comma-separated frontend origins (Vercel URL) |
| `GOOGLE_MAPS_API_KEY` | Empty → mock Places/Directions adapters |
| `LLM_BASE_URL` | Empty → `/api/v1/llm/*` disabled; local Ollama `http://127.0.0.1:11434/v1` |
| `LLM_MODEL` | Default `gemma2:2b` |
| `LLM_API_KEY` | Optional Bearer for managed providers |
| `SERVER_WRITE_TIMEOUT_SECONDS` | Default 120 (CPU LLM) |
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
