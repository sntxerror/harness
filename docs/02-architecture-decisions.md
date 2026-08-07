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

### ADR-034 — Mid-session change uses append-only channels, never prefix edits

**Status:** Accepted (August 2026); refines ADR-007

Instructions and capabilities that change during a session enter through append-only channels: an operator instruction is appended as a `system`-role message in the tail, and a capability change is an additive load/unload against tools declared up front with deferred loading. The top-level system prompt and the ordered tool schema list are immutable for the epoch. Where the pinned model does not support a preserving channel, the harness keeps a fixed surface for the epoch or declares an explicit boundary — it never silently edits the prefix. Availability per model is recorded in the session manifest. Mechanism, placement rules and verification: `10-context-and-cache-discipline.md`.

**Reason:** prefix edits were the only remaining sanctioned way to deliver mid-session context, and they invalidate the whole conversation cache. The append-only channels remove that trade-off; the `system`-role channel is additionally the non-spoofable operator path, unlike operator text embedded in user or tool content.

**Rejected:** rebuilding the system prompt to inject context; swapping the tool list per mode; smuggling operator instructions into user-turn text when a privileged channel exists.

### ADR-035 — Cache conformance is a verified gate, not a convention

**Status:** Accepted (August 2026); implements ADR-007

The normalized rendered prefix is hashed per breakpoint and compared against the epoch's recorded hash; an undeclared mismatch is a `CACHE_EPOCH_VIOLATION`, failing the request in the evaluation profile. Uncached, cache-read and cache-write tokens are recorded as separate event fields from the Executor onward, never as one total. A scripted smoke session asserts stable prefix hashes, non-zero cache reads after the first request and a startup token budget; drift fails CI. Savings are reported from traces only.

**Reason:** a frozen prefix is an assertion until something checks it, and every observed invalidator (interpolated clocks, non-deterministic serialization, per-turn panels, forks rebuilding the prefix) fails silently — no error, only cost. Hashing identifies which component moved the bytes; usage counters alone only prove that something did.

**Rejected:** trusting convention and review; a single combined token metric; estimating savings without traces.

### ADR-036 — Documented decisions are authority, not authorization

**Status:** Accepted (August 2026)

A decision recorded in these documents establishes *what was decided*. It does not constitute standing permission to implement it. Before an agent session implements any architecture decision carried in the `docs/` set — provisioning, account and privilege layout, package and version pins, profile and containment structure, provider/model selection, schema and contract changes, service topology — it presents the decision to the operator and obtains explicit approval for that decision.

Presenting means: name the decision and where it is recorded, state what implementing it commits the system to, note what it rules out, and surface any divergence between the document and the machine's actual state. Approval is per decision. It does not extend to adjacent decisions in the same document, to a later phase of the same runbook, or to a re-run after conditions change. Silence is not approval.

Documented commands are the exception that proves the rule: a runbook command block is reviewed content, not a script to execute on sight. The operator runs privileged commands, or approves each one, in keeping with R-005/R-006 — a password must never be typed into anything the agent can observe.

Reversible, non-privileged work that a decision already covers — reading state, running the read-only preflight, validation and lint, drafting documents, preparing reviewable scripts — proceeds without a new approval.

**Reason:** the documents are dense and highly specific, which makes them read like an execution plan. An agent following them faithfully will provision hosts, create accounts and install package sets without anyone having chosen to do so *now*. Authority over content and authorization to act are different things, and conflating them turns a design record into an autopilot.

**Rejected:** treating a checked-out document as consent; batching several decisions behind one approval; inferring approval from an operator's earlier approval of a related step.

### ADR-037 — Privileged commands have exactly one channel: the interactive PTY, gated on the bash surface

**Status:** Accepted (August 2026); depends on the `pi-interactive-shell` and `@gotgenes/pi-permission-system` pins

A command classified as privileged executes only through `interactive_shell` with `mode: "interactive"`. That mode is the only blocking one — `hands-free`, `dispatch` and `monitor` all return a `sessionId` immediately — so the model's turn is suspended for the session's whole life, and the focused overlay writes keystrokes straight to the PTY. The operator types the password into the real terminal, it never reaches the model, and because the capture buffer accumulates only the child's output stream it never reaches the transcript, the tool result or the handoff snapshot either.

