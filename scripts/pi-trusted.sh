#!/usr/bin/env bash
set -euo pipefail

# Launcher for the `trusted-local` profile (docs/01 §0.2, V0.1-T1).
#
# A launcher rather than a runtime mode toggle because extension loading and
# tool ownership are decided at startup: once Pi is running, the set of loaded
# extensions is not something a flag can safely change. Selecting the profile
# here means the daily and isolated extension sets can never load in one
# process, which is the whole point of the directory boundary.

profile_root="${PI_TRUSTED_PROFILE_ROOT:-$HOME/.pi/profiles/trusted}"

# The provider route and parent model are decided (D1/D2, 7 August 2026):
# the direct `openai-codex` OAuth route, because it is the only route whose
# catalog declares `supportsToolSearch` — Pi's deferred-tool-loading mechanism,
# and therefore the difference between an additive capability change and one
# that invalidates the cached prefix. The ID is exact and never an alias:
# alias drift silently changes the prefix and nothing errors when it does
# (docs/10 §10.3).
pi_provider="${PI_TRUSTED_PROVIDER:-openai-codex}"
pi_model="${PI_TRUSTED_MODEL:-gpt-5.6-luna}"
pi_thinking="${PI_TRUSTED_THINKING:-medium}"

if [[ ! -d "$profile_root" ]]; then
  printf 'Trusted profile root not found: %s\n' "$profile_root" >&2
  printf 'Create it before launching; the launcher does not create profiles.\n' >&2
  exit 1
fi

if ! command -v pi >/dev/null 2>&1; then
  printf 'pi not found on PATH.\n' >&2
  exit 1
fi

# Stage 0.3's `SessionManifestV1` compilation is NOT implemented here. It
# cannot be: the manifest hashes an extension set, system prompt, tool schema
# and permission policy that do not exist in this profile until V0.1-T3 and
# V0.1-T5. A launcher that emitted a manifest of empty hashes would be a check
# that always passes, which is worse than no check (R-057). This comment is the
# marker for that gap; the guard lands with T5, not before.

exec env \
  PI_CODING_AGENT_DIR="$profile_root" \
  pi --provider "$pi_provider" --model "$pi_model" --thinking "$pi_thinking" "$@"
