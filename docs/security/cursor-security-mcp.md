# Cursor Security MCP (repo scanner)

One-time setup:

```powershell
.\scripts\setup-cursor-security-mcp.ps1
```

Then merge into `.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "cursor-security": {
      "command": "node",
      "args": ["${workspaceFolder}/tools/cursor-security/packages/cursor-security-mcp/dist/index.js"]
    }
  }
}
```

`tools/cursor-security` is gitignored (clone locally). Run in chat: “Run a full security scan on this repo”.

Baseline findings: write triage notes to `docs/security/findings-baseline.md` after first scan.
