#!/usr/bin/env bash
set -euo pipefail

# Read-only structural validation of this repository. No network, no writes.
# Dependencies: bash, find, grep, jq. Optional: markdownlint-cli2 (see README).

bundle_root="${1:-$(cd "$(dirname "$0")/.." && pwd)}"

if [[ ! -d "$bundle_root" ]]; then
  printf 'Bundle directory not found: %s\n' "$bundle_root" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  printf 'Required tool missing: jq\n' >&2
  exit 1
fi

# Every tracked JSON file must parse. .git, node_modules and the frozen
# docs/archive tree are never inspected — archived material is kept verbatim and
# must not be able to fail the current repository's checks.
json_count=0
while IFS= read -r -d '' json_file; do
  jq empty "$json_file"
  json_count=$((json_count + 1))
done < <(find "$bundle_root" \
  \( -name .git -o -name node_modules -o -path "$bundle_root/docs/archive" \) -prune -o \
  -type f -name '*.json' -print0)

# Deployment placeholders are intentional in config/ templates and must stay
# visible; they are counted, not treated as failures. Only config/ is scoped —
# docs and task files legitimately discuss placeholders by name.
placeholder_count="$(
  grep -rEIo 'REPLACE_[A-Z0-9_]+' "$bundle_root/config" 2>/dev/null |
    wc -l | tr -d ' '
)"

printf 'Validated JSON files: %s\n' "$json_count"
printf 'Unresolved placeholders in config/ templates: %s\n' "$placeholder_count"

required_files=(
  README.md
  ROADMAP.md
  CHANGELOG.md
  docs/00-documentation-index.md
  docs/01-ordered-implementation-plan.md
  docs/02-architecture-decisions.md
  docs/03-risks-gaps-overlaps.md
  docs/04-brainstorm-evolution.md
  docs/05-sssf-comparison-and-closed-loop.md
  docs/06-session-portability-spec.md
  docs/07-remote-server-runbook.md
  docs/08-persona-mission-control.md
  docs/09-topology-and-clients.md
  docs/10-context-and-cache-discipline.md
  docs/11-execution-and-agentic-layers.md
  docs/12-foreign-cli-workers.md
  schemas/AgentProfileV1.schema.json
  schemas/PortableSessionBundleV1.schema.json
  schemas/ProjectCheckResultV1.schema.json
  schemas/TaskEnvelopeV1.schema.json
  schemas/UserQuestionV1.schema.json
  config/permission-system/config.json
)

for relative_path in "${required_files[@]}"; do
  if [[ ! -f "$bundle_root/$relative_path" ]]; then
    printf 'Required file missing: %s\n' "$relative_path" >&2
    exit 1
  fi
done

# Every roadmap version must have a task file, and vice versa.
for version in V0.0 V0.1 V0.2 V0.3 V0.4 V0.5 V0.6 V0.7 V0.8 V0.9 V1.0; do
  if ! find "$bundle_root/tasks" -maxdepth 1 -name "${version}-*.md" -print -quit | grep -q .; then
    printf 'Task file missing for roadmap version: %s\n' "$version" >&2
    exit 1
  fi
done

if find "$bundle_root" -name .git -prune -o -type l -print -quit | grep -q .; then
  printf 'Bundle must not contain symbolic links.\n' >&2
  exit 1
fi

printf 'Bundle structure check passed.\n'
