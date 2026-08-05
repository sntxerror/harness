# 08 — Persona and Mission Control Plane

Status: accepted design, August 2026. Extends the bundle beyond the coding harness into a multi-persona, remotely controllable agent system. This document is implementation authority for personas, missions, capability assignment, memory scopes, coordination and lifecycle state machines. Topology and clients are in `09-topology-and-clients.md`.

## 1. Entities

The system has exactly three runtime entity kinds:

| Entity | What it is | Lifetime | Owner |
| --- | --- | --- | --- |
| **Persona** | A top-level `AgentProfileV1`: role prompt, model class, tool/skill/MCP/RAG/memory grants, permission policy, risk tier | Long-lived, versioned, hashed | Persona registry (control plane) |
| **Workflow** | A deterministic runtime with phases, gates and acceptance (`pi-factory` first; others later) | Versioned package deployed to runners | Workflow registry |
| **Mission** | The runtime instance binding one persona + one `TaskEnvelopeV1` goal | From dispatch to terminal state | Orchestrator |

Personas are capability and knowledge; workflows are execution discipline; missions are the schedulable, observable unit. `software-factory` is not a peer of personas — it is a workflow any persona may invoke where its grants allow.

Examples of personas: `self-dev` (this system improving itself), `coder`, `researcher`, `lawyer`, `finance`, `news-reporter`, `media-reader` (OCR/image/video pipelines). The first persona implemented is `self-dev`.

## 2. Capability assignment pipeline

Deterministic layers decide *what a persona/mission can use*; intelligence only selects *within* the decided surface.

| Layer | Nature | Mechanism | Output |
| --- | --- | --- | --- |
| 0 — Canonical registries | Structural | One definition per capability: MCP service registry, skill catalog (`.agents/skills/`), command inventory, RAG corpora, memory namespaces | Conflict-free capability universe; non-combination lints; hashes |
| 1 — Persona declaration | Human/agent-authored, reviewed | `AgentProfileV1` declares subsets of Layer 0 plus permission policy and risk tier | Versioned persona |
| 2 — Compilation | Deterministic, automatic | `pi-session-control` intersects declaration with reality: command preflight, `skill-capability-filter`, MCP allowlist compile, hashing | Frozen session manifest; launch refused on missing capability |
| 3 — Task narrowing | Deterministic, per-mission | Envelope task grants only subtract; router picks child profiles; Stage 11 decision rule chooses parent-passed references vs scoped direct MCP | Mission surface |
| 4 — Runtime selection | Intelligent, bounded | Model chooses which skill body to load, which proxied tool to discover, which bounded RAG query to run, when to consult | Actions within the surface |

Invariant: **selection never expands the surface.** Any expansion is a new session/epoch decided at Layers 1–3.

RAG corpora follow the memory-namespace pattern: a persona declares which corpora it may read; retrieval is explicit, bounded, IDs-first; what a child sees is decided by its parent when authoring the envelope.

## 3. Cross-persona communication

Two channels with a hard separation:

- **Durable knowledge** never travels agent-to-agent. It moves only through the memory service (§4) with scopes, provenance and review. Chat-style DMs for knowledge are prohibited: unaudited, unversioned, contaminating.
- **Live coordination** moves only through the **mission board**: a structured, append-only store of typed envelopes and events. A "DM" is a consult envelope targeted at a persona; a "broadcast" is a subscription to event types or mission tags. Free-form inter-agent chat does not exist.

**Consult pattern:** a running mission needing another domain spawns a child with the other persona's profile (its own cache island, usually narrower grants) and receives a bounded result as an append-only message — or, cheaper, performs a scoped read from the other persona's memory namespace where its profile grants it. A persona is never mutated into another persona mid-session; the parent session's identity stays frozen.

Internal schemas stay **A2A-mappable** (`TaskEnvelopeV1` ≈ A2A Task; public `AgentProfileV1` subset ≈ Agent Card; artifact manifest ≈ A2A Artifact) but A2A is not the internal bus — see `09-topology-and-clients.md` §5.

## 4. Memory: one service, multi-scope namespaces

Adopted pattern (2026 hybrid consensus): private working memory stays in the session; only reviewed knowledge enters the shared layer.

