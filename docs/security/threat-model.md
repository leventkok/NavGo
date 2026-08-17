# NavGo Threat Model

Mapped from cursor-security `compliance/threat-model.md` patterns to NavGo.

## Assets

- User identity / JWT secrets (`JWT_SECRET`)
- Session tokens (user, device, blended)
- Organization / app tenancy
- Trip itineraries and Places cache
- LLM API key + Colab tunnel endpoint
- Google Maps API key
- Audit logs and security scan reports

## Trust boundaries

```text
Flutter / Next (untrusted)
    → NavGo Go API (AuthZ / audit / rate limit)
        → Postgres
        → LLM (llm.nomagent.com / Colab)
        → Google Maps
MCP stdio client (semi-trusted host)
    → cmd/mcp (must bind identity via env, not tool args)
```

## Abuse cases

| ID | Abuse case | Mitigation |
| --- | --- | --- |
| T1 | Session theft / token replay | Blended JWT (user+device+barrier); short TTL; secure storage on mobile |
| T2 | Tenant header IDOR | Header org must match JWT org when claim present |
| T3 | Handshake / login stuffing | Auth rate limit preset |
| T4 | Channel path confusion | `VerifyChannelAccess` on `/api/v1/c/{channelId}` |
| T5 | MCP confused deputy | `MCP_SERVICE_TOKEN` + forced `MCP_USER_ID`; ignore client `user_id` |
| T6 | Itinerary IDOR | Owner check on get |
| T7 | Prompt injection → tool abuse | No open tools; grounded `place_id` validation |
| T8 | LLM cost runaway | Timeouts + rate limit + `LLM_KILL_SWITCH` |
| T9 | Secret leakage | gitignore; CI secret scan; redact audit metadata |
| T10 | Audit tampering | Append-only inserts; no public update/delete |
