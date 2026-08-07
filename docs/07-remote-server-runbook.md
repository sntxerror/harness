# Ultimate Pi Setup — Gradual Remote Server Runbook

Revision: 5 August 2026

## Intended end state

The server eventually hosts two different services:

- **Hermes Coordinator** — optional IM/remote front door, scheduler, notifications and reviewed cross-session memory;
- **`pi-factory` control plane** — deterministic workflow phases, gates, artifacts, worktrees, process state and acceptance.

Coding work runs in disposable unprivileged workers. Pi, Claude Code, Codex CLI and Antigravity are worker adapters, not workflow schedulers. The first deployment is deliberately smaller: SSH-accessed Pi plus local artifact/state directories. Hermes and unattended workers are added only after local correctness and isolation tests pass.

## Assumptions

- Ubuntu 24.04 LTS or Debian 12 server;
- dedicated unprivileged account `piops`;
- SSH key access; password SSH and public agent dashboards disabled;
- operator retains a separate sudo-capable account;
- repositories are cloned under `/srv/pi-agent/repos`;
- runtime state is outside repositories;
- no host Docker socket, SSH-agent socket or broad home mount enters workers.

Replace example usernames, paths, package pins and provider/model IDs before use. Commands marked **operator** require the administrative account. Commands marked **piops** run as the service user.

> **Every command block below is reviewed content, not a script to run on sight.** An agent session presents the phase and its consequences and waits for explicit operator approval before executing any of it, per decision rather than per phase (ADR-036). Privileged commands are the operator's to run: a password is never typed into anything an agent can observe (R-005/R-006).

## Current host — surveyed 5 August 2026

The host exists and is reachable; this section records what is actually there, and where it diverges from the assumptions above. Divergence is recorded rather than quietly normalized — each one changes a phase.

| Fact | Value |
| --- | --- |
| Address / access | `62.238.51.68`, key-based SSH, same username as the workstation |
| OS / kernel | Ubuntu 26.04 LTS, `7.0.0-28-generic`, x86_64 |
| Resources | 4 vCPU, 7.6 GiB RAM, 75 GB disk (70 GB free) |
| Account | `sntx` (uid 1000), member of `sudo` |
| Present | `git 2.53.0`, `curl`, `python3`, `tmux`; `node v24.19.0` + `npm` under nvm |
| Pi | **0.83.0**, at `~/.nvm/versions/node/v24.19.0/bin/pi` |
| Pi state | `~/.pi/agent/` — `settings.json`, `auth.json` (credentials, never read or copied), `models-store.json` |
| Providers configured | `openai-codex` (7 models, ChatGPT subscription) and `openrouter` (274 models). Nothing else |
| Preflight gaps | `rg`, `jq`, `sqlite3`, `podman` absent — `scripts/server-preflight.sh` exits 1 |

Divergences from the assumptions, and what each one blocks:

1. **One account, not two.** The runbook assumes a dedicated unprivileged `piops` plus a separate sudo-capable operator. The host has a single sudo-capable account used for both. Phase 0's privilege split is therefore unsatisfied: either create the service user before Phase 1, or record an explicit, time-boxed acceptance of single-account operation for the early phases. It must not be left undecided — the isolated profile's guarantees assume the split.
2. **Ubuntu 26.04, not 24.04.** Package availability and pins need re-checking against this release rather than inherited from the runbook.
3. **Node and Pi live under nvm.** They are absent from non-interactive `PATH`, so `ssh host 'pi …'`, `systemd` units and any automation see nothing. Every unit and script must use absolute interpreter paths or source nvm explicitly. This will present as "command not found" in exactly the contexts that are hardest to debug.
4. **No container runtime.** Without rootless Podman there is no isolated execution boundary, so Phase 5 (isolated server-worker profile) and the `isolated-local` profile cannot be built, and V0.1-T1's acceptance cannot pass. Installing it is the first mutating action on this host and needs operator approval.

## Phase 0 — Provision and lock down the host

### Operator commands

```bash
sudo adduser --disabled-password --gecos "Pi agent service" piops
sudo install -d -o piops -g piops -m 0750 /srv/pi-agent
sudo install -d -o piops -g piops -m 0750 /srv/pi-agent/{repos,worktrees,runs,artifacts,backups}

sudo apt-get update
sudo apt-get install -y \
  ca-certificates curl git jq ripgrep tmux sqlite3 unzip zip \
  build-essential python3 podman uidmap slirp4netns fuse-overlayfs

sudo loginctl enable-linger piops
```

SSH baseline in `/etc/ssh/sshd_config.d/50-pi-agent.conf`:

```text
PasswordAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
AllowUsers REPLACE_OPERATOR_USER piops
```