The classification decision is not ours to invent, and it is not ours to write code for either. The permission system's `shellTools` config maps a non-`bash` tool onto the bash enforcement stack by naming the argument that carries its command — `{"interactive_shell": {"commandArgument": "command", "workdirArgument": "cwd"}}`, exactly as `docs/01` §2.1 already specifies. Recording the alias routes the command through the same decomposition, wrapper flooring, path and `external_directory` token gates and `bash:` rules as native `bash` (`src/access-intent/tool-kind.ts`). The `bash` surface therefore stays the single owner of command intent, `interactive_shell` becomes a consumer of that decision rather than a second policy surface, and no interceptor is needed for this half.

What the alias cannot cover is a call that carries no command. `resolveShellInvocation` reads the mapped argument and yields `""` when it is absent, so an `interactive_shell` call bearing only `sessionId` and `input` presents an *empty* command to the bash gate and matches the `"*": "allow"` rule. Keystroke injection into an already-running session is therefore invisible to command-level policy by construction. Classification must consequently be sticky to the session rather than evaluated per call: `input`, `inputKeys`, `inputHex` and `inputPaste` are refused for any session whose originating command was privileged, in every state that session can reach — `backgrounded` included, since backgrounding leaves it addressable by id and would otherwise hand a live root shell back to the model. This, and the mode rule above, are the only parts we implement.

A headless context has no privileged channel at all. The tool requires a TUI and errors without one, so a non-interactive or service-launched session cannot escalate by any route rather than falling back to a weaker one.

**Reason:** interactive mode supplies the R-005/R-006 property by construction, but supplies it only as an *availability*. `mode` is a model-supplied parameter, the package ships no mode allowlist and no permission integration of any kind, and its free-form `command` receives neither the `bash` token gates nor automatic path extraction — so without an explicit rule the same tool that makes safe password entry possible also offers `mode: "dispatch"` with keystroke injection and output polling over the identical command.

**Rejected:** trusting the model-supplied `mode`; a second permission surface or rule syntax for `interactive_shell`; a custom interceptor calling `checkPermission` where the `shellTools` alias already does the work in config; `registerToolAccessExtractor` as the gate, which is documented as path-only and cannot see a command string; evaluating privilege once at spawn and letting the session outlive its classification; treating this channel as containment rather than as intent control.

### ADR-038 — The harness account's sudo is time-boxed to Phase 0

**Status:** Accepted (August 2026); revocation is a V0.1 exit condition

The account running Pi keeps sudo through server bring-up, confined to the single channel in ADR-037, and loses it when Phase 0 completes. Revocation is an exit condition of V0.1, not an aspiration deferred to a later version. `piops` never receives sudo at any point — the isolated profile's guarantees depend on that, and nothing in this decision softens it.

After revocation, privileged host work happens in an operator terminal outside the harness. Escalation inside a worker is permitted only within a Gondolin or container boundary, never on the host, and a worker that needs root gets a contained root rather than a path to the host's.

**Reason:** permissions are UX and intent control; the container boundary is the security boundary. A guard that confines sudo to one channel is a usability affordance during a phase that genuinely needs frequent privileged steps — it is not a containment claim, and R-008 already records that a Pi-native extension process, PTY tools included, can execute on the host even when the built-in shell is contained. Keeping the affordance past the point of need silently converts a time-boxed convenience into a standing privilege, which is the same failure the existing `90-sntx-nopasswd` time-box was written to avoid.

**Rejected:** permanent sudo for the harness account; granting `piops` sudo under any condition; treating the ADR-037 guard as a substitute for the containment boundary; leaving revocation as an untracked intention rather than a checked exit condition.

### ADR-039 — Pins resolve to latest at refresh time; a version in prose is never authority

**Status:** Accepted (August 2026); amends the pin rule in ADR-006 and `CLAUDE.md`

Every Pi extension, package and plugin is taken at its latest published version whenever it is installed or deliberately refreshed. A version number written in these documents records what was resolved on a given date; it is evidence, never a target, and a stale one is not a reason to install an older release. Refreshing to latest is the default action and needs no separate justification.

