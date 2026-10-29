#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PYTHON="${ORCA_WORKER_PYTHON:-$ROOT/../orca-workers-uv-venv/bin/python}"

if [[ ! -x "$PYTHON" ]]; then
  echo "BLOCKED worker-python:$PYTHON"
  exit 0
fi

"$PYTHON" - <<'PY'
import importlib
import importlib.metadata as metadata

packages = {
    "strands-agents": "strands",
    "langgraph": "langgraph",
    "agent-framework": "agent_framework",
}
for package, module in packages.items():
    print(f"{package}={metadata.version(package)}")
    importlib.import_module(module)
    print(f"import:{module}=PASS")
PY

echo "SUMMARY framework-workers=3 import-fail=0 model-calls=0"
