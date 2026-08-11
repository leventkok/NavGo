# NavGo MCP Server

NavGo exposes an MCP (Model Context Protocol) server over **stdio** so Cursor / agents can call the same trip application services as the HTTP API (no duplicated business logic).

## Tools

| Tool | Purpose |
|------|---------|
| `search_places` | Grounded Places search (Google-shaped DTOs) |
| `build_day_route` | Directions from grounded `place_id`s |
| `save_itinerary` | Persist a client decision (validates grounding) |
| `get_itinerary` | Fetch by id |
| `list_itineraries` | List by user |
| `plan_day` | Orchestrates search + route (+ optional save) |

## Run

Postgres must be up and migrations applied (`places_cache`, `itineraries`).

```bash
# from repo root
export DB_HOST=localhost DB_USER=navgo DB_PASSWORD=navgo DB_NAME=navgo
go run ./cmd/mcp
```

## Cursor config

Add to `.cursor/mcp.json` (or Cursor Settings → MCP):

```json
{
  "mcpServers": {
    "navgo": {
      "command": "go",
      "args": ["run", "./cmd/mcp"],
      "cwd": "${workspaceFolder}",
      "env": {
        "DB_HOST": "localhost",
        "DB_USER": "navgo",
        "DB_PASSWORD": "navgo",
        "DB_NAME": "navgo"
      }
    }
  }
}
```

## Grounding rule

LLM output must not invent `place_id`. Always `search_places` first, then route/save using returned ids.
