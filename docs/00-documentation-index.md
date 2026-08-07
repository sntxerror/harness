# Ultimate Pi Setup — Documentation Index

Revision: 5 August 2026

## Purpose

This documentation set separates current implementation authority from history, uncertainty and future experiments. An idea appearing in the brainstorm is not permission to install or build it. The ordered plan is the only implementation sequence.

## Documents

| Document | Authority | Use |
| --- | --- | --- |
| `01-ordered-implementation-plan.md` | Authoritative | Current staged implementation, configuration examples, acceptance tests and final stack |
| `02-architecture-decisions.md` | Authoritative rationale | Stable decisions, boundaries, ownership and why alternatives were rejected or deferred |
| `03-risks-gaps-overlaps.md` | Active register | Known risks, unresolved questions, validation work, missing components and conflicts |
| `04-brainstorm-evolution.md` | Historical/non-authoritative | Evolution of the design, hypotheses, parked ideas and experiments worth revisiting |
| `05-sssf-comparison-and-closed-loop.md` | Authoritative design supplement | Source-level SSSF comparison and the deterministic `pi-factory` closed-loop architecture |
| `06-session-portability-spec.md` | Authoritative contract | Provider-neutral session continuation, evidence, compaction lineage, child audit and deletion |
| `07-remote-server-runbook.md` | Authoritative operations guide | Gradual host provisioning, isolated workers, foreign harnesses, portable sessions and Hermes rollout |
| `08-persona-mission-control.md` | Authoritative design supplement | Personas, missions, capability assignment pipeline, memory scopes, leases, lifecycle statecharts, observability event contract |
| `09-topology-and-clients.md` | Authoritative design supplement | Control plane/runners/clients topology, placement policy, session transfer, viewing layers (forge/IDE/web UI), A2A interop stance |
| `10-context-and-cache-discipline.md` | Authoritative mechanism | Request zones, breakpoint placement, append-only mutation channels, cache verification and the per-version obligations implementing ADR-007 |
| `11-execution-and-agentic-layers.md` | Authoritative sequencing | The line between execution and agentic layers, what "the execution layer is finished" means, the parity matrix and the measured switch gate |
| `12-foreign-cli-workers.md` | Authoritative design supplement | Claude Code / Codex / Antigravity control surfaces, compiled provider profiles and model defaults, steering foreign workers onto our capability surface, and the measurement obligation |
| `reviews/` | Point-in-time findings | Dated verification of a subsystem against the bundle and external experience; records findings, changes nothing. Includes the open-decisions dossier, which collects evidence and options for every decision not yet taken |
| `archive/` | Frozen, non-authoritative | Imported predecessor material (earlier plans, critiques, experiments) kept verbatim for provenance. Never edited, never linted, never cited as authority — if something in it still matters, restate it in an authoritative document |

## Reading order

0. Read `11` first: it says which half of the system is being built now and what "finished" means for it. Every other document describes the whole design and is easy to mistake for a work queue.
1. Read the architecture decisions to understand the intended system.
2. Use the ordered plan to implement one stage at a time; its layer map says which version claims which stage.
3. Check the risk register before promoting any stage.
4. Read the closed-loop supplement before implementing workflow orchestration.
5. Read the portability specification before building any cross-provider/foreign-session handoff.
6. Read the context and cache discipline before touching prompt assembly, tool registration, retrieval or history.
7. Use the remote-server runbook only after the corresponding local stage passes its acceptance tests.
8. Consult the brainstorm only when traces show a missing capability or a decision needs reconsideration.

## Change discipline

- **These documents are authority over content, not authorization to act.** An agent session obtains explicit operator approval for each architecture decision before implementing it; a command block here is reviewed content, not a script to run on sight (ADR-036).
- A settled decision is changed first in the architecture decision record, including rationale and consequences.
- The implementation plan is then updated to match.
- New uncertainty goes into the risk register with an owner, test and promotion criterion.
- Unvalidated ideas go into the brainstorm, not the installation plan.
- Package versions in commands are pins reviewed at the stated revision date; upgrades follow the plan's upgrade procedure.
- Every promoted custom component must have a deterministic acceptance test and an observable failure mode.

## Current high-confidence direction