- **One** memory service (Hermes Memory Service), never per-persona databases.
- Every write is tagged with scopes: persona namespace, mission/run ID, user, `shared/` (org-wide, e.g. user preferences). Scopes compose at retrieval.
- **Reads:** a persona's profile declares cross-namespace read grants (e.g. `lawyer` reads `finance/*`, everyone reads `shared/preferences`). Retrieval is explicit, bounded, append-only — never pushed.
- **Writes:** always to the writer's own namespace, always through the candidate pipeline: proposal → replay/evaluation where applicable → review → versioned promotion → revocable. Nothing enters a shared or foreign scope without review.
- **Per-persona learning** runs as N lightweight proposer processes (one per persona, watching that persona's accepted-run evidence) over the single service. The full Hermes Agent is not required for this (ADR-030).

## 5. Persona lifecycle and authoring

`draft → review → active → deprecated`, with optional `canary` between review and active.

- **Drafting** is done by agents or on user request — not by hand-editing YAML. A `persona-architect` agent (read-only access to registries, skill metadata, mission traces, routing evidence) drafts candidate profiles. Drafting objective is **minimal scope**: the smallest grant set the task evidence supports.
- **Review** happens in the persona editor (web UI): a form **generated from `AgentProfileV1` schema + Layer-0 registries** (never hand-maintained), with toggles/checkboxes enumerating only capabilities that exist, non-combination lints enforced live in the form, and a small legible grant diff ("adds: OCR read, legal-RAG read"). Provenance (who/what drafted, from which evidence) is recorded.
- **Subset rule:** if a suggested capability set is a subset of an existing active persona, no review is needed — it runs immediately as a Layer-3 narrowed instance. Review is required exactly when any grant not held by an active persona appears. Optional policy tier: auto-approve candidates whose grants are entirely read-only and credential-free.
- **Activation** creates a new hashed version; edits create new versions applying to **new sessions only** — running missions keep their frozen manifests and stay auditable under launch-time hashes. Deprecated personas remain resolvable for audit.
- The editor writes **declarations only** (Layer 1); compilation against reality stays with `pi-session-control` (Layer 2). The editor is an authority surface: authenticated, and every write is an event on the trace.

## 6. Persona suggestion

The orchestrator runs a suggest-only classifier: incoming request → top 1–2 persona suggestions with one-line rationale → user confirms (web UI / Telegram buttons). It never auto-selects any persona holding mutation, credential or spend capability. It first attempts to express the task as a narrowing of an active persona (subset rule) before proposing a new candidate. Misroutes and corrections are logged as routing evidence for the Stage-13 routing-learning optimization.

## 7. Missions, scheduling and leases

- The orchestrator schedules at **mission altitude only**. Inside a workflow run, the workflow (e.g. `pi-factory`) remains the sole scheduler of its phases. No second scheduler at either altitude.
- Per-persona queues order missions for UX; **conflict prevention is per-resource leases**, generalizing the existing PTY input lease: worktree, browser session, credential scope, index writer, root-changelog writer, PTY.
- The envelope declares its required leases; dispatch acquires **all leases atomically** (the mission waits until all are free) — no incremental mid-run acquisition, which removes deadlock by construction.
- Parallel missions that share no exclusive resource run concurrently. One mission, one workspace; parallel missions never share a worktree.

## 8. Lifecycles are declarative statecharts

Coordination logic is deterministic core; model intelligence lives inside phases, not between them ("deterministic between agents, agentic within an agent").

- These lifecycles are defined as **versioned, hashed statechart definitions (data, not prose or imperative code)**: mission lifecycle, workflow phase flow, persona candidate lifecycle, question/answer flow, lease acquisition, memory-candidate promotion.
- From each definition we generate: transition enforcement in the orchestrator (illegal transitions unrepresentable), validators, Given/When/Then transition test suites, and rendering semantics for the observability UI.
- Transitions use **named guards** (`envelope-complete`, `leases-held`, `gate-passed`, `review-approved`) — explicit predicates, not checks scattered in code.
- Machine definitions may be drafted by agents but deploy only through review and versioned promotion (R-004/R-051 apply).
- **Boundary:** do not state-machine the inside of an agent turn or a Pi session's tool loop. Machines own what crosses boundaries: dispatch, phases, gates, leases, lifecycles, commits, promotions.

Skills corollary: skills carry knowledge and judgment, never control flow. Imperative multi-step "must do step 1..N" language in a `SKILL.md` is a lint error; the sequence belongs in a workflow definition or a script the skill invokes (`commit-finalization` is the reference pattern).

## 9. Observability: one event stream, DAW rendering

- Instrument the **four chokepoints** — LLM calls, shared Executor, MCP proxy, permission decisions — so every persona, scout, OCR call and search request lands in the stream without voluntary emission.
- Every event carries `mission_id / run_id / parent_span_id / role / profile_hash / t_start / t_end / type / artifact_ref`. Lineage IDs are mandatory from the moment the Executor exists (Stage 5) — retrofitting lineage is not acceptable.
- Rendering (web UI, read-only): track = role/agent lane grouped by mission; clip = span; nested track group = a workflow run folded into its parent persona's track; markers = pending questions, permission asks, gate failures. Because lifecycles are statecharts (§8), the UI also renders current state per track and flags event sequences that violate their machine (conformance checking, not just logging).
- Storage is local-first (SQLite acceptable initially) per ADR-024.

## 10. Non-combinations added by this document

- free-form agent-to-agent chat, or knowledge transfer outside the memory service;
- a second scheduler at mission altitude, or the orchestrator reaching inside workflow phases;
- A2A as internal transport between co-located components;
- persona activation or grant expansion without review (except the subset rule);
- per-persona memory databases;
- control flow expressed in skill prose;
- incremental lease acquisition after dispatch.
