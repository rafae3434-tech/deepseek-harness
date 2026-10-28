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
set +a

provider="${GRAPHIFY_PROVIDER:-openrouter-free}"
case "$provider" in
  openrouter-free)
    : "${OPENROUTER_API_KEY_1:?OPENROUTER_API_KEY_1 is unavailable}"
    export OPENAI_API_KEY="$OPENROUTER_API_KEY_1"
    export OPENAI_BASE_URL="https://openrouter.ai/api/v1"
    export OPENAI_MODEL="${GRAPHIFY_MODEL:-cohere/north-mini-code:free}"
    exec timeout "${GRAPHIFY_TIMEOUT:-120}s" graphify ops/orca --backend openai --model "$OPENAI_MODEL" --no-viz --no-cluster
    ;;
  gemini)
    : "${GEMINI_API_KEY_1:?GEMINI_API_KEY_1 is unavailable}"
    export GEMINI_API_KEY="$GEMINI_API_KEY_1"
    exec timeout "${GRAPHIFY_TIMEOUT:-120}s" graphify ops/orca --backend gemini --model "${GRAPHIFY_MODEL:-gemini-3-flash-preview}" --no-viz --no-cluster
    ;;
  *)
    echo "FAIL: unsupported GRAPHIFY_PROVIDER=$provider" >&2
    exit 2
    ;;
esac