What stays exact is the *resolved* version. Installation resolves latest, then records the exact version and integrity hash into the profile lockfile and the session manifest, and that recorded value is what the running system uses until the next refresh. Between refreshes the profile does not float: a session that resolved a version keeps it, because `SessionCompatibilityV1` and the cache epoch are computed over package identity and a version that changes underneath a live profile invalidates both silently.

Refresh is therefore a deliberate act with a date, not a background process. It re-runs the profile's smoke suite before promotion, and for anything that carries policy semantics — the permission system above all — it re-reads the behaviours we depend on, since a major bump can move them without breaking a signature.

**Reason:** the previous rule optimized for stability and produced staleness instead. The pins carried in `docs/01` had drifted several majors behind by the time anyone tried to install them, and treating those numbers as decisions meant reproducing a months-old environment for no stated benefit. The real requirement was never an old version — it was knowing exactly which version is running and being able to reproduce it.

**Rejected:** installing a version because a document mentions it; genuinely floating ranges resolved per install, which make the manifest hash unreproducible and let permission semantics change mid-session; background auto-update; treating a routine refresh as needing operator approval when the profile's smoke suite covers it.

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

### ADR-040 — The system has two layers, and the execution layer is finished first

**Status:** Accepted (August 2026); re-sequences the roadmap, changes no stage content

The system is divided into an **execution layer** — everything that makes one task run well on one machine: session, permissions, code intelligence, validation, capability truth, context economy, workflow sequencing, commit finalization, delegation to children and to foreign CLIs, the local MCP registry and session portability — and an **agentic layer**: scheduling, unattended dispatch, cross-session durable knowledge, personas as schedulable identities, the mission board, remote interfaces and multi-runner placement. The execution layer is completed, used and measured before any agentic component starts. Full statement, including the boundary cases, is `11-execution-and-agentic-layers.md`.

Two boundary cases are settled by this decision. A foreign CLI worker executing one phase of an already-scheduled run is **delegation, not orchestration**, and therefore belongs to the execution layer and ships before the switch. And **remote is a deployment property, not a capability**: every execution-layer component is complete when it works locally, so hosting the MCP registry, RAG or memory service on the existing server is deferred behind the switch and `docs/07` becomes a runbook consulted at that point rather than a Phase 0 obligation.

**Reason:** the previous sequence put remote provisioning at V0.5 and delegation at V0.6, so months of work would have produced infrastructure rather than leverage, and at no point did the thing being built become better than the thing being used to build it. Separating "makes one task run well" from "makes many tasks run without a human" gives the first half a completion criterion and the second half a precondition.

**Rejected:** treating server provisioning as foundational; building scheduling and cross-session memory before the harness could delegate a phase; a single undifferentiated stage list whose ordering implied nothing about value.

### ADR-041 — The switch is a measured parity gate, per-workload and reversible

**Status:** Accepted (August 2026); supersedes the "V0.4 is the switch point" claim in `ROADMAP.md` and `README.md`

Daily development moves from VS Code plus Claude Code onto the harness at an explicit gate (V0.6), not when the harness can first commit its own changes. The gate has two halves: a **capability parity matrix** against the environment actually in daily use, and **measured criteria** over a dual-run period of at least ten working days — completion rate, post-acceptance correctness, median cost including foreign-worker spend, median latency, no silent stalls, crash recovery, and an export that lets an in-flight task continue in Claude Code. Thresholds and evidence are in `11` §4.

The switch is declared **per workload class** — this repository, then other trusted repositories, then unfamiliar or risky code — and each declaration is reversible against a rollback condition stated in advance. Claude Code and Codex remain installed and remain legitimate workers of the system afterwards.

Writing the matrix surfaced three capabilities used daily that the plan assigns to nobody: **web search and fetch, image input, and editor integration**. They are recorded as parity gaps with deadlines (D10–D12 in the open-decisions dossier), because a switch declared without them is a downgrade presented as progress.

