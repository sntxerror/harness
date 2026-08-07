#!/usr/bin/env bash
set -uo pipefail

# Read-only capability inventory taken the way an executor sees the machine,
# not the way a login shell does (V0.1-T1; reference case for V0.3-T2).
#
# The distinction is not pedantic, though the specific case here is not the one
# previously recorded. `rg` resolves in neither shell on this workstation: there
# is no system ripgrep at all. Pi vendors its own at `$PI_CODING_AGENT_DIR/bin/rg`
# and calls it by path, so the command exists for Pi and does not exist for
# anything Pi spawns. That makes the dependency *profile-scoped* rather than
# shell-scoped — a fresh profile root has no `bin/` until Pi populates it — and
# it is R-003 with a sharper edge than a login-shell disagreement: two profiles
# on one machine can disagree about whether a command exists.
#
# The probe therefore reports three views: login shell, executor, and the
# vendored directory of each profile root it is told about.
#
# No network, no writes, no privileged commands.

probe() {
  local name="$1"
  local login_path non_login_path login_kind non_login_kind

  # Non-interactive, non-login: bash does not source the rc file, so shell
  # functions and rc-defined aliases do not exist. This is the executor's view.
  non_login_path="$(bash --noprofile --norc -c "command -v $name" 2>/dev/null || true)"
  non_login_kind="$(bash --noprofile --norc -c "type -t $name" 2>/dev/null || true)"

  # Interactive login shell: the operator's view.
  login_path="$(bash -lic "command -v $name" 2>/dev/null | tail -1 || true)"
  login_kind="$(bash -lic "type -t $name" 2>/dev/null | tail -1 || true)"

  local verdict
  if [[ -n "$non_login_path" ]]; then
    verdict="resolves"
  elif [[ -n "$login_path" ]]; then
    verdict="LOGIN-ONLY"
  else
    verdict="absent"
  fi

  printf '%-12s %-10s %-10s %-12s %s\n' \
    "$name" \
    "${login_kind:--}" \
    "${non_login_kind:--}" \
    "$verdict" \
    "${non_login_path:-${login_path:-}}"
}

printf '%-12s %-10s %-10s %-12s %s\n' COMMAND LOGIN EXECUTOR VERDICT PATH
printf '%-12s %-10s %-10s %-12s %s\n' ------- ----- -------- ------- ----
for cmd in node npm git jq tmux docker rg ripgrep ast-grep sg codegraph podman pi claude codex agy; do
  probe "$cmd"
done

printf '\nVersions as the executor resolves them:\n'
for cmd in node npm git jq pi claude; do
  if bash --noprofile --norc -c "command -v $cmd" >/dev/null 2>&1; then
    printf '  %-8s %s\n' "$cmd" \
      "$(bash --noprofile --norc -c "$cmd --version 2>&1 | head -1" || echo '?')"
  fi
done

# Vendored binaries are invisible to both shells above because Pi calls them by
# path. They belong to a profile, so each profile root is probed separately —
# a command present in one and absent in another is the failure V0.3-T2 exists
# to catch, and it is already reproducible between these two roots.
printf '\nVendored per profile root (Pi calls these by path, never via PATH):\n'
for root in "$HOME/.pi/agent" "$HOME/.pi/profiles/trusted"; do
  printf '  %s\n' "$root"
  if [[ -d "$root/bin" ]]; then
    for tool in "$root"/bin/*; do
      [[ -x "$tool" ]] || continue
      printf '    %-8s %s\n' "$(basename "$tool")" \
        "$("$tool" --version 2>&1 | head -1)"
    done
  else
    printf '    (no bin/ — nothing vendored)\n'
  fi
done
