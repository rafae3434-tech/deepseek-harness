#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

graphify_path="${GRAPHIFY_PATH:-scripts}"
graphify_out="${GRAPHIFY_OUT:-.}"
timeout_s="${GRAPHIFY_TIMEOUT:-180}"

# Code is extracted locally with ASTs and never needs an API key. This is the
# default route so Graphify remains useful and free even when cloud providers
# are unavailable. It also avoids scanning encrypted office test fixtures.
if [[ "${GRAPHIFY_MODE:-code}" == "code" ]]; then
  timeout "${timeout_s}s" graphify extract "$graphify_path" \
    --code-only --no-cluster --max-workers "${GRAPHIFY_MAX_WORKERS:-2}" \
    --out "$graphify_out"
  timeout "${GRAPHIFY_CLUSTER_TIMEOUT:-90}s" graphify cluster-only "$graphify_out" \
    --no-viz --no-label
  exit 0
fi

if [[ ! -f .env && ! -p .env ]]; then
  echo "BLOCKED: missing 1Password-managed .env for semantic mode" >&2
  exit 2
fi

set -a
. "$ROOT/.env"
set +a

provider="${GRAPHIFY_PROVIDER:-gemini}"
case "$provider" in
  gemini)
    : "${GEMINI_API_KEY_1:?GEMINI_API_KEY_1 is unavailable}"
    export GEMINI_API_KEY="$GEMINI_API_KEY_1"
    exec timeout "$timeout_s" graphify extract "$graphify_path" \
      --backend gemini --model "${GRAPHIFY_MODEL:-gemini-3-flash-preview}" \
      --no-viz --no-cluster --api-timeout "${GRAPHIFY_API_TIMEOUT:-90}"
    ;;
  openrouter-free)
    : "${OPENROUTER_API_KEY_1:?OPENROUTER_API_KEY_1 is unavailable}"
    export OPENAI_API_KEY="$OPENROUTER_API_KEY_1"
    export OPENAI_BASE_URL="https://openrouter.ai/api/v1"
    export OPENAI_MODEL="${GRAPHIFY_MODEL:-cohere/north-mini-code:free}"
    exec timeout "$timeout_s" graphify extract "$graphify_path" \
      --backend openai --model "$OPENAI_MODEL" --no-viz --no-cluster \
      --api-timeout "${GRAPHIFY_API_TIMEOUT:-90}"
    ;;
  *)
    echo "FAIL: unsupported GRAPHIFY_PROVIDER=$provider" >&2
    exit 2
    ;;
esac
