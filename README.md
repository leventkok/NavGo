# NavGo

![Version](https://img.shields.io/badge/version-0.1.0-blue.svg)
![Go Version](https://img.shields.io/badge/go-1.26.4-00ADD8?logo=go)
![License](https://img.shields.io/badge/license-AGPL--v3.0-green.svg)

**NavGo** is a Go backend for grounded travel day-plans: Places search, day routes, and itinerary persistence. LLM inference runs on the client (browser web-llm demo / Flutter on-device MLC); this API stores decisions and proxies Maps data.

Derived from [masterfabric-go](https://github.com/gurkanfikretgunak/masterfabric-go) (AGPL-3.0). See [NOTICE](NOTICE) and [LICENSE](LICENSE).

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

AGPL-3.0 — see [LICENSE](LICENSE) and [NOTICE](NOTICE).
