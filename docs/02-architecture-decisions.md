# Ultimate Pi Setup — Architecture Decisions

Revision: 5 August 2026

Status vocabulary: **Accepted** is the current implementation authority; **Trial** requires measurement before promotion; **Deferred** is intentionally later; **Rejected** must not appear in the same production profile unless this decision is revisited.

## System position

Pi is the primary interactive terminal harness, not the owner of every engine. The longer-term system is an Agent OS with several execution frontends—Pi, Claude Code, Codex CLI, Antigravity and potentially a VS Code-native frontend—sharing selected versioned services rather than one mutable prompt/configuration directory.

Shared infrastructure may include project knowledge, memory, model/provider availability, CodeGraph, evaluation data and task coordination. Each frontend still receives its own compiled capabilities, prompt, tools, credentials and isolation policy. Separate sessions do not silently share conversation history.

## Governing principles

1. One authoritative owner per responsibility.
2. Explicit retrieval instead of automatic context dumps.
3. Pi-native integration where lifecycle or UI access matters; CLI where a model-visible schema adds no value; MCP for remote/stateful services.
4. Session control-plane state is immutable to models and automation.
5. Dynamic task data is append-only; stable role/profile data forms the cached prefix.
6. Repository-native validation outranks agent confidence.
7. A package is promoted only after traces show net value over operational and context cost.
8. Components fail independently, visibly and without host fallback.

## Decision ledger

### ADR-001 — Upstream Pi remains the main host

**Status:** Accepted

Use current upstream `@earendil-works/pi-coding-agent`. Oh My Pi and other full distributions remain separate trials, not a base to mix package-by-package with the balanced profile.

**Reason:** upstream provides the extension lifecycle, sessions, compaction, tool truncation, provider support and the smallest stable base. A fork makes every later package comparison and cache/security invariant harder to attribute.

### ADR-002 — Profiles are separate processes and configuration roots

**Status:** Accepted

Use physically separate `trusted-local`, `isolated-local`, `isolated-readonly`, `whole-sandbox` and `server-worker` configurations. A user can change profile only by ending the runtime and launching a new session.

**Rejected:** model-driven in-place sandbox/permission/profile switching.

**Reason:** tool ownership, extension code, credentials, mounts and network policy are selected at startup. An in-place toggle creates ambiguous enforcement and destroys cache stability.

### ADR-003 — Permission system is broad allow plus ask-on-risk

**Status:** Accepted

`@gotgenes/pi-permission-system` is the single intent gate. Ordinary Bash and paths are allowed. Removal, privilege escalation, destructive Git, recursive permission changes, infrastructure deletion and foreign CLI launch ask. Nothing is globally denied merely to simulate safety.

**Reason:** the user wants autonomy without a giant whitelist or approval fatigue. Real containment is handled separately.

**Required patch:** merged permission configuration is frozen at session start; changes apply next session.

### ADR-004 — PTY mechanics and permission policy remain separate

**Status:** Accepted

`pi-interactive-shell` supplies a real observable PTY in the trusted main session, including direct sudo password entry. The permission system decides whether the command may start. Passwords never enter chat, MCP or logs.

**Rejected:** `pi-safe-shell` beside permission-system, `sudo -S`, persistent root shells, or a host PTY in isolated profiles.

### ADR-005 — One containment owner per profile

**Status:** Accepted

The recommended isolated-local path is an audited fork of Pi's Gondolin example. Whole-process alternatives such as vmpi, rootless containers or OpenShell are separate profiles.

**Rejected:** stacked sandbox runtimes and silent host fallback.

**Reason:** containment must cover effects, while permission prompts cover intent. Multiple containment layers obscure paths, network behavior and failures.

### ADR-006 — Build `pi-session-control` before specialists

**Status:** Accepted

The first custom package compiles and freezes the profile, capabilities, command inventory, skill catalog, MCP allowlist, permission/containment hashes and cache contract. Effective capability is:

