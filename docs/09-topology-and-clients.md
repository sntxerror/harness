# 09 — Topology, Clients and Interop

Status: accepted design, August 2026. Defines where things run, where state lives, and through what clients the user works. Persona/mission semantics are in `08-persona-mission-control.md`.

## 1. One control plane, N runners, N clients

- **Control plane (server, singular):** orchestrator + mission board, event/trace store, artifact store, memory service, canonical registries (personas, skills, MCP, RAG, workflows), git remote/forge. There is exactly one control plane; it is "the system."
- **Runners (plural, registered):** any machine with the harness installed that registers its compiled capability manifest. The developer's workstation is one runner; the server's ephemeral per-mission containers are others. The orchestrator dispatches a mission to a runner whose manifest satisfies the envelope and whose leases are free.
- **Clients (plural, stateless):** web UI, Telegram gateway, IDE, terminal. Clients talk to the control plane and to runners; they hold no state.

There are not "two setups." One versioned configuration repo (profiles, registries, machine definitions) is deployed to all runners; the system executes in two places and is viewed through many.

## 2. Placement policy (default, not architecture)

Execution site is a dispatch-policy decision per mission, never a hard-wired property of a component. Workflows (including `software-factory`) and personas are deployed to every runner; only the control plane is fixed.

| Situation | Default runner |
| --- | --- |
| Attended work; PTY/sudo needed; repo currently leased to the local worktree | Local |
| Unattended, scheduled, long-running, or untrusted/risky execution | Remote ephemeral |
| Persona missions | Remote, except consults inside an attended session |
| Factory runs | Follow the repo lease and attendance; overridable per envelope |

## 3. Sessions transfer at boundaries; they are never live-synced

Live bidirectional session sync between harness instances is rejected: the session compatibility hash (provider/model, tool schemas, skills, MCP export, policy, worktree identity) will differ across machines, and native resume after a hash change is a forbidden combination.

- Code state moves through git (WIP branches are fine).
- Mission state lives on the board; artifacts in the artifact store.
- The rare "continue this exact conversation elsewhere" uses `PortableSessionBundleV1` (Stage 9): native resume only when identically-versioned profiles reproduce the exact hash; otherwise a new session imports the bundle's projection as context.

Cross-site continuity is deliberate and explicit, never ambient.

## 4. Viewing files, diffs, commits: three bought layers, one built

| Need | Solution | Build? |
| --- | --- | --- |
| Live filesystem, native IDE feel, attach to sessions | VS Code Remote-SSH / JetBrains Gateway; tmux attach over SSH (Stage 8 broker) | No |
| Commits, branches, web diffs, PRs, code browsing | Self-hosted forge: Forgejo (or Gitea). Missions push branches; review diffs in the forge | No |
| Mission events, artifacts, run outputs, lifecycle state | The DAW web UI (08 §9) | Yes — nothing off-the-shelf exists |
| Raw remote-FS browsing in a browser (optional) | `filebrowser` as an embedded page | No |

Boundary rule: the web UI owns events and artifacts; the forge owns committed code; the IDE owns live files. The web UI never grows a file manager; it deep-links outward (forge commit URLs, `vscode://vscode-remote/ssh-remote+...` links). `sshfs` remains a casual fallback for mounting.

## 5. Interop stance: internal-native, A2A at the edge only

A2A standardizes interop between opaque agents across trust/vendor boundaries — a boundary this system does not have internally. Internal adoption is rejected because: Agent Cards are self-declared advertisements while our profiles are compiled truth (R-030 class); A2A agents are black boxes while we require chokepoint observability; A2A authorization is late/coarse while our permission chain approves intent pre-execution; and per-agent HTTP/auth/task-state overhead buys nothing in-process.

Kept cheap hedge: internal schemas remain A2A-mappable (`TaskEnvelopeV1` ≈ Task, public profile subset ≈ Agent Card, artifact manifest ≈ Artifact). If external agents ever participate, the orchestrator's gateway speaks A2A outward at that single edge.

## 6. Authority surfaces

The web UI (persona editor, mission control) and the IM gateway are authority surfaces equivalent to the local terminal: authenticated, least-privilege, every action an event on the trace. Risk approvals arriving remotely carry the same permission semantics as local ones; some actions (sudo, credential entry) are impossible remotely by construction (Stage 12 gate). The IM gateway is a gateway, not an agent: it authenticates, maps chats/topics to missions, relays `UserQuestionV1` and notifications. Chat/topic/command patterns may be derived from existing bots (openclaw, hermes-agent) without adopting their agent cores.

## 7. Bootstrap deployment path

1. **Local-first (V0.1–V0.6):** control-plane services begin as local processes on the development machine alongside the harness (SQLite event store, file-based registries). The MCP registry and lazy proxy are built here, locally, because foreign CLI workers need a generated `.mcp.json` before any server exists (ADR-040).
2. **Remote services wave 1 (V0.7, after the switch):** the existing remote server hosts the stateless/service tier — MCP lazy proxy + canonical registry, RAG service, memory service — consumed by the local runner over SSH/private overlay. No public ports (07-runbook rules apply). This wave relocates processes; it adds no capability, which is why it follows the parity gate rather than preceding it.
3. **Packaged control plane (V1.0):** control plane and runner images become containerized (compose/systemd per 07), the forge is added, and the workstation re-registers as a peer runner of the server-resident control plane.

The self-development repo follows gitflow (`main` = released versions, `develop` = integration, feature branches per task) and syncs with a private GitHub remote; the forge joins at packaging time and GitHub remains a mirror or is retired by explicit decision.
