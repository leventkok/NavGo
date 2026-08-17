# Launch checklist (≈3 days)

## Must do before prod traffic

1. Render Postgres: run goose migrations through **00017** (`auth_handshakes`, `security_scans`, `auth_magic_links`).
2. Set env on `navgo-api`:
   - `JWT_SECRET` (strong, unique)
   - `REQUIRE_AUTH_HANDSHAKE=true`
   - `REQUIRE_BLENDED_SENSITIVE=true`
   - `APP_ENV=production`
   - `LLM_KILL_SWITCH=false`
   - `LLM_*`, `GOOGLE_MAPS_API_KEY`, `DB_SSLMODE=require`
3. Mobile **prod** build:
   - `flutter pub get`
   - `--dart-define=NAVGO_USER_EMAIL=... --dart-define=NAVGO_USER_PASSWORD=...`
   - Do **not** ship with `NAVGO_ALLOW_DEMO=true`
4. Frontend: `NEXT_PUBLIC_ALLOW_DEMO_AUTH` unset/false; set real user env or login flow.
5. MCP (if used): real `MCP_USER_ID` + `MCP_REQUIRE_TOKEN=true` + matching tokens.
6. Optional: `.\scripts\setup-cursor-security-mcp.ps1` then first scan → `docs/security/findings-baseline.md`.
7. Kill switch drill: `LLM_KILL_SWITCH=true` or Redis `SET navgo:llm_kill_switch 1`.

## Auth client flow (all production clients)

`POST /auth/handshake` → `POST /auth/login|register` (with `handshake_id`) → `POST /auth/bind` → use **blended** token for trip/LLM.
