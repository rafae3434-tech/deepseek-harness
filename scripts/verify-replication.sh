#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0
BLOCKED=0

pass() { PASS=$((PASS + 1)); printf 'PASS %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s\n' "$1"; }
blocked() { BLOCKED=$((BLOCKED + 1)); printf 'BLOCKED %s\n' "$1"; }

for path in \
  ops/orca/agents.yaml \
  ops/orca/policy.yaml \
  ops/orca/replication.yaml \
  run-local.sh \
  scripts/verify-orca-harness.sh \
  scripts/verify-local-connections.sh \
  scripts/tailscale-orca-status.sh; do
  [[ -f "$ROOT/$path" ]] && pass "file:$path" || fail "file:$path"
done

for path in ops/orca/workers.yaml scripts/verify-framework-workers.sh scripts/rea-ghidra-env.sh; do
  [[ -f "$ROOT/$path" ]] && pass "file:$path" || fail "file:$path"
done

for command_name in node npx git curl; do
  command -v "$command_name" >/dev/null 2>&1 && pass "command:$command_name" || fail "command:$command_name"
done

[[ -x "$ROOT/tools/bin/nuclei" ]] && pass "local:nuclei" || fail "local:nuclei"
[[ -x "$ROOT/scripts/tailscale-orca-status.sh" ]] && pass "local:tailscale-check" || fail "local:tailscale-check"
[[ -x "$ROOT/scripts/verify-framework-workers.sh" ]] && pass "local:framework-check" || fail "local:framework-check"
[[ -x "$ROOT/scripts/rea-ghidra-env.sh" ]] && pass "local:ghidra-env" || fail "local:ghidra-env"

if grep -RInE '(^|[^A-Za-z])(sk-|nvapi-|hf_|fc-|Bearer[[:space:]])' "$ROOT/ops/orca" >/dev/null 2>&1; then
  fail "secret-literal-scan"
else
  pass "secret-literal-scan"
fi

if curl -sS --max-time 3 -o /dev/null -w '%{http_code}' http://127.0.0.1:3080 2>/dev/null | grep -Eq '^(200|401|403)$'; then
  pass "loopback:harness"
else
  blocked "loopback:harness"
fi

printf 'SUMMARY pass=%s fail=%s blocked=%s\n' "$PASS" "$FAIL" "$BLOCKED"
(( FAIL == 0 ))