```text
available in selected executor
∩ execution profile
∩ specialist role
∩ task grant
```

The task may only subtract.

**Reason:** role prompts and permissions are not enough if a child is told to use commands, skills or servers that do not exist in its executor.

### ADR-007 — Cache behavior is a control-plane invariant

**Status:** Accepted

The parent model, base system prompt, ordered existing tool schemas, skill catalog, policy and containment remain stable. Dynamic tools are additive only; on providers without native deferred tools, use a fixed initial surface or record a deliberate cache epoch. Compaction is an explicit epoch boundary.

**Implementation split:** a last-loaded Pi observer measures hashes; a launcher/SDK guard prevents forbidden mutation. A normal extension alone cannot veto every competing extension action.

### ADR-008 — CodeGraph is the single relationship graph

**Status:** Accepted

CodeGraph owns callers, callees, dependency relationships, architecture and blast radius. Do not run GitNexus, a second graph index or a code-focused RAG beside it.

### ADR-009 — Native Pi Lens is the single LSP/diagnostics integration

**Status:** Accepted with conservative configuration

Use Pi Lens natively in trusted-local. Disable automatic context injection, formatting and autofix initially. Repository-native checks remain authoritative. Do not connect Pi Lens MCP to the same Pi instance and do not install another Pi LSP client.

CodeGraph remains authoritative for cross-file architecture; `ast-grep` CLI remains authoritative for structural codemods. The capability compiler hides Pi Lens graph/identifier/AST-write surfaces that duplicate those owners.

**Reason for evolution:** an earlier plan selected a simpler standalone Pi LSP to minimize scope. The final preference is Pi Lens native because it adds high-value per-edit diagnostics, read coverage, triage and health while still allowing noisy automatic behavior to be disabled. Its broad tool/index surface is a known overlap requiring filtering.

### ADR-010 — Keep one explicit project-knowledge RAG

**Status:** Accepted

RAG owns authoritative prose: documentation, ADRs, decisions, notes and historical knowledge. It exposes search and get, with preview/provenance first and explicit expansion. Source code is not re-indexed merely to duplicate CodeGraph/LSP.

**Reason:** Hermes memory does not eliminate the need for curated project knowledge. CodeGraph understands code relationships, not product decisions or non-code research.

### ADR-011 — Hermes memory is later and non-overlapping

**Status:** Deferred

Hermes owns learned procedures, verified preferences, episodic outcomes and candidate reusable skills. It does not own project documents, live task state, code relationships or conversation compaction.

Workers submit memory candidates; a versioned service handles provenance, confidence, contradictions, promotion and revocation. Memory may propose a configuration/skill improvement but cannot deploy it automatically.

### ADR-012 — Pi remains the only conversation compactor

**Status:** Accepted

Use Pi's compaction entries, kept-tail semantics and lifecycle. Defaults are the baseline. A deterministic model/task mapping may choose reserve and recent-tail budgets once at launch. A thin native hook may later use a separate inexpensive summary model, but still produces Pi's single compaction entry.

**Rejected:** simultaneous Pi, LeanCTX, Hermes and todo recaps.

### ADR-013 — Tool-result compression happens before insertion

**Status:** Accepted

Prefer structured compiler/test formats and `project_check`. RTK is the first measured text-output compressor. Store bounded semantic failure information plus a raw artifact reference before the result enters history.

Pi's 2,000-character per-result compaction serialization remains a fallback, not the main semantic filter.

### ADR-014 — LeanCTX is a narrow experiment

**Status:** Trial

Eligible: unchanged reread caching, deltas/signatures/maps and pre-insertion output reduction. Disabled: graph, memory, permissions, execution, editing, multi-agent orchestration, automatic recaps and alternate conversation compaction.

Run it only in a separate profile against the RTK/baseline traces.

### ADR-015 — `project_check` is the validation authority

**Status:** Accepted

