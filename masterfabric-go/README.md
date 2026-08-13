# NavGo API (`masterfabric-go`)

![Version](https://img.shields.io/badge/version-0.1.0-blue.svg)
![Go Version](https://img.shields.io/badge/go-1.26.4-00ADD8?logo=go)

Go backend for grounded travel day-plans: Places search, day routes, and itinerary persistence. Optional **LLM proxy** (`/api/v1/llm/*`) talks to OpenAI-compatible upstream (local Ollama, or Colab + Cloudflare Tunnel in prod). Web still has a web-llm demo; Flutter calls the API (with preference-template fallback if LLM is off).

Same licensing posture as [mlc-llm-monitoring](https://github.com/leventkok/mlc-llm-monitoring) (no root LICENSE). Platform patterns adapted from [masterfabric-go](https://github.com/gurkanfikretgunak/masterfabric-go) — see [NOTICE](NOTICE).

## Architecture

- Clean / hexagonal layers (`domain` → `application` → `infrastructure` / `gateway`)
- Platform modules: IAM, Tenant, API Management, Audit, WebSocket
- **Trip** bounded context: Google-shaped `PlacesClient` / `DirectionsClient`, mock or Google adapters, **pgvector** place cache, itineraries
- **LLM** helpers: `parse-intent` + `pick-stops` (indices only; no invented `place_id`)
- **MCP server** (`cmd/mcp`) shares the same application services as HTTP

## Quick Start

### Prerequisites

- Go 1.26.4+
- Docker & Docker Compose
- (Optional) `goose` CLI
- (Optional) [Ollama](https://ollama.com) + `ollama pull gemma2:2b`

### Infra + server

```bash
make docker-up
make migrate
# Put secrets in masterfabric-go/.env (gitignored), e.g.:
#   GOOGLE_MAPS_API_KEY=...
#   LLM_BASE_URL=http://127.0.0.1:11434/v1
#   LLM_MODEL=gemma2:2b
make run
```

Health:

```bash
curl http://localhost:8080/health/live
curl http://localhost:8080/health/ready
```

### Trip API (JWT required)

```bash
curl -s -X POST http://localhost:8080/api/v1/places/search \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"query":"gezilecek yerler","area":"Kaleiçi Antalya","max_results":5}'

curl -s -X POST http://localhost:8080/api/v1/routes/build \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"place_ids":["ChIJ...","ChIJ..."],"optimize_waypoint_order":true}'
```

### LLM helpers (optional)

```bash
curl -s -X POST http://localhost:8080/api/v1/llm/parse-intent \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"prompt":"Kadıköyde yarım gün gezmek istiyorum","default_area":"İstanbul"}'
```

Grounding contract: [docs/CLIENT_CONTRACT.md](docs/CLIENT_CONTRACT.md)

### Frontend / mobile clients

See repo root [README](../README.md). Frontend docs: [../frontend/README.md](../frontend/README.md).

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
| Places/Directions | Mock, or Google when `GOOGLE_MAPS_API_KEY` set |
| LLM | OpenAI-compatible (`LLM_BASE_URL`): Ollama locally, Colab+Cloudflare in prod (`navgo-gemma`) |

## License

No root LICENSE (same as [mlc-llm-monitoring](https://github.com/leventkok/mlc-llm-monitoring)). See [NOTICE](NOTICE).