- The system has two layers. The **execution layer** — session, permissions, code intelligence, validation, capability truth, context economy, workflow sequencing, commit finalization, delegation to children and foreign CLIs, the local MCP registry and portable export — is local, is built first, and is finished before any agentic component starts (ADR-040).
- **Remote is a deployment property, not a capability.** Hosting the registry, RAG or memory service on the server changes where a process runs and nothing about what the harness can do, so it follows the switch rather than preceding it.
- The move off VS Code plus Claude Code is a **measured parity gate at V0.6**, declared per workload class and reversible, not the moment the system can first commit its own changes (ADR-041, `11` §4).
- Foreign CLI workers are **execution-layer components with compiled provider profiles** and cheap-but-capable defaults; they are steered onto our capability surface by registry-generated config, and the saving is measured per launch rather than assumed (ADR-042/043, `12`).
- Upstream Pi is the main terminal execution harness and one frontend in a broader Agent OS.
- Trusted and isolated profiles are physically separate; containment, permissions and cache-critical configuration are frozen for a session.
- Mid-session change is append-only: operator instructions arrive as `system`-role messages and capabilities as additive tool loads; the prefix is never edited, and conformance is hash-verified rather than assumed (ADR-034/035, `10`).
- `@gotgenes/pi-permission-system` provides broad allow/ask-on-risk intent approval. `pi-interactive-shell` provides trusted human PTY and sudo password entry.
- CodeGraph is the only code relationship graph. Native Pi Lens is the only Pi LSP/diagnostics integration, with context injection, formatting and autofix disabled initially; its MCP mirror is not connected back into Pi.
- Project documentation and decisions remain in one explicit RAG — **a remote-tier service from V0.7, never a local one** (ADR-048). The coding harness reads `docs/` directly and installs no embedding model. Hermes is later procedural/episodic memory, not a replacement for RAG or Pi compaction.
- Pi owns conversation compaction. Tool output is compacted before insertion; LeanCTX may be tested only for narrow pre-insertion read/output behavior.
- `pi-session-control` is the first custom package: immutable profile/capability compilation, command preflight, skill filtering and cache-contract enforcement.
- `project_check` is the authoritative validation tool. The parent owns commit, changelog and documentation finalization.
- `pi-factory` is the deterministic outer workflow runtime: typed phases/envelopes, bounded same-session correction, worktree/evidence gates and one run-level acceptance decision. It composes existing owners rather than replacing them.
- Native Pi subagents use compiled static profiles plus dynamic task envelopes. Foreign CLI harnesses run in attachable supervised tmux sessions with a structured user-question relay.
- MCP is used for genuinely remote/stateful services through one lazy proxy and task-specific exports. It does not duplicate native Pi Lens, CodeGraph, local CLIs or generic filesystem/shell access.
- Smart routing is deterministic and chooses a new child cache island. It never changes parent permissions, containment or model algorithmically.
- Pi JSONL and `pi-factory` are the canonical readable records. `PortableSessionBundleV1` is the explicit cross-provider/harness projection; provider-sealed state is never the sole carrier of meaning.
- Hermes is split into `Hermes Memory Service` first and the optional full `Hermes Coordinator` later. Hermes owns reviewed learning and remote interaction, while `pi-factory` owns workflow state and acceptance.
- Personas are top-level `AgentProfileV1` instances; missions bind persona + envelope and are the schedulable unit. The orchestrator schedules at mission altitude only; conflicts are prevented by per-resource leases (ADR-028, 08).
- One memory service with multi-scope namespaces: cross-persona knowledge moves only through profile-declared read grants and review-gated writes; live coordination moves only through the typed mission board (ADR-029/031).
- Stage 12's coordinator is a thin owned orchestrator + IM gateway + relay, not the full Hermes Agent (ADR-030). Internal transport is envelopes/board; A2A only at the external edge (ADR-031).
- Coordination lifecycles are versioned statechart definitions with named guards; enforcement, tests and UI rendering are generated from them. Deterministic between agents, agentic within an agent (ADR-032).
- One control plane, registered runners (workstation is a peer runner), stateless clients. Sessions transfer at explicit boundaries via `PortableSessionBundleV1`; never live-synced (ADR-033).
- Observability instruments four chokepoints (LLM calls, Executor, MCP proxy, permission decisions) with mandatory lineage IDs from Stage 5; the DAW-style web UI is a read-only renderer and conformance checker over one event stream.
- The first persona is `self-dev`: the system develops itself through gitflow, factory runs and the candidate pipeline as soon as Stage 6 lands.
