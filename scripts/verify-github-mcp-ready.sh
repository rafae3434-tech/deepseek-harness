#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$ROOT/ops/orca/github-mcp.yaml"

[[ -f "$CONFIG" ]] || { echo "FAIL github-mcp-config"; exit 1; }
grep -q '^secret_ref: GITHUB_PERSONAL_ACCESS_TOKEN$' "$CONFIG"
grep -q 'api.githubcopilot.com/mcp/x/all/readonly' "$CONFIG"
grep -q 'access: read-only' "$CONFIG"
grep -q '^    - deepseek-harness$' "$CONFIG"

if grep -RInE '(^|[^A-Za-z])(gh[pousr]_[A-Za-z0-9_]+|github_pat_[A-Za-z0-9_]+|Bearer[[:space:]]+[A-Za-z0-9._-]{20,})' "$ROOT/ops/orca" >/dev/null 2>&1; then
  echo "FAIL github-mcp-secret-literal"
  exit 1
fi

echo "PASS github-mcp-config"
if [[ -p "$ROOT/.env" || -f "$ROOT/.env" ]]; then
  set -a
  . "$ROOT/.env"
  set +a
fi
if [[ -n "${GITHUB_PERSONAL_ACCESS_TOKEN:-}" ]]; then
  echo "PASS github-mcp-token-in-1password"
else
  echo "PENDING github-mcp-token-in-1password"
  exit 2
fi
echo "INFO secret_ref=GITHUB_PERSONAL_ACCESS_TOKEN"
