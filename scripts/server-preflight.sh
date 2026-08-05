#!/usr/bin/env bash
set -euo pipefail

required=(git rg tmux jq sqlite3 podman curl)
missing=()

for command_name in "${required[@]}"; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    missing+=("$command_name")
  fi
done

if ((${#missing[@]})); then
  printf 'Missing required commands:\n'
  printf '  %s\n' "${missing[@]}"
  exit 1
fi

printf 'Command inventory:\n'
for command_name in "${required[@]}"; do
  printf '  %-10s %s\n' "$command_name" "$(command -v "$command_name")"
done

printf '\nVersion summary:\n'
git --version
rg --version | sed -n '1p'
tmux -V
jq --version
sqlite3 --version
podman --version

printf '\nRootless Podman check:\n'
podman info --format 'rootless={{.Host.Security.Rootless}} graphRoot={{.Store.GraphRoot}}'

printf '\nSensitive socket checks:\n'
if [[ -S /var/run/docker.sock ]]; then
  printf '  warning: host Docker socket exists; never mount it into workers\n'
else
  printf '  host Docker socket not present at /var/run/docker.sock\n'
fi

if [[ -n "${SSH_AUTH_SOCK:-}" ]]; then
  printf '  warning: SSH_AUTH_SOCK is set in this shell; do not forward it into workers\n'
else
  printf '  SSH_AUTH_SOCK is not set\n'
fi

printf '\nPreflight completed. This script performs no installation or mutation.\n'
