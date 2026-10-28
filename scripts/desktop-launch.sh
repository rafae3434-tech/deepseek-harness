#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="$ROOT/.dsh-home"
mkdir -p "$STATE_DIR"
chmod 700 "$STATE_DIR"

# Harness issues a fresh browser token at startup. If an old local instance is
# listening, stop only that loopback listener so the browser receives a valid
# authenticated URL from the new process.
listener_pid="$(ss -ltnp 2>/dev/null | awk '/127\.0\.0\.1:3080/ { match($0, /pid=[0-9]+/); if (RSTART) { print substr($0, RSTART + 4, RLENGTH - 4); exit } }')"
if [[ "$listener_pid" =~ ^[0-9]+$ ]]; then
  kill "$listener_pid" 2>/dev/null || true
  for _ in {1..10}; do
    kill -0 "$listener_pid" 2>/dev/null || break
    sleep 1
  done
fi

exec setsid "$ROOT/run-local.sh"