One tool runs repository-declared formatter checks, linters, compilers, typecheckers and tests through the selected executor. It returns structured failures, artifacts, tree identity and changed-file evidence. It never silently fixes files.

Validation evidence becomes stale after any later write.

### ADR-016 — Editing reliability has one owner per profile

**Status:** Accepted/Trial

Trusted-local may trial one hashline edit package after traces. Gondolin remains the sole built-in owner in isolated-local until stale-edit semantics are integrated into its router. Do not stack read/edit replacements.

### ADR-017 — Todo is optional and parent-only

**Status:** Deferred trial

Baseline task state stays in the parent conversation/plan. Add a todo package only when long missions repeatedly cross compaction or require dependency tracking. Do not inject the changing list every turn and do not create independent child todo stores.

### ADR-018 — Native subagents use static profiles plus dynamic envelopes

**Status:** Accepted after baseline measurement

Use `@gotgenes/pi-subagents` and its worktree companion. `AgentProfileV1` contains the stable role prompt, model class, tools, skills, MCP subset, permissions and output contract. `TaskEnvelopeV1` is the first user message with goal, scope, references, constraints and done criteria.

Children are separate cache islands. Dynamic cwd/branch/task data does not modify their system prompt. Recursive delegation is denied initially.

### ADR-019 — Smart routing chooses children, not parent mutation

**Status:** Accepted deterministic v1; learned routing deferred

Start with explicit role-to-model-class and role-to-harness mappings. Record success, rework, latency, validation and quota. A route may select another child model/provider but never broaden permissions, change containment or switch the parent model.

### ADR-020 — Foreign harnesses are attachable supervised sessions

**Status:** Accepted after prototype

Prototype with `pi-interactive-shell`. The final broker uses a private tmux server, dedicated worktrees, bounded artifacts, a process registry and three interaction modes: attended, supervised background and batch. Every local run is attachable and has a structured question channel.

The user and automation use an exclusive input lease. Password, sudo and sensitive permission dialogs require direct attachment.

### ADR-021 — MCP is one lazy proxy plus per-task exports

**Status:** Accepted after measurement

Pi uses one stable lazy proxy. A canonical registry generates a role/task-specific subset for Claude Code, Codex and verified Antigravity versions. One or two lookups are performed by the parent and passed as references; repeated exploration may justify child-direct access.

**Rejected:** eager direct exposure of every MCP tool; generic filesystem/shell MCP; native/MCP duplicates; one CodeGraph/RAG server per child.

### ADR-022 — Skills use progressive, capability-filtered discovery

**Status:** Accepted

Canonical project skills live in `.agents/skills/`. The model initially receives precise name/description metadata; full procedures load on demand. Skill metadata declares profiles and required commands/files/tools/MCP. Incompatible skills are excluded before launch.

Foreign harnesses receive only task-relevant mirrored/exported skills.

### ADR-023 — Parent owns commit/changelog/documentation finalization

**Status:** Accepted

Subagents return patches/worktrees. Immediately before commit, a parent-only skill runs documentation impact analysis, `project_check`, concise changelog/subject generation, root `CHANGELOG.md` prepend and deterministic hook verification.

Hooks verify but never call an LLM or mutate. Every normal project commit gets exactly one concise changelog bullet. Documentation uncertainty blocks the commit.

### ADR-024 — Observability is local-first and privacy-aware

**Status:** Accepted

Collect tool-surface hashes, prompt/cache epochs, checks, edits, reruns, routes and user corrections locally. External Braintrust/Langfuse-style tracing is opt-in per repository because prompts, code, commands and paths may be sensitive.

### ADR-025 — Hermes may coordinate ephemeral server workers later

**Status:** Deferred

Hermes may schedule Pi/Claude/Codex workers, but workers run in ephemeral isolated environments with scoped services and no shared mutable memory/configuration database. “Self-improvement” is proposal → replay/evaluation → review → staged rollout → rollback.

