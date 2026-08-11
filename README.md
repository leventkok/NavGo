# NavGo

Monorepo for grounded travel day-plans.

| Package | Role |
|---------|------|
| [`masterfabric-go/`](masterfabric-go/) | Go API — Places, Routes, itineraries, IAM |
| [`frontend/`](frontend/) | Next.js + browser Gemma (web-llm) |
| [`mobile/`](mobile/) | Flutter day-planner client |

LLM runs on the client (browser / later on-device MLC). The API stores decisions and talks to Google Places/Routes.

Same licensing posture as [mlc-llm-monitoring](https://github.com/leventkok/mlc-llm-monitoring) (no root LICENSE). See [`masterfabric-go/NOTICE`](masterfabric-go/NOTICE).

## Quick start

### Backend

```bash
cd masterfabric-go
make docker-up
make migrate
# set GOOGLE_MAPS_API_KEY optionally
make run
```

### Frontend

```bash
cd frontend
cp .env.local.example .env.local
npm install
npm run dev
```

Open http://localhost:3000 — API via same-origin `/navgo-api` proxy.

### Mobile

```bash
cd mobile
flutter pub get
flutter run
```

Default API base: `http://10.0.2.2:8080` on Android emulator (`localhost` on iOS sim / desktop).

## Docs

- API contract: [`masterfabric-go/docs/CLIENT_CONTRACT.md`](masterfabric-go/docs/CLIENT_CONTRACT.md)
- MCP: [`masterfabric-go/docs/MCP.md`](masterfabric-go/docs/MCP.md)
- Render: [`masterfabric-go/docs/RENDER.md`](masterfabric-go/docs/RENDER.md)
