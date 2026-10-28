#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ ! -p .env && ! -f .env ]]; then
  echo "BLOCKED: missing 1Password-managed .env" >&2
  exit 2
fi

set -a
. "$ROOT/.env"
set +a

route() {
  local label="$1" url="$2" key="$3" model="$4"
  local out status
  out="$(mktemp /tmp/dsh-route.XXXXXX)"
  status="$(curl -sS -o "$out" -w '%{http_code}' --max-time 20 "$url" \
    -H "Authorization: Bearer $key" \
    -H 'Content-Type: application/json' \
    --data-binary "$(printf '{\"model\":\"%s\",\"messages\":[{\"role\":\"user\",\"content\":\"Reply with exactly OK.\"}],\"max_tokens\":8,\"temperature\":0}' "$model")" || true)"
  rm -f "$out"
  if [[ "$status" =~ ^2 ]]; then
    printf '%s %s\n' "$label" "$model"
    return 0
  fi
  return 1
}

route abliteration https://api.abliteration.ai/v1/chat/completions "${Abliteracion:-}" abliterated-model-large-flash && exit 0
route nvidia https://integrate.api.nvidia.com/v1/chat/completions "${NVIDIA_API_KEY_1:-}" nvidia/nemotron-3.5-lightning-30b-a3b && exit 0
route groq https://api.groq.com/openai/v1/chat/completions "${GROQ_API_KEY_1:-}" openai/gpt-oss-20b && exit 0
route openrouter https://openrouter.ai/api/v1/chat/completions "${OPENROUTER_API_KEY_1:-}" nvidia/nemotron-3.5-lightning:free && exit 0

echo "FAIL: no healthy provider in bounded fallback order" >&2
exit 1