**Reason:** V0.4 makes the system self-hosting, which is a different property from being the better tool. A harness that can commit but cannot delegate, cannot reach the web and has no diff view is not one a reasonable person would switch to, and calling it the switch point guaranteed either a premature move or a quietly abandoned label.

**Rejected:** declaring the switch from impression rather than from run records; an all-or-nothing switch across every workload; treating the previous environment as decommissioned rather than as a fallback and a worker.

### ADR-042 — Foreign CLI harnesses are first-class factory workers with compiled provider profiles

**Status:** Accepted (August 2026); promotes part of ADR-020 from prototype to execution-layer requirement

`pi-factory` selects a worker per phase from compiled **provider profiles** binding task nature to binary, model, reasoning effort and access — `recon`, `sweep`, `implement`, `implement-hard`, `review`, `typed` (`12` §4). Profiles are compiled by policy from the phase spec; the model never passes one. Defaults are the cheap-but-capable tier (`gpt-5.6-luna`, `gemini-3.6-flash`, `claude-sonnet-5`) because gates catch what a cheaper model gets wrong and re-running a bounded phase costs less than paying frontier rates for every phase. Escalation to a stronger tier is a config change within the same adapter.

The review profile names a different vendor from the implement profile: the existing reviewer-differs-from-implementer rule is worth more across vendors than across one family's models, and foreign workers are what make that affordable.

The factory **spawns the official CLI as a local process**. It does not re-implement a provider client, proxy OAuth tokens, or wrap a subscription into a service — a design constraint, not a convenience, and the thing that keeps the arrangement inside the providers' terms (`12` §7).

**Rejected:** foreign CLIs as a post-parity nicety; model choice made by the model; one provider for every phase; re-implementing provider clients to avoid spawning processes.

### ADR-043 — Foreign workers are steered onto our capability surface by generated config, and the saving is measured

**Status:** Accepted (August 2026)

A vendor CLI arrives with its own search, file reading and web tools — in Claude Code's case roughly 24k tokens of tool definitions inside a ~33k-token prefix — for capabilities this system already owns better. Every foreign launch therefore receives a task-scoped MCP export from the canonical registry, an exclusive-MCP flag where one exists, removal of overlapping built-ins where the CLI permits it, the routing policy appended to its system prompt, and a deterministic hook denying the tools the phase must not use.

A prompt addendum is a **request**; a hook is **enforcement**. Only the second survives a model that decides otherwise, and where no hook exists the restriction is reported as a preference rather than recorded as a control.

Every adapter records the measured prefix cost, the exported server set, the tools removed and denied, token counts and the phase verdict into the event stream on every launch. A profile whose measured prefix does not improve on the stock CLI is recorded as not improving on it. Two known upstream defects mean the intent cannot be assumed to hold: `--disallowedTools` does not affect MCP tools in Claude Code's print mode, and its built-in MCP servers cannot be removed from context at all (R-093, R-094).

**Reason:** a foreign worker's context is entirely outside our cache accounting, which makes it the one place where an unmeasured claim of saving could persist indefinitely. ADR-035 already rejects estimating savings without traces; this extends the same rule across the process boundary.

**Rejected:** accepting vendor defaults; hand-maintained per-provider configs instead of registry-generated exports; asserting a token saving from a config change without counting the prefix; treating prompt instructions as enforcement.

### ADR-044 — Control-channel preference for foreign workers: structured headless, then ACP, then PTY

**Status:** Accepted (August 2026); amends the adapter list in `docs/01` §10.2

An adapter uses the highest available rank: (1) native headless structured output, (2) ACP where the CLI ships or has a maintained adapter, (3) PTY with sentinel detection. Codex CLI's `codex exec --json` with `--output-schema` supplies the typed-envelope contract directly and makes it the default worker for batch and schema-constrained phases and the reference implementation for the others. PTY prompt detection by silence or terminal text remains a fallback, never a correctness mechanism.

ACP moves up from `ACPAdapter (later)` because its adoption changed: Zed 1.0 shipped it on 29 April 2026 with Claude Code, Codex, Gemini CLI and OpenCode in-editor, JetBrains shipped support in December 2025, and the ACP Agent Registry launched 28 January 2026. Anthropic has not adopted it natively — Claude Code reaches ACP through a Zed-maintained bridge — so ACP is evaluated per provider rather than adopted universally.

