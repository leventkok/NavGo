# Deploy NavGo API on Render (Docker)

## Services

1. **PostgreSQL** — Render Postgres (new account). Needs **pgvector** (`CREATE EXTENSION vector`).
2. **Web Service** — Docker runtime from this repo (Go API) on Render.
3. **LLM** — Colab + Cloudflare Tunnel OpenAI-compatible URL (`LLM_BASE_URL`). See [`deployments/cloudflare/CLOUDFLARE.md`](../deployments/cloudflare/CLOUDFLARE.md).
4. **Redis** — optional (Upstash or skip); API runs without it.

Local dev DB remains `deployments/docker-compose.yml` → `navgo-postgres`.

```text
Mobile → Render Web Service (Go) → Render Postgres
                                 → Colab LLM via Cloudflare HTTPS
```

## New Render account checklist

### 1) Postgres

1. Dashboard → **New** → **PostgreSQL** (region close to you / EU if possible).
2. Copy **Internal Database URL** (for the Web Service on Render) and **External Database URL** (for local goose from your PC).
3. In Render Shell / `psql` (or any SQL client on the External URL):

```sql
CREATE EXTENSION IF NOT EXISTS vector;
```

4. Migrate from your PC (use External URL; add `sslmode=require` if missing):

```bash
cd masterfabric-go
goose -dir internal/infrastructure/postgres/migrations postgres "$DATABASE_URL" up
```

Ensure `00013_enable_pgvector` (or equivalent) succeeds. If `vector` is unavailable on the plan, switch DB host or enable the extension per Render docs.

### 2) Web Service (Docker)

1. **New** → **Web Service** → connect this GitHub repo.
2. Runtime: **Docker**
   - Dockerfile path: `masterfabric-go/deployments/Dockerfile` (or set root to `masterfabric-go` and use `deployments/Dockerfile`)
   - Build context: directory that contains `go.mod` (usually `masterfabric-go`)
   - Port: `8080`
3. Attach env vars (below). Deploy.

### 3) LLM (Colab + Cloudflare) first

1. Open [`deployments/cloudflare/NavGo_Serve_Cloudflare.ipynb`](../deployments/cloudflare/NavGo_Serve_Cloudflare.ipynb) on Colab (T4 GPU).
2. Set `HF_TOKEN`, run all cells; keep the last cell running.
3. Copy printed `LLM_BASE_URL`, `LLM_MODEL`, `LLM_API_KEY` into the Web Service env.
4. After every Colab / quick-tunnel restart, update `LLM_BASE_URL` on Render (URL rotates unless you use a named tunnel).

## Required env vars (Web Service)

| Variable | Notes |
|----------|--------|
| `DB_HOST` / `DB_PORT` / `DB_USER` / `DB_PASSWORD` / `DB_NAME` | From Render Postgres (or parse from Internal URL) |
| `DB_SSLMODE` | `require` |
| `JWT_SECRET` | Strong random secret (never default) |
| `CORS_ALLOWED_ORIGINS` | Comma-separated frontend origins |
| `GOOGLE_MAPS_API_KEY` | Empty → mock Places/Directions adapters |
| `LLM_BASE_URL` | Cloudflare public URL **with** `/v1` suffix, e.g. `https://xxxx.trycloudflare.com/v1` |
| `LLM_MODEL` | `navgo-gemma` |
| `LLM_API_KEY` | Same key printed by the Colab notebook |
| `SERVER_WRITE_TIMEOUT_SECONDS` | `300` (Colab cold / long generate) |
| `REDIS_HOST` / `REDIS_PORT` | Optional; omit if unused |
| `KAFKA_ENABLED` | Keep `false` for MVP |

## Dockerfile (API)

Use [`deployments/Dockerfile`](../deployments/Dockerfile):

- Build context: `masterfabric-go` (repository module root with `go.mod`)
- Dockerfile path: `deployments/Dockerfile`
- Port: `8080`

## Health

- Liveness: `GET /health/live`
- Readiness: `GET /health/ready`

## Mobile

Point Flutter `baseUrl` at the Render public HTTPS API (not `10.0.2.2` / localhost).

## Local Ollama (optional)

For offline API work without Colab:

```env
LLM_BASE_URL=http://127.0.0.1:11434/v1
LLM_MODEL=gemma2:2b
LLM_API_KEY=
```

Do **not** expose Ollama publicly. Flutter talks only to the Go API.

## Migrations reminder

Re-run goose when new SQL files appear under `internal/infrastructure/postgres/migrations`:

```bash
goose -dir internal/infrastructure/postgres/migrations postgres "$DATABASE_URL" up
```
