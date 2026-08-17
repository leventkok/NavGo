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

## Identity (AuthZ outside the prompt)

MCP does **not** accept `user_id` from tool arguments. Configure:

| Env | Purpose |
| --- | --- |
| `MCP_USER_ID` | Required UUID bound to all save/list/plan operations |
| `MCP_SERVICE_TOKEN` | Optional shared secret |
| `MCP_EXPECTED_TOKEN` | If set, must match `MCP_SERVICE_TOKEN` |
| `MCP_REQUIRE_TOKEN` | `true` to refuse start without token |

```bash
# from repo root / masterfabric-go
export DB_HOST=localhost DB_USER=navgo DB_PASSWORD=navgo DB_NAME=navgo
export MCP_USER_ID=00000000-0000-0000-0000-000000000001
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