Validate before reload:

```bash
sudo sshd -t
sudo systemctl reload ssh
```

Do not expose Pi, tmux, SQLite, MCP or worker ports publicly. Prefer SSH or a private overlay network. Firewall/network policy is infrastructure-specific and must be tested without cutting off administrative access.

### Service-user directories

```bash
sudo -iu piops
umask 077
install -d -m 0700 \
  ~/.config/pi-agent \
  ~/.local/state/pi-factory \
  ~/.local/share/pi-factory \
  ~/.cache/pi-agent \
  ~/.pi/profiles/trusted \
  ~/.pi/profiles/isolated \
  ~/.pi/profiles/server-worker
```

Acceptance:

- `piops` cannot access the operator's home or agent socket;
- no service listens on a public interface;
- rootless `podman info` succeeds for `piops`;
- `/srv/pi-agent` ownership is correct;
- reboot preserves the user service manager.

## Phase 1 — Install vanilla Pi and establish a server baseline

Review the current upstream installer before running it, then install as `piops`:

```bash
curl -fsSL https://pi.dev/install.sh -o /tmp/pi-install.sh
less /tmp/pi-install.sh
bash /tmp/pi-install.sh
hash -r
pi --version
```

Run vanilla Pi with an isolated configuration root:

```bash
PI_CODING_AGENT_DIR="$HOME/.pi/profiles/trusted" pi
```

Configure one provider interactively. Do not place API keys in repositories, systemd unit files or portable session bundles. Record the Pi/provider/model version and a baseline session export.

Minimum checks:

```bash
command -v pi git rg tmux jq sqlite3 podman
pi --version
git --version
rg --version
tmux -V
podman info
```

At this phase:

- work only over SSH in trusted repositories;
- no unattended writes;
- no Hermes gateway;
- no foreign harness delegation;
- no model-accessible sudo.

## Phase 2 — Install the ergonomic trusted profile

Install only the baseline packages into the trusted profile:

```bash
PI_CODING_AGENT_DIR="$HOME/.pi/profiles/trusted" \
  pi install npm:@gotgenes/pi-permission-system@24.0.0

PI_CODING_AGENT_DIR="$HOME/.pi/profiles/trusted" \
  pi install npm:pi-interactive-shell@0.14.0

PI_CODING_AGENT_DIR="$HOME/.pi/profiles/trusted" \
  pi install npm:@juicesharp/rpiv-ask-user-question
```

Copy the reviewed templates from this bundle:

- `config/permission-system/config.json` into the permission package's documented profile-local config location;
- `config/interactive-shell.example.json` into the extension's documented profile-local location;
- `config/profiles.example.yaml` into the future `pi-session-control` source configuration.

Because package install layouts can change, locate the exact documented path in the pinned package before copying. Do not scan and edit arbitrary global package directories algorithmically.

Server-specific changes from the local trusted profile:

- keep ordinary Bash broadly allowed;
- risky/removal/privilege commands ask;
- direct sudo is for an attached human session only;
- background and `server-worker` profiles deny sudo entirely;
- do not approve persistent root shells;
- never use `sudo -S` or capture a password.

Test through an attached trusted session:

```bash
sudo -k
```

Then ask Pi to run `sudo true` through the interactive PTY. Confirm the permission decision occurs first and the password is typed directly into the focused terminal without entering the transcript/log.

Acceptance:

- ordinary Git/search/test commands do not repeatedly prompt;
- `rm`, force push and sudo ask with the concrete command;
- removal can be approved rather than being categorically denied;
- password input is absent from Pi JSONL and extension logs;
- policy edits do not affect the active session until restart.

## Phase 3 — Add code intelligence and repository validation

Install CodeGraph and its selected Pi adapter, then the single selected Pi Lens/LSP integration according to the main plan. Keep `rg` and `ast-grep` as CLIs. Do not start a second code graph or language server.

```bash
npm install -g @colbymchenry/codegraph

PI_CODING_AGENT_DIR="$HOME/.pi/profiles/trusted" \
  pi install npm:@vndv/pi-codegraph
```

Pin and install the audited Pi Lens package/version selected during implementation. Disable its automatic context injection, formatting, autofix and duplicate MCP mirror initially.

For every repository, create `.pi/project-check.json` from `config/project-check.example.json` and replace all commands with repository-native scripts. A missing check is `unconfigured`, never success.

Before adding any output compressor, collect representative baseline traces for:

- repeated reads;
- long shell/check output;
- stale edits;
- CodeGraph/LSP/RAG queries;
- validation failures;
- compaction quality;
- cache reads/writes and epoch changes.

## Phase 4 — Build the custom control plane locally

Implement in this order:

