#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ORCA="${ORCA_BIN:-/home/pc-1/.cache/orca/appimage/launcher/orca-ide}"
PASS=0
FAIL=0
BLOCKED=0

pass() { PASS=$((PASS + 1)); printf 'PASS %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s\n' "$1"; }
blocked() { BLOCKED=$((BLOCKED + 1)); printf 'BLOCKED %s\n' "$1"; }

if [[ -x "$ORCA" ]]; then pass "orca-cli-present"; else fail "orca-cli-present"; fi

STATUS="$($ORCA status 2>/dev/null || true)"
if grep -q 'runtimeState: ready' <<<"$STATUS" && grep -q 'graphState: ready' <<<"$STATUS"; then
  pass "orca-runtime-ready"
else
  fail "orca-runtime-ready"
fi

if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then pass "deepseek-harness-git"; else fail "deepseek-harness-git"; fi

if [[ -f "$ROOT/ops/orca/agents.yaml" && -f "$ROOT/ops/orca/policy.yaml" ]]; then
  pass "orca-manifest-and-policy"
else
  fail "orca-manifest-and-policy"
fi

HTTP_STATUS="$(curl -sS --max-time 3 -o /dev/null -w '%{http_code}' http://127.0.0.1:3080 2>/dev/null || true)"
if [[ -x "$ROOT/run-local.sh" && "$HTTP_STATUS" =~ ^(200|401|403)$ ]]; then
  pass "deepseek-harness-loopback"
else
  blocked "deepseek-harness-loopback"
fi

NUCLEI_BIN="$(command -v nuclei || true)"
if [[ -z "$NUCLEI_BIN" && -x "$ROOT/tools/bin/nuclei" ]]; then NUCLEI_BIN="$ROOT/tools/bin/nuclei"; fi
if [[ -n "$NUCLEI_BIN" ]]; then pass "nuclei-present"; else fail "nuclei-present"; fi

if grep -RInE '(^|[^A-Za-z])(sk-|nvapi-|hf_|fc-|Bearer[[:space:]])' "$ROOT/ops/orca" >/dev/null 2>&1; then
  fail "no-secret-literals-in-orca-config"
else
  pass "no-secret-literals-in-orca-config"
fi

printf 'SUMMARY pass=%s fail=%s blocked=%s\n' "$PASS" "$FAIL" "$BLOCKED"
(( FAIL == 0 ))
