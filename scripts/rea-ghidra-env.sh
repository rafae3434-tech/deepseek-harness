#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS_ROOT="${REA_TOOLS_ROOT:-$ROOT/../rea-tools}"
export JAVA_HOME="${JAVA_HOME:-$TOOLS_ROOT/jdk}"
export PATH="$JAVA_HOME/bin:$PATH"
export GHIDRA_INSTALL_DIR="${GHIDRA_INSTALL_DIR:-$TOOLS_ROOT/ghidra/ghidra_12.1.4_PUBLIC}"

if [[ ! -x "$JAVA_HOME/bin/java" || ! -x "$GHIDRA_INSTALL_DIR/ghidraRun" ]]; then
  echo "BLOCKED ghidra-runtime java_home=$JAVA_HOME ghidra=$GHIDRA_INSTALL_DIR" >&2
  exit 2
fi

exec "$@"
