#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-/tmp/orca-harness-health.json}"
ORCA="${ORCA_BIN:-/home/pc-1/.cache/orca/appimage/launcher/orca-ide}"

python3 - "$ROOT" "$OUT" "$ORCA" <<'PY'
import json
import subprocess
import sys
import time
from pathlib import Path

root, out, orca = sys.argv[1:]

def run(*args):
    p = subprocess.run(args, text=True, capture_output=True, timeout=30)
    return {"code": p.returncode, "stdout": p.stdout[-4000:], "stderr": p.stderr[-2000:]}

snapshot = {
    "timestamp": int(time.time()),
    "orca": run(orca, "status"),
    "harness_check": run(str(Path(root) / "scripts" / "verify-orca-harness.sh")),
    "provider_route": run(str(Path(root) / "scripts" / "provider-route.sh")),
}
Path(out).write_text(json.dumps(snapshot, indent=2) + "\n")
print(out)
print(json.dumps({k: v["code"] for k, v in snapshot.items() if isinstance(v, dict) and "code" in v}))
PY