### ADR-026 — Terminal and VS Code frontends remain distinct

**Status:** Deferred architecture direction

The Terminal Pi instance and a future VS Code/Phi frontend may share engines and versioned configuration packages but not one live conversation brain. VS Code can use its native LSP, file watcher and DAP capabilities instead of duplicating terminal extensions. Cross-frontend sharing happens through explicit APIs/artifacts/memory records.

### ADR-027 — A deterministic workflow engine owns the closed loop

**Status:** Accepted after `pi-session-control`, the shared `Executor` and `project_check`

Build `pi-factory` as a reusable outer runtime callable from Pi, CLI, CI and later Hermes. Ordinary typed code owns phase sequencing, bounded retries, worktree/process state, handoff artifacts, deterministic operations, gates and final run acceptance. Models execute only named judgement phases through immutable `AgentProfileV1` instances.

Every agent call has one versioned output schema. The same schema generates runtime validation and compact model-facing report instructions; do not manually synchronize independent type, prompt-example and call-site copies. Invalid output or a retryable gate violation continues the same child session only when its complete session compatibility hash is unchanged.

### ADR-028 — Personas are top-level profiles; missions are the schedulable unit

**Status:** Accepted (August 2026)

A persona (`self-dev`, `coder`, `lawyer`, `finance`, `researcher`, …) is a top-level `AgentProfileV1` with its own role prompt, grants and risk tier — not a new mechanism. A mission binds one persona to one `TaskEnvelopeV1`. Workflows such as `pi-factory` are invocable by personas, not peers of them. A running session is never mutated into another persona; cross-domain needs are served by the consult pattern (spawn a child with the other persona's profile) or by scoped memory reads. Full semantics: `08-persona-mission-control.md`.

**Rejected:** persona switching in-session; a separate persona subsystem beside profiles.

### ADR-029 — One memory service with multi-scope namespaces and reviewed writes

**Status:** Accepted (August 2026); refines ADR-014/ADR-025

One memory service, per-persona namespaces, scope-tagged writes (persona/mission/user/shared), cross-namespace read grants declared in profiles, and writes admitted only through the candidate pipeline (proposal → evaluation → review → versioned promotion). Per-persona learning runs as lightweight proposer processes over the single service. Durable knowledge never travels agent-to-agent; live coordination travels only through the typed mission board.

**Rejected:** per-persona memory databases; free-form inter-agent chat; unreviewed writes to shared scopes.

### ADR-030 — Thin orchestrator, IM gateway and relay replace the full Hermes Agent

**Status:** Accepted (August 2026); amends ADR-025

Stage 12's coordinator is implemented as three owned thin components — mission orchestrator (suggest-only routing, dispatch, leases), IM gateway (authentication, chat/topic↔mission mapping, `UserQuestionV1` relay), and notification relay — rather than deploying the full Hermes Agent. The orchestrator schedules at mission altitude only; workflow runtimes keep sole ownership of their phases. Chat/command patterns may be derived from existing bot codebases without adopting their agent cores.

**Rejected:** an external agent whose scheduler competes with `pi-factory`; IM gateway with its own agency.

### ADR-031 — Internal transport is envelopes and the mission board; A2A only at the edge

**Status:** Accepted (August 2026)

Internally, agents communicate through typed envelopes, the mission board and artifacts — never per-agent HTTP protocol stacks. Internal schemas remain A2A-mappable (envelope ≈ Task, public profile subset ≈ Agent Card, artifact manifest ≈ Artifact); if external agents ever participate, only the orchestrator's gateway speaks A2A. Reasons: self-declared Agent Cards conflict with compiled capability truth; A2A opacity conflicts with chokepoint observability; A2A late authorization conflicts with pre-execution intent approval.

### ADR-032 — Coordination lifecycles are declarative statecharts with named guards

**Status:** Accepted (August 2026)

Mission, workflow-phase, persona-candidate, question/answer, lease and promotion lifecycles are versioned, hashed statechart definitions (data). From each definition are generated: orchestrator transition enforcement, validators, Given/When/Then transition tests, and observability rendering/conformance semantics. Guards are named predicates. The boundary is "deterministic between agents, agentic within an agent": no state machine inside a session's tool loop. Skills carry knowledge, never control flow; imperative multi-step sequencing in skill prose is a lint error and belongs in a workflow definition or script.

**Rejected:** lifecycle logic scattered in orchestrator code; fine-grained machines wrapping individual tool calls; prose control flow in skills.

### ADR-033 — One control plane, registered runners, stateless clients

**Status:** Accepted (August 2026)

The control plane (orchestrator, board, event/artifact stores, memory service, registries, forge) exists once, server-resident at steady state. Execution sites are registered runners advertising compiled capability manifests; the workstation is a peer runner. Placement is dispatch policy (attended→local, autonomous/untrusted→remote), never a hard-wired property of a component. Sessions transfer at explicit boundaries via `PortableSessionBundleV1`; live session sync between instances is rejected. Viewing: forge owns committed code, IDE-remote owns live files, the mission web UI owns events/artifacts and deep-links outward. Full detail: `09-topology-and-clients.md`.

**Rejected:** two independent setups synchronizing sessions; a file manager grown inside the mission UI; per-project fixed execution sites.

Workflow state is durable outside model context. A run must resume from manifests, envelopes, evidence and repository state even if every model session is discarded. Pi-native compaction remains local to each Pi child conversation.

The first named workflows are `inspect`, `plan`, `implement`, `research`, `release` and `incident`. Known invocations are deterministic code phases using the authoritative `Executor`; they are never rediscovered by a tester agent. Phase execution success and run acceptance are separate recorded facts.

Pi exposes the runtime through `/factory` user commands and at most two small stable parent tools, `factory_start` and `factory_wait`. Questions, approvals, attachment and cancellation use the existing UI/broker rather than generic model-visible terminal/process controls.

**Reason:** the earlier architecture correctly assigned component ownership but did not provide one executable outer loop that composes all owners repeatably. SSSF demonstrated the value of phases, typed envelopes, same-session correction, gates, artifact handoffs and live trace state. Its current implementation is a reference, not a production dependency: it lacks our containment, worktrees, cache compatibility, interaction, intelligence and finalization requirements.

**Rejected:** agent-owned orchestration hidden in one prompt; adopting SSSF unchanged; stamping a full mutable workflow engine into every repository; current-branch automatic `git add -A`; placeholder checks that count as green; resuming a child based only on model identity.

### ADR-028 — The local readable record is canonical; provider state is only an optimization

**Status:** Accepted

Pi's append-only JSONL session tree is the working conversation record. `pi-factory`'s manifests, typed envelopes, event log and content-addressed artifacts are the durable workflow record. Provider response IDs, opaque reasoning signatures, hosted compaction items, hosted search state and server-side agent messages may improve same-provider continuation, but no opaque item may be the sole carrier of a decision, instruction, evidence item or task state.

Add one small Pi-native portable-export projection, not another session manager. It reads the live active branch and emits `PortableSessionBundleV1`: a compact continuity snapshot, readable event stream, compiled capability/profile snapshot, compaction lineage, subagent lineage, evidence/artifact manifest and deletion inventory. It is a slash-command/factory code phase, exposes no permanent model tool, performs no per-turn injection and never rewrites Pi history.

Resume a native Pi or foreign-harness session only when its full `SessionCompatibilityV1` hash matches. A provider/model/profile/tool/policy/executor/worktree change cold-starts a new cache island from the portable bundle and selected artifacts. Native resumption is a performance optimization; readable local reconstruction is the correctness requirement.

Evidence-critical hosted tools must return or be mirrored into locally inspectable inputs, outputs, passages, timestamps, provenance and hashes. A citation or provider object ID alone is discovery metadata, not replayable evidence. Every native and foreign child launch persists the exact readable task envelope, lineage, model/profile, capability grant, questions, answers and bounded result before relying on provider-side orchestration.

**Reason:** Pi's local readable compaction and raw pre-compaction history already avoid most provider lock-in, while the existing factory artifacts make workflow restart independent of model sessions. The missing piece is a normalized export that also captures effective configuration, external evidence and child-session lineage.

**Rejected:** provider-hosted conversations as canonical state; opaque server compaction; transcript-only export without tool evidence; Hermes memory as session replay; LeanCTX history rewriting; forcing another provider to consume incompatible reasoning signatures.

### ADR-029 — Hermes has two explicitly named deployment roles

**Status:** Accepted terminology; staged implementation

`Hermes Memory Service` is the initial narrow integration: reviewed procedural/episodic memory behind explicit `memory_search`, `memory_get`, proposal and review operations. It is not a coordinator, project-document RAG, task database or compactor.

`Hermes Coordinator` is the later full Hermes Agent deployment on the same server or another controlled machine. It may provide the IM front door, scheduling, remote questions/notifications and launch `pi-factory` runs. `pi-factory` still owns phases, retries, gates, artifacts and acceptance; Hermes never directly takes over worker terminals or silently changes permissions, containment, credentials, prompts or production skills.

The coordinator and workers share versioned APIs and artifacts, not one writable SQLite file or mutable prompt/skill directory. Candidate memories and self-improvement proposals require provenance, replay/evaluation, human review, versioned rollout and rollback.

## Superseded directions

| Earlier direction | Why it changed | Current decision |
| --- | --- | --- |
| Install many useful tools and route later | Large permanent schemas and unclear ownership damage reliability/cache | One owner and compiled role-specific surface; add tools only after traces |
| Standalone Pi LSP plus Pi Lens audit profile | Missed Pi Lens's native diagnostic/read-coverage advantages and explicit no-context mode | Native Pi Lens replaces standalone LSP, with overlapping features filtered |
| Todo as baseline | Tool/prompt overhead without evidence and conflicts with parent task ownership | Optional parent-only trial |
| Fixed universal compaction numbers | Model windows and task phases differ | Deterministic per-session policy mapping; defaults first |
| Cheap model decides compaction thresholds | Threshold selection is deterministic and lacks labeled data | No model for thresholds; optional separate summary model after evaluation |
| Interactive shell only for foreign agents | Non-durable across supervisor/UI failures and weak structured question routing | tmux-backed broker; interactive shell remains prototype/sudo PTY |
| Hide/remove control tools when idle | Non-additive tool changes can invalidate cache | Fixed schemas or additive once on deferred-tool models and retained |
| Hermes replaces project RAG | Procedures/episodes and authoritative documents have different lifecycle | Keep both with explicit ownership |
| LeanCTX replaces Pi compaction | LeanCTX overlaps many owners and history pruning is cache-hostile | Pi compaction only; LeanCTX narrow pre-insertion experiment |
| Parent switches model for smart routing | Loses the parent's cache and couples routing to permissions | New child cache island with fixed profile |
| A collection of capable tools is itself a closed loop | Ownership boundaries do not define sequencing, correction or acceptance | Add deterministic `pi-factory` phases, envelopes, gates and run state outside the model |
| Use SSSF as the production orchestrator | Its pattern is strong but the current project is very young and omits sandbox, worktrees, merge and human interaction | Reuse the pattern inside our stronger profiles/executor/broker architecture |
| Treat Pi JSONL alone as a complete cross-harness export | It omits effective prompt/tool/profile contents and external evidence/artifacts | Native JSONL for Pi; `PortableSessionBundleV1` for provider-neutral continuation and audit |
| Use Hermes as both memory and workflow/session state | It would duplicate RAG, compaction and `pi-factory` and make causality unclear | `Hermes Memory Service` first; optional `Hermes Coordinator` later with strict ownership |
