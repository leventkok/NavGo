# Setup @cursor-security/mcp for local Cursor scans (one-time).
# Usage (PowerShell):  .\scripts\setup-cursor-security-mcp.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$dest = Join-Path $root "tools\cursor-security"

if (-not (Test-Path $dest)) {
  git clone --depth 1 https://github.com/gurkanfikretgunak/cursor-security.git $dest
}

Push-Location $dest
npm install
npm run build -w @cursor-security/mcp
Pop-Location

$mcpJs = Join-Path $dest "packages\cursor-security-mcp\dist\index.js"
Write-Host "Built MCP at: $mcpJs"
Write-Host "Add to .cursor/mcp.json (see docs/security/cursor-security-mcp.md)"