1. `pi-session-control`;
2. shared `Executor` and `project_check`;
3. `pi-factory` minimal local workflow core;
4. Pi `/factory` UI and stable `factory_start`/`factory_wait` tools;
5. portable-session exporter;
6. native/foreign worker adapters;
7. deterministic commit finalization.

Do not make these host-global mutable scripts. Build versioned packages in a source repository, run tests, install exact artifacts into an evaluation profile, then promote the same hashes.

Required state roots:

```text
~/.config/pi-agent/              immutable compiled profile sources
~/.local/state/pi-factory/       SQLite/WAL, process registry, questions
~/.local/share/pi-factory/       events, envelopes, portable bundles
/srv/pi-agent/worktrees/         disposable Git worktrees
/srv/pi-agent/artifacts/         bounded raw evidence
```

`pi-session-control` compiles a `SessionManifestV1` before launch. Control-plane configuration is mounted/read as read-only to workers and cannot be changed algorithmically during a session.

`pi-factory` initially supports only:

```text
inspect
plan
implement
```

Run `implement` only on disposable repositories until crash recovery, diff scope, checks, questions, portable export and atomic acceptance tests pass.

## Phase 5 — Create the isolated server-worker profile

The unattended profile differs fundamentally from trusted SSH work:

- no sudo or host interactive shell;
- no host home, Docker socket or SSH-agent mount;
- per-task repository worktree is the only normal writable mount;
- network disabled unless the task declares a bounded egress class;
- scoped credentials are brokered per task;
- PID/CPU/RAM/disk/time limits;
- task grant can only subtract capabilities;
- question/approval timeouts fail closed.

Start with rootless Podman or the selected OpenShell/Gondolin worker backend. Do not stack containment engines for one worker.

Illustrative Podman boundary—not a production image definition:

```bash
podman run --rm \
  --network none \
  --read-only \
  --pids-limit 512 \
  --memory 8g \
  --cpus 4 \
  --userns keep-id \
  --security-opt no-new-privileges \
  --cap-drop all \
  --tmpfs /tmp:rw,noexec,nosuid,nodev,size=1g \
  --volume /srv/pi-agent/worktrees/REPLACE_RUN_ID:/workspace:rw,Z \
  --workdir /workspace \
  REPLACE_PINNED_WORKER_IMAGE \
  REPLACE_WORKER_ENTRYPOINT
```

The worker image must contain the exact Pi/CLI/tool versions required by its compiled capability snapshot. Never fall back from a failed isolated launch to host execution.

Acceptance:

- worker cannot read host credentials or unrelated repositories;
- worker cannot reach the network when `network: none`;
- child and extension subprocesses remain in the same boundary;
- termination cleans up processes and worktree leases;
- artifacts survive worker deletion through the broker-controlled artifact path;
- no worker can edit profile, permission, skill or service configuration.

## Phase 6 — Add supervised foreign harnesses

Install and authenticate Claude Code, Codex CLI and Antigravity only where their official subscription terms and unattended-use behavior permit. Authentication belongs to each official CLI; do not copy parent credentials blindly.

Prototype attached launches through `pi-interactive-shell`. After useful traces exist, enable the private tmux broker:

- one private tmux server/socket directory mode `0700`;
- one run/session and worktree per writer;
- transcript/artifact files `0600`;
- single input lease between automation and attached user;
- structured question path preferred over PTY scraping;
- attach/detach/focus/cancel/status available to the operator;
- exact task/profile/capability launch envelope persisted before start.

Every background run remains attachable. “Unattended” means not focused, not unable to ask. `server-worker` cannot request sudo; credential and destructive prompts pause and require an authenticated human decision or fail blocked.

The router chooses a new child cache island using static rules from `config/router.example.yaml`. It may not switch the parent model or loosen access, containment, credentials or network scope.

## Phase 7 — Add portable sessions and backups

Implement `PortableSessionBundleV1` from the dedicated specification and schema in this bundle. Keep it outside repositories by default:

```text
~/.local/share/pi-factory/portable/
```

Run the cross-provider acceptance test before depending on it operationally:

1. complete and compact a disposable Pi phase;
2. export and verify the bundle;
3. revoke/remove the original provider credential from the test profile;
4. start a different harness from `continuity.json`;
5. retrieve declared evidence only as needed;
6. complete the next check-gated phase;
7. inspect and delete all bundle dependencies.

Back up only reviewed configuration, factory state needed for recovery, encrypted portable/audit bundles and artifact indexes. Do not back up raw credentials, sudo PTY logs, transient worktrees or unlimited raw output. Test restoration into a new service account/profile.

## Phase 8 — Add Hermes Memory Service

Do not start with the full coordinator. First expose a narrow reviewed memory boundary to Pi:

