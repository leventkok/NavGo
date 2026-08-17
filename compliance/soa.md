# Statement of Applicability (starter)

| Control area | Applicable | Notes |
| --- | --- | --- |
| Access control | Yes | JWT + RBAC + channel bind |
| Cryptography / secrets | Yes | Env secrets; HS256 JWT (accepted risk documented) |
| Operations security | Yes | Render + CI scans |
| Communications security | Yes | TLS at edge; HSTS when TLS terminated at app |
| Supplier relationships | Yes | Render, Cloudflare, Maps, HF |
| Incident management | Yes | See policies/incident-response.md |
| AI / agent controls | Yes | Manifest + kill switch + MCP identity |
