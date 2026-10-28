#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ ! -f .env && ! -p .env ]]; then
  echo "BLOCKED: missing 1Password-managed .env" >&2
  exit 2
fi

set -a
. "$ROOT/.env"
. "$ROOT/.env.huggingface"
set +a

fail=0
check_secret() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "FAIL: $name is unavailable"
    fail=1
  else
    echo "PASS: $name is available (value withheld)"
  fi
}

check_secret Abliteracion
check_secret Fireclaw
check_secret HUGGINGFACE_API_KEY_1

if [[ -x tools/bin/nuclei ]]; then
  echo "PASS: project-local Nuclei binary present"
  tools/bin/nuclei -version 2>&1 | sed -E 's/[[:space:]]+$//' | head -3
else
  echo "FAIL: project-local Nuclei binary missing"
  fail=1
fi

if curl --fail --silent --show-error --max-time 20 \
  -H "Authorization: Bearer $Abliteracion" \
  https://api.abliteration.ai/v1/models \
  | python3 -c 'import json,sys; d=json.load(sys.stdin); ids={x.get("id") for x in d.get("data", [])}; wanted="abliterated-model-large-flash"; print("PASS: Abliteration model list reachable; requested model present" if wanted in ids else "FAIL: requested model missing from Abliteration model list"); raise SystemExit(0 if wanted in ids else 1)'; then
  :
else
  echo "FAIL: Abliteration /v1/models check failed"
  fail=1
fi

if curl --fail --silent --show-error --max-time 20 \
  -X POST https://mcp.firecrawl.dev/v2/mcp \
  -H "Authorization: Bearer $Fireclaw" \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  --data '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"deepseek-harness-local-check","version":"1.0.0"}}}' \
  | rg -q 'result|protocolVersion'; then
  echo "PASS: Firecrawl MCP initialize reachable"
else
  echo "FAIL: Firecrawl MCP initialize check failed"
  fail=1
fi

echo "INFO: Playwright MCP is verified during harness startup via stdio discovery."
exit "$fail"
