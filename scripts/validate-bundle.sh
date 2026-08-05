#!/usr/bin/env bash
set -euo pipefail

bundle_root="${1:-$(cd "$(dirname "$0")/.." && pwd)}"

if [[ ! -d "$bundle_root" ]]; then
  printf 'Bundle directory not found: %s\n' "$bundle_root" >&2
  exit 1
fi

json_count=0
while IFS= read -r -d '' json_file; do
  jq empty "$json_file"
  json_count=$((json_count + 1))
done < <(find "$bundle_root" -type f -name '*.json' -print0)

placeholder_count="$(rg -n 'REPLACE_[A-Z0-9_]+' "$bundle_root" --glob '!README.md' | wc -l | tr -d ' ')"

printf 'Validated JSON files: %s\n' "$json_count"
printf 'Intentional deployment placeholders: %s\n' "$placeholder_count"

required_files=(
  README.md
  docs/01-ordered-implementation-plan.md
  docs/02-architecture-decisions.md
  docs/03-risks-gaps-overlaps.md
  docs/04-brainstorm-evolution.md
  docs/05-sssf-comparison-and-closed-loop.md
  docs/06-session-portability-spec.md
  docs/07-remote-server-runbook.md
  schemas/PortableSessionBundleV1.schema.json
  config/permission-system/config.json
)

for relative_path in "${required_files[@]}"; do
  if [[ ! -f "$bundle_root/$relative_path" ]]; then
    printf 'Required file missing: %s\n' "$relative_path" >&2
    exit 1
  fi
done

if find "$bundle_root" -type l -print -quit | grep -q .; then
  printf 'Bundle must not contain symbolic links.\n' >&2
  exit 1
fi

printf 'Bundle structure check passed.\n'