The same protocol is the cheapest available answer to the editor-integration parity gap in the opposite direction: `pi-acp` exposes Pi itself as an ACP agent over stdio, making the harness drivable from Zed, JetBrains or a VS Code ACP client without building an extension. That remains an open decision (D12), not a commitment — the package is at 0.0.33.

**Rejected:** PTY scraping where a structured channel exists; adopting ACP universally on adoption numbers alone; building an ACP client for a provider whose headless path already satisfies the contract.

### ADR-045 — CodeGraph is one engine with per-session single surfaces, not one interface

**Status:** Accepted (August 2026); refines ADR-008 and corrects the blanket "never duplicate through MCP" phrasing in `docs/01`

ADR-008's rule was written as "CodeGraph is the single relationship graph; do not expose it again through MCP." Read literally that forbids a foreign CLI worker from ever seeing the graph, which contradicts both the reason foreign workers exist and the pattern this plan already applies to Pi Lens one section earlier. The rule conflated three separate invariants; they are now stated separately, and only the second and third were ever about interfaces.

1. **One index and one daemon per repository.** CodeGraph stores a per-project SQLite/FTS5/WAL graph at `.codegraph/codegraph.db` and shares **one background server across sessions over a local socket**, with one debounced OS-level watcher. Concurrent clients attach to that server; they do not each build an index. The harm ADR-008 names — duplicate indexes, duplicate watchers, conflicting schemas — is what a *second graph engine* causes, not what a second *consumer* of this one causes.
2. **One graph surface per session.** A session sees exactly one CodeGraph interface. Pi uses the native bridge or the MCP proxy, never both; a foreign worker receives one exported server and never a second. Two schemas for one capability in one prefix is a context and ambiguity cost, and that is the invariant worth keeping.
3. **One authority for graph questions.** CodeGraph answers architecture, callers, callees, dependencies and blast radius. No GitNexus, no second graph, no code-focused RAG. Unchanged from ADR-008.

Consequently **graph access is a per-profile grant, not a property of the process that asks**. Pi's parent and its native children receive the graph through the Pi-native surface; a foreign worker receives the CodeGraph MCP server in its generated export when its phase needs the graph, exactly as `docs/01` §3.2 already permits for the Pi Lens MCP mirror — that mirror exists precisely for hosts lacking the native lifecycle integration, which is what a foreign CLI is.

Which Pi-native surface is used is a **measured** choice, not a stated one. `@vndv/pi-codegraph` registers eight named tools (`codegraph_search`, `_node`, `_files`, `_callers`, `_callees`, `_impact`, `_explore`, `_status`), each proxying one request to `codegraph serve --mcp`; the engine's own MCP surface defaults to a single `codegraph_explore` tool with the rest opt-in via `CODEGRAPH_MCP_TOOLS`. Eight schemas in the frozen prefix against one is a real cost, and the named operations map onto the routing policy in a way one general tool does not. The capability compiler decides from the measured prefix cost and the routing traces, not from preference.

The bridge is a thin proxy over the engine's MCP server and does not run its own watcher or index, which makes its failure mode cheap: if it lags the engine or is abandoned, CodeGraph is consumed through the lazy MCP proxy we already own, with no change to invariants 1–3 and no code to write (R-103).

**Reason:** the graph is the coding foundation, so restricting it to one process class would make every delegated phase structurally weaker at exactly the work worth delegating — a reviewer that cannot see blast radius is reviewing text. The engine's daemon-and-socket design already provides the property the blanket rule was trying to protect, so the rule cost capability and bought nothing.

**Rejected:** a second graph engine of any kind; two graph surfaces inside one session; a per-worker CodeGraph index or watcher; graph access as an ambient property of any agent rather than a declared profile grant; keeping the blanket MCP prohibition now that its stated harm is known not to occur.

### ADR-046 — The parent runs `openai-codex/gpt-5.6-luna`; OpenRouter is a scouting route, not the main one

