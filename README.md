# NavGo

![Version](https://img.shields.io/badge/version-0.1.0-blue.svg)
![Go Version](https://img.shields.io/badge/go-1.26.4-00ADD8?logo=go)

**NavGo** is a Go backend for grounded travel day-plans: Places search, day routes, and itinerary persistence. LLM inference runs on the client (browser web-llm demo / Flutter on-device MLC); this API stores decisions and proxies Maps data.

Same licensing posture as [mlc-llm-monitoring](https://github.com/leventkok/mlc-llm-monitoring) (no root LICENSE). Platform patterns adapted from [masterfabric-go](https://github.com/gurkanfikretgunak/masterfabric-go) — see [NOTICE](NOTICE).

## Architecture

- Clean / hexagonal layers (`domain` → `application` → `infrastructure` / `gateway`)
- Platform modules from masterfabric-go: IAM, Tenant, API Management, Audit, WebSocket
- **Trip** bounded context: Google-shaped `PlacesClient` / `DirectionsClient`, mock adapters, **pgvector** place cache, itineraries
- **MCP server** (`cmd/mcp`) shares the same application services as HTTP

## Quick Start

### Prerequisites

- Go 1.26.4+
- Docker & Docker Compose
- (Optional) `goose` CLI

### Infra + server

```bash
# Postgres (pgvector) + Redis
make docker-up

# Migrations
make migrate

# API
make run
```

Health:

```bash
curl http://localhost:8080/health/live
curl http://localhost:8080/health/ready
```

### Trip API (JWT required)

```bash
# After register/login → Bearer token
curl -s -X POST http://localhost:8080/api/v1/places/search \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"query":"gezilecek yerler","area":"Kaleiçi Antalya","max_results":5}'

curl -s -X POST http://localhost:8080/api/v1/routes/build \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"place_ids":["ChIJkaleici_hadrian_gate","ChIJkaleici_old_harbor"],"optimize_waypoint_order":true}'
```

Grounding contract: [docs/CLIENT_CONTRACT.md](docs/CLIENT_CONTRACT.md)

### Web demo (Gemma in browser)

```bash
# Terminal A — API with CORS for Next.js
$env:CORS_ALLOWED_ORIGINS="http://localhost:3000"
$env:DB_HOST="127.0.0.1"
go run ./cmd/server

# Terminal B — web
cd web
npm install
npm run dev
```

Open http://localhost:3000 → **Gemma 2B yükle** → prompt → **Günü planla**.  
Requires WebGPU (Chrome/Edge). Docs: [web/README.md](web/README.md)

### MCP

```bash
go run ./cmd/mcp
```

Docs: [docs/MCP.md](docs/MCP.md)

### Render

See [docs/RENDER.md](docs/RENDER.md).

## Tech stack

| Component | Technology |
|-----------|------------|
| Language | Go 1.26.4 |
| HTTP | Chi |
| DB | PostgreSQL 16 + pgvector |
| Cache | Redis 7 |
| Auth | JWT |
| MCP | mark3labs/mcp-go (stdio) |
| Places/Directions | Mock now → Google when `GOOGLE_MAPS_API_KEY` set |

## License

No root LICENSE (same as [mlc-llm-monitoring](https://github.com/leventkok/mlc-llm-monitoring)). See [NOTICE](NOTICE).
