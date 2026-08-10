# NavGo Web (basic)

Next.js + `@mlc-ai/web-llm` (Gemma 2B) demo client.

## Flow

1. Load Gemma in the browser (WebGPU)
2. Gemma → intent JSON (`area`, `query`, …) — no fake `place_id`
3. `POST /api/v1/places/search` (Go API, mock Places for now)
4. Gemma picks indices from grounded list
5. `POST /api/v1/routes/build` + `POST /api/v1/itineraries`

## Run

```bash
# API (repo root)
$env:CORS_ALLOWED_ORIGINS="http://localhost:3000"
go run ./cmd/server

# Web
cd web
npm install
npm run dev
```

Open http://localhost:3000 — Chrome/Edge with WebGPU recommended.
First model download is ~1GB+.