**Status:** Accepted (7 August 2026); settles D1 and D2; implements the pin requirement in ADR-035 and `10` §10.3

The parent Pi session reaches its model through the direct **`openai-codex`** OAuth route, pinned to the exact ID **`gpt-5.6-luna`** at thinking level `medium`. OpenRouter remains authenticated and is used only for specific scouting queries where a second vendor's model is the point of the query; its default there is the exact dated ID **`deepseek/deepseek-v4-flash-0731`**, never the `~deepseek/deepseek-v4-flash-latest` alias and never the rolling `deepseek/deepseek-v4-flash` pointer.

The route is decided by capability, not by price — which matters because on this workstation's catalog OpenRouter is the *cheaper* route for the same model ($0.10/$0.60 against $0.20/$1.20 per Mtok) and offers 1.05M context against 272k. What it does not offer is deferred tool loading. Every model in the `openai-codex` catalog declares `compat.supportsToolSearch` and `supportsOpenAIGrammarTools`; **none of the 273 OpenRouter models declares either**. Tool search is Pi's mechanism for changing a tool surface additively, and the parent is the one session whose surface is meant to grow — the MCP lazy proxy, the graph surface, the skill catalog all arrive mid-life. Choosing the cheaper route would commit us permanently to ADR-034's fallback, a fixed tool surface for the whole epoch, in exchange for a window the parent is designed never to reach.

Two smaller properties follow the same way. `openai-codex-responses` is a first-party API surface and the one Pi's own `showCacheMissNotices` already reads, where OpenRouter is `openai-completions` behind a third party — one more place ADR-035's three separate token counters can arrive as a single combined number. And grammar tools, declared only on the direct route, are the cheapest path to the typed envelopes the gates consume.

The parent runs the cheap-fast tier rather than a stronger one, which is the opposite of what the dossier's framing suggested and is decided deliberately. The argument for a strong parent — it authors envelopes no gate checks, so its errors are the invisible ones — is real, and it is answered by keeping the parent's work small rather than by buying a larger model: the parent owns state and delegation, and every phase whose *quality* is load-bearing is routed to a worker under a compiled profile (ADR-042), where a gate does check it. Caching suppresses the parent's input cost and does nothing for its output, so a stronger parent is a real recurring cost against a benefit this architecture already obtains elsewhere.

**Reason:** the pin is part of the frozen prefix, so it must be exact and it must be chosen for the properties the prefix depends on. Tool-search support is the only property in this comparison that cannot be bought back later by configuration.

**Rejected:** OpenRouter as the parent route despite its lower price and larger window; `gpt-5.6-terra` or `gpt-5.6-sol` as the parent; any alias or rolling pointer as a recorded model ID; the `openrouter/free` router, which selects a different backing model per request and is therefore incompatible with a frozen prefix by construction.

**Contingent on one fact:** `supportsToolSearch` was read from Pi 0.80.10's catalog. If the V0.1-T2 upgrade to 0.84.x declares tool search for OpenRouter models, this ADR is reopened, because the reason for accepting the worse price and smaller window would no longer hold (R-105).

### ADR-047 — We evaluate our tooling, never models

**Status:** Accepted (7 August 2026); amends ADR-041 by exclusion; supersedes the comparison plans in ADR-019's orbit

No work in this project benchmarks, ranks or comparatively evaluates language models. Model choice is made once, recorded as a pin with its reason, and revised when a stated property changes — not by running a task against several models and reading the scores. Where a plan step previously required a model comparison to proceed, that step is removed rather than deferred.

What remains measured is **our own tooling**, and only where a number changes a decision: the cache regression gate (V0.3-T9), prefix and token budgets, the parity gate's dual run against the environment actually in daily use (ADR-041), and any tool-integration A/B where two components would otherwise both be installed to do one job. These measure components we build or install, not vendors' models.

**Reason:** model evaluation is expensive, ages within weeks, and answers a question this design deliberately does not ask — the architecture routes work by phase to a profile, so its correctness comes from gates and envelopes rather than from having picked the best model. A comparison plan embedded in a task file is a blocking dependency on work nobody intends to do, which is worse than an unmeasured pin.

