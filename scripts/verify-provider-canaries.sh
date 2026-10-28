#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
set -a
. "$ROOT/.env"
set +a

run_canary() {
  local label="$1" url="$2" key="$3" model="$4"
  local out="/tmp/dsh-provider-canary-${label}.json"
  local status
  status="$(curl -sS -o "$out" -w '%{http_code}' --max-time 60 "$url" \
    -H "Authorization: Bearer $key" \
    -H 'Content-Type: application/json' \
    --data-binary "$(printf '{\"model\":\"%s\",\"messages\":[{\"role\":\"user\",\"content\":\"Reply with exactly OK.\"}],\"max_tokens\":8,\"temperature\":0}' "$model")" || true)"
  if [[ "$status" == 2* ]] && grep -q '"choices"' "$out"; then
    echo "PASS: $label chat completion"
  else
    echo "FAIL: $label chat completion (HTTP $status; provider policy/quota/model may need adjustment)"
  fi
}

run_canary Abliteration https://api.abliteration.ai/v1/chat/completions "$Abliteracion" abliterated-model-large-flash
run_canary OpenRouter https://openrouter.ai/api/v1/chat/completions "$OPENROUTER_API_KEY_1" nvidia/nemotron-3.5-lightning:free
run_canary Groq https://api.groq.com/openai/v1/chat/completions "$GROQ_API_KEY_1" openai/gpt-oss-20b
run_canary NVIDIA https://integrate.api.nvidia.com/v1/chat/completions "$NVIDIA_API_KEY_1" nvidia/nemotron-3.5-lightning-30b-a3b
