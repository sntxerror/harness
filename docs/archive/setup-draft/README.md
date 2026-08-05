# Ultimate Pi Agent Setup — Implementation Bundle

> **ARCHIVED (5 August 2026):** this bundle is frozen. The canonical, maintained copy of these documents — plus the roadmap and task tracker — lives in the `harness/` repository. Do not edit here.

Revision: 5 August 2026

This archive is the implementation authority for a clean, high-capability Pi environment that can later run on a remote server with Hermes coordination. It separates settled architecture, staged installation, executable workflow design, risks, experiments, portability and server operations.

## Start here

1. `docs/02-architecture-decisions.md` — ownership and non-negotiable boundaries.
2. `docs/01-ordered-implementation-plan.md` — install/build stages and acceptance tests.
3. `docs/03-risks-gaps-overlaps.md` — blockers and evidence required before promotion.
4. `docs/07-remote-server-runbook.md` — operator sequence for the server.
5. `docs/05-sssf-comparison-and-closed-loop.md` — `pi-factory` workflow runtime.
6. `docs/06-session-portability-spec.md` — provider-neutral continuation and audit.
7. `docs/08-persona-mission-control.md` — personas, missions, capability assignment, memory scopes, leases and lifecycle statecharts.
8. `docs/09-topology-and-clients.md` — control plane/runners/clients topology, session transfer and viewing layers.
9. `docs/04-brainstorm-evolution.md` — history and experiments; not implementation authority.
10. `REVIEW.md` — August 2026 MCP/skills review; its accepted gaps are integrated into the plan and ADRs.

## Architecture in one paragraph

Upstream Pi is the interactive coding harness. `pi-session-control` freezes the effective profile, capabilities and cache contract. One permission system approves intent and one executor/containment boundary enforces effects. CodeGraph, Pi Lens/LSP, project RAG, `rg`, `ast-grep` and repository-native checks each have one distinct responsibility. `project_check` is the validation authority. `pi-factory` is the deterministic outer workflow runtime. Native and foreign agents are phase workers with static profiles and dynamic task envelopes. Pi alone compacts conversations. A portable session projection makes work inspectable and continuable across providers. Hermes Memory Service is added later for reviewed procedural/episodic memory; the full Hermes Coordinator is last and owns IM/scheduling, not workflow acceptance.

## Deployment sequence

| Order | Capability | Promotion condition |
| --- | --- | --- |
| 0 | Host/service account, SSH, directories, rootless worker runtime | No public services; no host-socket leakage |
| 1 | Vanilla upstream Pi in separate profile roots | Stable baseline session and version inventory |
| 2 | Permission system, interactive PTY, structured questions | Ordinary commands flow; risky actions ask; passwords are not captured |
| 3 | CodeGraph, Pi Lens, CLIs, one project RAG | No duplicate index/LSP/RAG owner |
| 4 | `pi-session-control` | Immutable capability/cache manifest and unavailable-capability preflight |
| 5 | Shared Executor and `project_check` | Checks bound to exact tree; raw evidence retrievable |
| 6 | `pi-factory` core | Crash-safe `inspect`, `plan`, `implement` with typed gates |
| 7 | Isolated `server-worker` | No host fallback, sudo or undeclared network/credentials |
| 8 | Native/foreign worker adapters and tmux broker | Attach/question/cancel/recover and worktree isolation |
| 9 | Portable session exporter | Cross-provider continuation, audit and deletion test |
| 10 | Commit/changelog/docs finalization | Exact staged tree validated and committed deterministically |
| 11 | Hermes Memory Service | Reviewed memory recall without RAG/compaction duplication |
| 12 | Hermes Coordinator and IM gateway | Authenticated remote question flow and isolated read-only runs |
| 13 | Optimizations: RTK, narrow LeanCTX, summary model, routing learning | Measured improvement without correctness/cache regression |

## What is installed first

- upstream Pi;
- `@gotgenes/pi-permission-system`;
- `pi-interactive-shell`;
- `@juicesharp/rpiv-ask-user-question`;
- CodeGraph and one Pi adapter;
- one selected Pi Lens/LSP integration;
- `rg`, `ast-grep` and repository-native format/lint/type/test/build commands;
- one explicit project-document RAG.

Package pins in the plan are research-time pins, not permission to upgrade blindly. Install them into an evaluation profile first and preserve rollback metadata.

## What is custom-built first

1. `pi-session-control`;
2. shared `Executor` plus `project_check`;
3. `pi-factory`;
4. portable-session exporter;
5. attachable foreign-harness broker;
6. commit/changelog/documentation finalizer;
7. canonical MCP exporter and explicit evidence fusion only if traces justify them.

Later custom builds added by the persona/mission extension (08/09): mission orchestrator with leases and statechart lifecycles, mission board and event store with lineage IDs, persona registry and generated editor UI, suggest-only persona router, DAW-style observability web UI, IM gateway, and per-persona memory proposers over the single memory service.

## Important non-combinations

- permission-system and `pi-safe-shell` in the same profile;
- multiple containment engines around one worker;
- multiple code graphs or LSP clients for one worktree;
- RTK and LeanCTX shell rewriting simultaneously;
- Pi compaction plus LeanCTX/Hermes/todo recap writers;
- two subagent schedulers or any scheduler competing with `pi-factory`;
- direct MCP tools plus the same tools behind the lazy MCP proxy;
- native Pi Lens plus its MCP mirror connected back into the same Pi session;
- multiple automatic format/autofix/edit hooks;
- native resume after a compatibility-hash change;
- free-form agent-to-agent chat or knowledge transfer outside the memory service;
- a second scheduler at mission altitude, or the orchestrator reaching inside workflow phases;
- A2A as internal transport between co-located components;
- persona activation or grant expansion without review (subset-narrowing excepted);
- per-persona memory databases;
- control flow expressed in skill prose.

## Templates

The `config/` directory contains examples, not secrets or universal defaults:

- broad allow/ask-on-risk permission policy;
- trusted interactive-shell settings;
- repository-native project-check placeholder;
- trusted/isolated/server-worker profiles;
- deterministic child router;
- session manifest;
- Hermes gateway user-service template.

Every `REPLACE_...` value must be resolved before use. Do not copy a template into production without comparing it to the pinned package's current schema/documentation.

## Schemas

The `schemas/` directory is an initial contract source for:

- `AgentProfileV1`;
- `TaskEnvelopeV1`;
- `ProjectCheckResultV1`;
- `UserQuestionV1`;
- `PortableSessionBundleV1` manifest.

Generate runtime validators and compact model-facing output instructions from one canonical schema. Do not independently maintain TypeScript types, prompt examples and validators.

## Validation

From the unpacked archive:

```bash
chmod +x scripts/*.sh
scripts/validate-bundle.sh
scripts/server-preflight.sh
```

`server-preflight.sh` is read-only. It checks command availability, versions, rootless Podman and sensitive socket warnings. It installs or modifies nothing.

## Secrets and privacy

This archive contains no credentials. Keep provider tokens, IM bot secrets and repository credentials in their supported private stores. Portable sessions, factory artifacts and transcripts may contain private code and commands; default them to mode `0600`, bounded retention, structured redaction and explicit deletion. Never capture sudo passwords or attach host credential sockets to workers.

## Source freshness

The research and examples were checked through 5 August 2026. Pi, Hermes, packages and provider CLIs move quickly. Follow the upgrade procedure in the ordered plan: inspect current release/source/issues, install into evaluation profile, snapshot the tool/prompt/capability surface, run acceptance tests, then promote the exact version.