**Rejected:** the D2 settling test (running the V0.4 bootstrap task per parent class and comparing accepted-first-time rate); a continuity benchmark as the precondition for a separate compaction model — the separate compaction model is simply not used; any "measure and then choose the model" step as a gate on a version.

### ADR-048 — Project-knowledge RAG belongs to the remote tier, not to the coding harness

**Status:** Accepted (7 August 2026); supersedes the local-RAG placement in ADR-010 and ADR-040's layer table; settles D6

There is no RAG in the execution layer. `knowledge_search` and `knowledge_get` are not part of the coding harness, no local index is built over `docs/`, and **no local embedding model is installed**. The project-knowledge corpus becomes a service in the remote tier at V0.7, alongside the MCP registry and memory service, and the contract in ADR-010 describes that service when it is built rather than something local that precedes it.

ADR-010's ownership rule is unchanged and still binding: RAG owns authoritative prose, CodeGraph owns relationships, Hermes owns reviewed procedures and episodes, and source code is not re-indexed to duplicate the graph. What changes is *where and when* — placement, not ownership.

This costs the execution layer one capability, and the cost is smaller than it looks: the corpus is this repository's own `docs/`, the harness works inside the repository with `read`, `grep` and the vendored `rg`, and the questions a RAG would answer are answerable by reading files the agent already has. Retrieval earns its dependency when the corpus outgrows direct reading or lives somewhere the agent cannot open — both of which are remote-tier conditions.

**Reason:** an embedding model, an index and an engine are three components with a lifecycle, a staleness failure mode and a duplicate-index risk (R-025, R-039), bought at V0.2 to query documents the agent can already open. Deferring it removes the largest unowned selection decision from the execution layer without removing anything the harness does.

**Rejected:** any local embedding model or vector store; `qmd`, LanceDB or Chroma as a V0.2 component; an FTS5-only local index as a stepping stone, which would still be an index to build, own and invalidate; treating `docs/11`'s "one local RAG" row as still current.

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
| Remote service tier before delegation | Hosting location adds no capability; it blocked the work that actually closes the gap with the current environment | Execution layer local and complete first; the server hosts services after the switch (ADR-040) |
| V0.4 is the switch point because the system can commit | Self-hosting and being the better tool are different properties; a harness with no delegation, web access or diff view is not one to switch to | Measured parity gate at V0.6, per workload, reversible (ADR-041) |
| Foreign CLIs as a late delegation nicety | Routing a phase to the best available model is a large part of parity, and the review-differs-from-implementer rule is worth most across vendors | Compiled provider profiles in the execution layer, before the switch (ADR-042) |
| Foreign harnesses accept vendor defaults | A vendor CLI re-derives with its own tools what this system already owns better, at a measured ~33k-token prefix | Registry-generated MCP exports, tool removal, hook enforcement, measured prefix (ADR-043) |
| PTY adapters first, ACP later | ACP adoption changed and Codex's headless JSON already satisfies the envelope contract without either | Structured headless, then ACP, then PTY (ADR-044) |
| CodeGraph must never be exposed through MCP | The stated harm is caused by a second engine, not a second consumer; the engine shares one daemon and one watcher across sessions by design | One index and one daemon; one graph surface per session; graph access as a per-profile grant (ADR-045) |
| Route chosen on price and context window | The only property that cannot be bought back later by configuration is deferred tool loading, and one route declares it | Direct `openai-codex` route despite being dearer and smaller; OpenRouter for scouting only (ADR-046) |
| Buy a stronger parent because its errors are ungated | Correct diagnosis, wrong remedy — quality-bearing phases route to profiled workers where a gate does check them, and caching suppresses only the parent's input | Parent on the cheap-fast tier; quality bought per phase (ADR-046) |
| Choose the parent model by running a task against each | Model evaluation ages within weeks and gates a version on work nobody intends to do | Pin with a stated reason; evaluate our tooling only (ADR-047) |
| One local RAG in the execution layer | Three components with a staleness and duplicate-index failure mode, bought to query documents the agent can already open | No RAG, no embedding model locally; project knowledge is a remote-tier service at V0.7 (ADR-048) |
