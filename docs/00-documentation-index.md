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

## Reading order

1. Read the architecture decisions to understand the intended system.
2. Use the ordered plan to implement one stage at a time.
3. Check the risk register before promoting any stage.
4. Read the closed-loop supplement before implementing workflow orchestration.
5. Read the portability specification before building any cross-provider/foreign-session handoff.
6. Use the remote-server runbook only after the corresponding local stage passes its acceptance tests.
7. Consult the brainstorm only when traces show a missing capability or a decision needs reconsideration.

## Change discipline

- A settled decision is changed first in the architecture decision record, including rationale and consequences.
- The implementation plan is then updated to match.
- New uncertainty goes into the risk register with an owner, test and promotion criterion.
- Unvalidated ideas go into the brainstorm, not the installation plan.
- Package versions in commands are pins reviewed at the stated revision date; upgrades follow the plan's upgrade procedure.
- Every promoted custom component must have a deterministic acceptance test and an observable failure mode.

## Current high-confidence direction

- Upstream Pi is the main terminal execution harness and one frontend in a broader Agent OS.
- Trusted and isolated profiles are physically separate; containment, permissions and cache-critical configuration are frozen for a session.
- `@gotgenes/pi-permission-system` provides broad allow/ask-on-risk intent approval. `pi-interactive-shell` provides trusted human PTY and sudo password entry.
- CodeGraph is the only code relationship graph. Native Pi Lens is the only Pi LSP/diagnostics integration, with context injection, formatting and autofix disabled initially; its MCP mirror is not connected back into Pi.
- Project documentation and decisions remain in one explicit RAG. Hermes is later procedural/episodic memory, not a replacement for RAG or Pi compaction.
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
