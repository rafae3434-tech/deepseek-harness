#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

if [[ ! -f .env && ! -p .env ]]; then
  echo "Missing 1Password-managed .env at $ROOT/.env" >&2
  exit 2
fi

if [[ ! -f .env.huggingface && ! -p .env.huggingface ]]; then
  echo "Missing 1Password-managed Hugging Face env at $ROOT/.env.huggingface" >&2
  exit 2
fi

set -a
. "$ROOT/.env"
. "$ROOT/.env.huggingface"
set +a

export DSH_HOME="$ROOT/.dsh-home"
exec node --import tsx/esm apps/cli/src/bin.ts web --no-open "$@"
