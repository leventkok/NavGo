# Incident response

1. Contain: set `LLM_KILL_SWITCH=true`, revoke JWT secret if needed, disable MCP token.
2. Investigate audit logs and Render/Cloudflare logs.
3. Eradicate: patch, rotate secrets, re-deploy.
4. Notify: security@masterfabric.co / GitHub Security Advisory.
