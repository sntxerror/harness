# Ultimate Pi Setup — Architecture Decisions

Revision: 22 July 2026

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

## Superseded directions

| Earlier direction | Why it changed | Current decision |
|---|---|---|
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

