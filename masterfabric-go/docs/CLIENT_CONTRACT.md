# Client contract (grounded day plans)

Backend stores decisions and proxies Maps data. **LLM inference** may run:

- on the client (web-llm demo), or
- on the server via OpenAI-compatible proxy (`POST /api/v1/llm/*` → Ollama on Render / local)

Grounding rules (unchanged):

1. Parse user prompt → intent (`area`, `query`, `max_stops`, prefs) — client or `POST /api/v1/llm/parse-intent`.
2. `POST /api/v1/places/search` → grounded places with real `place_id` / lat/lng.
3. Select/order stops **only** from that list — client or `POST /api/v1/llm/pick-stops` (indices only).
4. `POST /api/v1/routes/build` with `place_ids`.
5. `POST /api/v1/itineraries` with grounded stops + route fields.

Ungrounded `place_id` → **422**.

If `LLM_BASE_URL` is unset, `/api/v1/llm/*` is disabled; Flutter falls back to preference templates.
