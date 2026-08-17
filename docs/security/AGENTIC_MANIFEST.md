# NavGo Agentic Security Manifest

Adapted from [cursor-security MANIFEST.md](https://github.com/gurkanfikretgunak/cursor-security/blob/main/MANIFEST.md) (attribution: Gürkan Fikret Günak / Cursor Security). Educational patterns applied to NavGo’s Go API, Flutter client, Colab LLM, and MCP tools.

## Purpose

NavGo agents do not only answer. They plan trips, call Places/Directions, persist itineraries, and invoke LLM upstreams. Security covers intent, capability, memory, and action — not only the model prompt.

## Principles (NavGo)

1. **Least agency** — Fixed trip/LLM tools only; no open shell; prefer draft itinerary over silent external side effects.
2. **Identity before action** — Handshake → login → bind → blended JWT; MCP uses `MCP_SERVICE_TOKEN` + bound `MCP_USER_ID`.
3. **Tool trust is zero by default** — Pin MCP/server deps; review Cloudflare/Colab egress; treat tool args as untrusted.
4. **Prompt is not policy** — AuthZ in Chi middleware / use cases; never trust LLM or MCP args for `user_id` / `org_id`.
5. **Human control for high impact** — Destructive admin and production kill switches require operator action (`LLM_KILL_SWITCH`).
6. **Observable by design** — Audit handshake, bind, channel deny, LLM, and trip mutations.
7. **Memory is sensitive** — Places cache / pgvector / itineraries are tenant-scoped confidential data.
8. **Contain blast radius** — Rate limits on auth/LLM; body caps; LLM timeouts; kill switch.
9. **Evaluate adversarially** — Injection fixtures and MCP abuse checks in `docs/security/adversarial-runbook.md`.
10. **Ship with ownership** — Named owner for Render API, Colab tunnel, and mobile releases.

## Minimum controls

| Control | NavGo expectation |
| --- | --- |
| AuthN / AuthZ | Handshake + blended channel JWT; RBAC on admin |
| Sandbox | MCP/LLM without host shell; Colab isolated from DB |
| Network | API egress to Maps + `llm.nomagent.com` only as configured |
| Secrets | Env/vault; never in prompts by default |
| Approvals | Kill switch + admin RBAC for high impact |
| Audit | Append-only `audit_logs` + security scan ingest |
| Kill switch | `LLM_KILL_SWITCH=true` / Redis flag |

## Commitment

Capability grows only as fast as verification, observability, and human accountability.
