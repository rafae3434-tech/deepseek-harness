#!/usr/bin/env bash
set -euo pipefail

# Bounded, read-only Tailscale health snapshot for Orca. It never prints
# auth keys or invokes commands that change login, routes, serving, or ACLs.
command -v tailscale >/dev/null 2>&1 || { echo 'FAIL tailscale-not-installed'; exit 1; }
status="$(timeout 5s tailscale status --json)"
printf '%s\n' "$status" | jq -e '{backendState:.BackendState, self:(.Self|{hostName:.HostName,dnsName:.DNSName,ips:.TailscaleIPs,online:.Online}), peerCount:(.Peer|length)}'
