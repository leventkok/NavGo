# Risk register (starter)

| ID | Risk | Likelihood | Impact | Treatment |
| --- | --- | --- | --- | --- |
| R1 | Stolen JWT / session replay | M | H | Handshake + blended channel JWT; mobile secure storage |
| R2 | MCP confused deputy | M | H | MCP_USER_ID + token; no tool-arg identity |
| R3 | Prompt injection | H | M | Schema + grounded places; no open tools |
| R4 | LLM cost runaway | M | M | Rate limit + kill switch + timeouts |
| R5 | Secret leak in repo/logs | M | H | gitignore; gitleaks CI; redact audit |
| R6 | Tenant header IDOR | L | H | Org header must match JWT claim |
