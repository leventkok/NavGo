# Client contract (web-llm demo + Flutter ship)

Backend is **LLM-agnostic**. Clients (Next.js `@mlc-ai/web-llm` or Flutter on-device MLC) must follow grounding:

1. Parse user prompt → intent (`area`, `duration`, prefs) locally.
2. `POST /api/v1/places/search` → grounded places with real `place_id` / lat/lng.
3. Client selects/orders stops **only** from that list.
4. `POST /api/v1/routes/build` with `place_ids`.
5. `POST /api/v1/itineraries` with grounded stops + route fields.

Ungrounded `place_id` → **422**.

Demo (web-llm) is not the quality gate; Flutter on-device Gemma is the ship path.