```text
memory_search(query, scope, types?, limit?)
memory_get(ids, max_chars?)
/memory-propose
/memory-review
```

Project documents remain in RAG. Pi compaction remains conversation continuity. Factory manifests remain task state. Hermes stores reviewed preferences, procedures, outcomes and candidate skills.

Requirements before promotion:

- typed memory records with provenance, confidence, scope and revocation;
- candidate writes separated from promoted records;
- explicit retrieval and bounded payloads;
- export/delete and contradiction handling;
- no raw session-bundle ingestion;
- no automatic prompt, skill, permission or containment mutation.

## Phase 9 — Deploy Hermes Coordinator and messaging

Only after the isolated worker and question broker are reliable, install the full Hermes Agent as `piops`:

```bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh -o /tmp/hermes-install.sh
less /tmp/hermes-install.sh
bash /tmp/hermes-install.sh
source ~/.bashrc
hermes setup
hermes doctor
```

Configure the messaging gateway interactively using the official flow:

```bash
hermes gateway setup
hermes gateway start
```

Verify one IM platform and one authenticated user before enabling scheduling. Do not expose the gateway administration surface publicly. Use the included `config/systemd/hermes-gateway.service.example` only after confirming the installed binary path and foreground command on the pinned Hermes version.

Coordinator flow:

```text
IM user
  -> Hermes Coordinator
  -> pi-factory request
  -> isolated Pi/Claude/Codex/Antigravity worker
  -> structured question or result
  -> pi-factory/broker
  -> Hermes
  -> IM user
```

Hermes owns IM delivery, scheduling and remote interaction. `pi-factory` owns workflow sequence and acceptance. The worker owns only its assigned phase. Hermes never answers a worker's human question itself and never sends raw terminal keystrokes.

Start with read-only `inspect` and `plan` from IM. Enable write-capable `implement` only after:

- authenticated question/approval round trip works;
- operation hashes prevent stale approval replay;
- containment and credential scopes are proven;
- factory recovery survives coordinator restart;
- commit gate validates the exact staged tree;
- portable export/deletion works.

## Phase 10 — Controlled optimization and self-improvement

After enough production traces:

- trial RTK for selected command families;
- trial LeanCTX only in its separate narrow read/delta profile;
- evaluate a separate compaction summarizer while retaining one Pi compaction entry;
- tune deterministic model routing;
- propose reusable procedures/skills from repeated evidence.

Production changes follow:

```text
candidate
-> isolated replay/evaluation
-> human review
-> versioned package/config
-> canary profile
-> monitored rollout
-> rollback
```

No model or memory system may change active permission, containment, credential, tool-schema, compaction or production skill configuration algorithmically.

## Operational commands

Examples once the respective components exist:

```bash
# Pi attached trusted session
PI_CODING_AGENT_DIR="$HOME/.pi/profiles/trusted" pi -r

# Pi isolated evaluation session
PI_CODING_AGENT_DIR="$HOME/.pi/profiles/isolated" pi

# Inspect user services
systemctl --user status hermes-gateway.service
journalctl --user -u hermes-gateway.service --since today

# List broker tmux sessions using its private socket
tmux -S "$HOME/.local/state/pi-factory/tmux.sock" list-sessions

# Inspect rootless containers
podman ps --all
podman stats --no-stream

# Database integrity after stopping writers or through a read-only snapshot
sqlite3 "$HOME/.local/state/pi-factory/factory.sqlite" 'PRAGMA quick_check;'
```

Do not manually edit the live factory database. Use versioned migrations and supported administrative commands.

## Promotion checklist

Each phase is promoted separately. Do not continue merely because installation succeeded.

- Exact versions and configuration hashes recorded.
- Tool/capability surface matches the profile snapshot.
- Ordinary commands do not nag; risky actions ask once at the right boundary.
- Sudo credentials are never captured.
- Isolation has no host fallback.
- `project_check` is fresh and bound to the current tree.
- Child tasks, questions and results are readable and attributable.
- Cache-critical prefix/tool/profile configuration remains frozen.
- Crash recovery, cancellation and cleanup pass.
- Portable export/replay/audit/deletion pass.
- Observability is useful without leaking secrets.
- Rollback procedure restores the previous pins/configuration.

## Sources

- [Pi installation and documentation](https://pi.dev/)
- [Pi repository](https://github.com/earendil-works/pi)
- [Hermes Agent](https://github.com/NousResearch/hermes-agent)
- [Hermes documentation](https://hermes-agent.nousresearch.com/docs)
- [OpenShell](https://github.com/NVIDIA/OpenShell)
- [Gondolin](https://github.com/earendil-works/gondolin)
