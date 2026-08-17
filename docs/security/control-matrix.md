# NavGo Control Matrix

Links ASVS / LLM Top 10 themes to code. Attribution: cursor-security control-matrix pattern.

| Theme | Control | NavGo path | Status |
| --- | --- | --- | --- |
| ASVS V2 AuthN | Handshake + login + bind | `internal/application/security/usecase`, `/api/v1/auth/*` | Implemented |
| ASVS V3 Session | Device / blended JWT kinds | `internal/infrastructure/auth/jwt_service.go` | Implemented |
| ASVS V4 Access | Channel verify + RBAC | `middleware/channel.go`, `RequirePermission` | Implemented |
| ASVS V4 Tenant | Org header bind | `middleware/tenant.go` | Implemented |
| ASVS V7 Logging | Audit middleware + typed events | `middleware/audit.go` | Implemented |
| ASVS V11 DoS | Auth/LLM rate limit | `middleware/rate_limit.go` | Implemented |
| ASVS V14.4 Headers | Security headers | `middleware/security_headers.go`, `frontend/next.config.ts` | Implemented |
| LLM01 Injection | Schema + grounded places | `application/llm`, `application/trip` | Partial |
| LLM02 Sensitive data | No secrets in prompts | LLM use case / env | Partial |
| LLM08 Excessive agency | Fixed tools; MCP identity | `cmd/mcp` | Implemented |
| SC-01…19 | Platform registry | `masterfabric-go/SECURITY.md` | Implemented |
| CI verify | govulncheck / gosec / gitleaks | `.github/workflows/security.yml` | Implemented |
| Kill switch | LLM disable | `LLM_KILL_SWITCH`, LLM handler | Implemented |
| Scans ingest | MCP/CLI reports | `/api/v1/security/scans` | Implemented |
