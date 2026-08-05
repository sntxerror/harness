# Ultimate Pi Setup — Idea Evolution and Experiment Backlog

This document preserves how the design evolved, including promising ideas that are not part of the recommended starting stack. It is intentionally broader and less authoritative than `ultimate-pi-setup-plan.md`.

The point is to remember *why* an idea moved, not to keep every idea alive. Current decisions live in `ultimate-pi-architecture-decisions.md`; unresolved failure modes live in `ultimate-pi-risks-gaps-overlaps.md`.

## The design in one sentence

The concept evolved from “equip Pi with every useful extension” into “make Pi a precise, cache-stable execution frontend whose small set of authoritative services can also be shared safely with specialist native and foreign workers.”

## Evolution of the architecture

### Phase 0 — Pi as part of an eventual Agent OS

The long-range idea is larger than a single terminal agent:

- Pi is the primary interactive coding frontend.
- A future VS Code/Phi-style frontend may use the same underlying services.
- Claude Code, Codex CLI and possibly Antigravity are specialist execution harnesses, not mere models.
- Hermes may eventually coordinate server workers and learned procedures.
- CodeGraph, project knowledge, evaluation data and model availability can be shared services.
- Conversation history, live task state, credentials and cache epochs must not bleed between Terminal Pi, VS Code or remote workers.

This led to the service/API boundary: share versioned services and reviewed knowledge, not one mutable prompt directory, session database or memory file.

### Phase 1 — Broad ecosystem survey

The initial brainstorm considered Pi Lens, standalone LSP packages, CodeGraph/GitNexus, local RAG, LeanCTX, Hermes, todo/planning extensions, subagent packages, shell compressors, alternative editors, sandbox packages, MCP bridges, browser tools, tracing and forks such as Oh My Pi.

The key realization was that adding all of them would create more duplicate indexes, watchers, tool schemas, automatic hooks and failure modes than actual capability. The architecture therefore adopted one authoritative owner per responsibility and required measurable advantage for any duplicate.

### Phase 2 — Context cleanliness and native compaction

Questions about `reserveTokens`, `keepRecentTokens`, the 2,000-character per-tool-result serialization limit and LeanCTX changed the plan:

- Pi-native compaction remains the single conversation-continuity mechanism.
- Compaction policy may vary by model and task class, but it is selected deterministically once at session start.
- A separate cheap summarization model is technically plausible through Pi's compaction hook, but only after a continuity benchmark proves it.
- Tool output should be reduced *before insertion* because later conversation compaction cannot recover data already omitted from its serialization.
- LeanCTX is not a replacement for Pi compaction in this stack; only its delta/read/output ideas remain an experiment.

This separated three often-confused layers: command-output reduction, conversation compaction and cross-session memory.

### Phase 3 — Permissions, risky actions and real user interaction

The desired UX is broad autonomy without a giant hand-maintained whitelist:

- allow ordinary Bash, edits and repository work;
- ask for risky destructive, privileged, credential, external-side-effect or containment-changing actions;
- do not blanket-deny deletion;
- let the user type sudo passwords in a real interactive terminal;
- never pass a password through chat or `sudo -S`;
- give specialist subagents narrower paths/tools/commands where appropriate.

This clarified that permission-system and interactive-shell solve different problems. Permission-system decides whether an intent may start; interactive-shell supplies the PTY and human takeover. `pi-safe-shell` is an alternative policy owner, not an additional layer for the normal profile.

It also exposed a deeper rule: permissions are UX and intent control, while Gondolin/container/OpenShell is the security boundary.

### Phase 4 — Immutable capabilities and cache behavior

Concerns about cache invalidation led from conventions to enforcement. A cache-friendly session cannot let agents algorithmically toggle containment, tools, policies, system instructions or credentials mid-session.

The resulting concept is `pi-session-control`:

- compile an `AgentProfileV1` and `SessionCapabilitySnapshot` before the first request;
- advertise only tools, skills, commands, MCP services and credentials that actually exist;
- freeze permissions, mounts, network, executor, model/provider, system prompt and ordered base tool schemas for the cache epoch;
- allow only measured additive tool activation where the provider preserves the prefix;
- create a new child session/cache island when a different model or capability set is needed;
- refuse attempts to reload or mutate control-plane policy from inside the session.

The important shift was from “tell the model not to call unavailable things” to “make unavailable things absent and return deterministic capability errors at the executor boundary.”

### Phase 5 — Precise specialist profiles and smart routing

Smart routing originally sounded like swapping models depending on each task. That would damage the parent's stable cache prefix and blend specialist instructions into one session.

The refined design routes *tasks to child cache islands*:

- a static specialist profile contains role prompt, capabilities, model/provider, tools, skills, permissions, MCP exports, validation contract and sandbox policy;
- a dynamic task envelope contains objective, inputs, constraints, expected output, working directory, branch/worktree and deadlines;
- the task envelope is appended as a user message, never spliced into the stable system prompt;
- a cheap deterministic router starts with rules and observed task classes; a learned router comes only after traces justify it.

Native Pi subagents are best when tight lifecycle/tool integration matters. Foreign harnesses are selected when their bundled workflow, subscription or provider-specific strengths materially help.

### Phase 6 — Foreign harnesses must remain human-accessible

An unattended Claude/Codex/Antigravity process still needs a way to ask a question, request approval or hand control to the user. A fire-and-forget subprocess is therefore insufficient.

The idea evolved into three modes:

- **Attended:** open/focus the terminal immediately; the user can type.
- **Supervised background:** run independently, notify on structured question/risk, and remain attachable.
- **Batch:** no interactive dependencies; fail with a structured blocker instead of waiting forever.

`pi-interactive-shell` is the prototype for direct PTY, dispatch, worktree and takeover. A final `agent_delegate` component uses a private tmux server, durable process registry, single input lease, normalized question events and bounded artifacts. Pi should expose task-level operations—not arbitrary tmux commands.

### Phase 7 — MCP sharing without an MCP explosion

The desire for CLI subagents to use the same useful MCPs as Pi produced a canonical registry/export design:

- define each remote/stateful service once;
- generate role/task-specific client configs for Pi, Claude, Codex and supported harnesses;
- export read-only subsets and scoped credentials by default;
- let the parent perform one-off retrieval and pass evidence when direct child access is unnecessary;
- give a child direct access only when repeated interactive use is more efficient or correct;
- never mirror Pi Lens, CodeGraph, local Bash/filesystem or local CLIs through MCP merely for uniformity.

MCP became a remote-service boundary, not the universal internal bus.

### Phase 8 — Code intelligence consolidation

The earlier idea used a standalone Pi LSP and considered Pi Lens as an optional audit profile. Source inspection showed that current Pi Lens provides useful native diagnostics and focused symbol-reading/navigation with configurable context injection and mutation.

The current direction is:

- CodeGraph owns cross-file relationships, architecture and impact;
- native Pi Lens owns exact LSP diagnostics/navigation/read coverage;
- `ast-grep` CLI owns structural search and codemods;
- repository-native tools own format/lint/typecheck/test;
- Pi Lens context injection, formatting and autofix start disabled;
- its overlapping graph, broad identifier search and AST-write tools are filtered;
- its MCP mirror is never connected back into the same Pi.

This is a change from the original plan and remains contingent on proving exact active-tool filtering.

### Phase 9 — Task state, skills and completion discipline

The todo package initially looked like a baseline planning improvement. Further analysis showed that it could become a second changing recap, compete with Pi's plan/conversation and encourage child-local task stores.

Current view:

- the parent conversation/plan owns ordinary current-task state;
- `rpiv-todo` is an optional parent-only trial for long missions with durable dependencies;
- skills are discovered progressively from compact metadata and loaded only when the task/capability requires them;
- a specialist never sees a skill it cannot execute;
- `project_check` is the single repository-native completion gate.

### Phase 10 — Git, changelog and documentation become part of completion

The desired workflow requires every agent-authored committed change set to have:

- a concise entry prepended to root `CHANGELOG.md` under the configured section;
- a compact validated commit message;
- updated documentation when public behavior, configuration or workflow changed;
- validation against the exact staged contents.

The design avoids generative Git hooks. A parent-owned `commit-prepare` command inspects the staged diff, runs `project_check`, determines documentation impact, generates/validates text, updates files, re-stages and emits a receipt. Hooks only verify deterministic invariants. Foreign children return changes; they do not compete to finalize the commit.

### Phase 11 — Hermes is memory and coordination, not a universal replacement

The idea of putting Pi and other agents behind Hermes on a server remains valuable, but “shared memory and self-improvement” needed boundaries:

- project RAG remains the authority for documents, ADRs, decisions and curated notes;
- CodeGraph remains the authority for code relationships;
- Pi compaction remains the authority for the active conversation;
- Hermes later stores reviewed procedures, preferences, episodic outcomes and candidate skills;
- workers submit candidates instead of mutating shared memory directly;
- self-improvement means proposal, replay/evaluation, review, staged rollout and rollback—not automatic prompt/policy mutation.

Hermes can eventually schedule ephemeral Pi/Claude/Codex workers, but it does not collapse all frontend sessions into one memory stream.

## From early idea to current direction

| Early idea | What we learned | Current direction |
|---|---|---|
| Install many high-value extensions together | Tool schemas, hooks, watchers and indexes compound | One owner per responsibility; packages start with automatic behavior disabled |
| One very capable profile | It grants unnecessary authority and destabilizes cache/tool surface | Separate trusted, isolated, read-only and specialist profiles |
| Swap the parent's model by task | Model/provider/prompt changes break the parent's cache island | Spawn a child with a compiled static profile and dynamic task envelope |
| Permission prompts provide safety | Prompts do not contain extension subprocesses or hostile repos | Permission-system for UX; containment as the boundary |
| Safe shell plus permission package is safer | Two parsers and UIs cause conflicts and nagging | permission-system alone; safe-shell only in an alternative profile |
| Interactive shell and subagent tools overlap completely | PTY/user interaction and task delegation are different layers | Direct PTY for human/sudo; broker for durable delegated harnesses |
| Todo package by default | It can duplicate plan/compaction state | Parent plan first; todo only after repeated trace evidence |
| Standalone LSP plus optional Pi Lens | Pi Lens can be the native LSP surface if constrained | Pi Lens conservative mode; no second LSP/self-MCP |
| LeanCTX handles compaction | Its broad feature set overlaps multiple owners | Pi-native compaction; LeanCTX only a pre-insertion delta/output trial |
| Native compaction is “stupid” | Its lifecycle is correct and extensible, but input serialization is lossy | Keep Pi ownership; improve tool envelopes and optionally the one summarizer hook |
| Hermes can replace local RAG | Episodic/procedural memory differs from authoritative documents | RAG plus Hermes with disjoint record types |
| Every child should inherit all parent MCPs | Most tasks need fewer services and credentials | Generated per-role/task exports from one registry |
| Foreign agent can run as a background command | Questions and approvals can deadlock; crashes orphan work | Attended/supervised/batch modes with attachable tmux broker |
| Let agents adapt permissions/containment | Mid-session mutation defeats cache and security invariants | Immutable session snapshot; new session for different authority |
| Hooks can generate changelog/commit text | Mutating hooks are surprising and hard to reproduce | Parent preparation command generates; hooks validate |
| Shared Agent OS means shared state | Mutable shared session state causes context bleed and races | Shared versioned services; distinct sessions/cache/task state |

## Active experiment backlog

These are plausible enough to test after the baseline is stable.

### E-001 — Conservative Pi Lens surface

**Hypothesis:** Pi Lens improves exact diagnostics and focused symbol understanding without meaningfully duplicating CodeGraph or `ast-grep` when context injection and mutation are disabled.

**Test:** measure active schema tokens, startup processes, diagnostics correctness, symbol navigation, graph/AST-tool exclusion and upgrade stability across representative repositories.

**Promote if:** filtering is enforceable before first request, no duplicate LSP/index exists, and it materially reduces navigation/error cycles.

### E-002 — Deterministic compaction policy profiles

**Hypothesis:** a small table keyed by context-window bucket and task class outperforms universal `reserveTokens: 16384` / `keepRecentTokens: 20000` without a routing model.

**Test:** replay long coding, research and delegation sessions; measure premature compaction, completion headroom and continuity.

**Promote if:** at least one non-default policy wins consistently and selection remains fixed per session.

### E-003 — Dedicated compaction summarizer model

**Hypothesis:** a cheap model can produce the one Pi-native structured summary at lower cost without losing requirements or evidence.

**Test:** blind compare constraint/decision/failure/provenance retention against the active model and native default; inject cancellation and invalid-output failures.

**Promote if:** quality threshold is met and fallback is deterministic. Do not promote based on price alone.

### E-004 — RTK output interceptor

**Hypothesis:** RTK reduces noisy common command output while preserving decisive errors and exit semantics.

**Test:** repository command corpus including failures, warnings, test flakes and binary/noisy output; compare raw versus compact conclusions.

**Promote if:** no material diagnostics are lost and raw artifacts remain cheaply retrievable.

### E-005 — LeanCTX narrow delta/read profile

**Hypothesis:** signatures, unchanged-file suppression or deltas reduce repeated file cost beyond RTK and focused reads.

**Test:** isolated profile with graph, memory, agents, permissions, editing and conversation compaction disabled; measure billed input and answer quality.

**Promote if:** it wins against the baseline on real traces. If shell rewriting is enabled, RTK must be disabled.

### E-006 — Alternative hashline editing

**Hypothesis:** a line-hash editing tool can reduce stale-offset and ambiguous patch failures.

**Test:** golden corpus for concurrent edits, repeated lines, Unicode, CRLF, large files and partial failures; compare against Pi built-in edit.

**Promote if:** failure rate is materially lower without adding a second normal edit path.

### E-007 — Attachable foreign-agent broker

**Hypothesis:** task-level delegation to subscription-backed Claude Code and Codex improves specialist outcomes while the user retains visibility and control.

**Test:** attended, supervised and batch runs; structured questions; sudo prohibition/approval; focus takeover; crash recovery; worktree isolation; scoped MCP; artifact return.

**Promote if:** no run can wait invisibly, escape its profile, or lose its terminal/process identity.

### E-008 — Rule-based smart router

**Hypothesis:** transparent routing based on task class, risk, repository size, required tools and latency/cost can select useful specialists without an LLM router.

**Test:** log human override, success, retries, cost/time and validation results; compare always-parent baseline.

**Promote if:** rules have repeatable wins. A near-free model router is a later challenger, not the starting point.

### E-009 — RAG/CodeGraph evidence fusion

**Hypothesis:** some architecture/design questions benefit from one bounded result containing code relationships plus authoritative decisions.

**Test:** only queries that currently require repeated manual dual retrieval; fuse IDs/previews with provenance, not full documents.

**Promote if:** traces show repeated need and improved correctness without creating a third index/router authority.

### E-010 — Parent-only durable task state

**Hypothesis:** `rpiv-todo` helps long missions with dependencies that cross compaction.

**Test:** compare missed steps, duplicated work and context injection for complex tasks; keep children stateless and do not auto-inject full lists.

**Promote if:** it solves a measured continuity gap that typed Pi compaction fields do not.

### E-011 — Canonical MCP exporter

**Hypothesis:** generated task-scoped configs let children directly use repeated remote/stateful services more correctly than parent-mediated excerpts.

**Test:** installed Claude/Codex clients first; compare startup/schema overhead, credential scope and result quality; validate config hashes.

**Promote if:** direct use is repeated and no native/local duplicate is introduced.

### E-012 — Hermes procedural memory

**Hypothesis:** reviewed procedures and outcome memories improve future task execution beyond project RAG and compaction.

**Test:** candidate capture, contradiction, revocation, replay and cross-worker retrieval; measure harmful/stale suggestions as well as hits.

**Promote if:** namespace/provenance controls work and reviewed memory improves evaluated repeats.

## Parked ideas

These may become useful after corresponding evidence appears.

- A learned/LLM model router trained from successful delegation traces.
- Backend routing inside one specialist profile where providers have genuinely interchangeable cache contracts.
- A compact UI showing cache epoch, context budget, active tools, policy, checks and broker sessions without model injection.
- DAP integration after LSP/repository diagnostics show a repeated debugging gap.
- Browser/research workers with a narrow evidence-citation protocol and isolated credentials.
- Shared remote CodeGraph/RAG services for ephemeral server workers after project identity and concurrency semantics are proven.
- A VS Code frontend using the same profile compiler, project checks and service registry while retaining its own session.
- Automatic creation of candidate skills from repeated reviewed procedures, never direct activation.
- An explicit `completion_gate` wrapper if `project_check` plus commit preparation proves insufficient.
- Provider-specific prompt/cache adapters if normalized payload traces reveal large avoidable misses.
- Remote user-question delivery for server workers through a notification/UI service.

## Rejected for the normal setup

- An all-in-one Pi fork merely to acquire a bundle of overlapping features.
- Multiple LSP clients, code graphs, source-code RAGs or automatic post-edit systems.
- Eager exposure of every MCP server/tool to every model and subagent.
- MCP wrappers for local filesystem, Bash, Pi Lens, CodeGraph or a CLI already reachable more cleanly.
- Per-turn automatic project, memory, todo, graph or diagnostics dumps.
- Full LeanCTX alongside Pi compaction, CodeGraph, RAG, Hermes, RTK and native tools.
- `pi-safe-shell` and permission-system in the same profile.
- Multiple generic shell/terminal tools visible to the model.
- `sudo -S`, agent-readable passwords, persistent root shells or unattended sudo prompts.
- Algorithmic in-session containment, permission, model, provider, system-prompt or base-tool switching.
- Child profiles created only through natural-language instructions rather than capability enforcement.
- A foreign harness without attach/focus/question/cancel behavior.
- Sharing one writable memory/config/session database among workers.
- Silent memory promotion or autonomous prompt/policy/skill self-modification.
- LLM calls from Git hooks or hooks that silently mutate files.
- Child and parent both committing/finalizing the same worktree.
- Treating a package's popularity or MCP exposure as proof of value.

## Brainstorm cards that still need definition

### Dynamic compaction controller

Possible design: compute context-window bucket, expected tool-output class, task mode and provider output reserve at session creation; choose a named policy; optionally compare against a cheap model's recommendation in logs without following it. Only a new session can change the policy. The model should not receive a tool that rewrites thresholds.

Unresolved: sufficient trace volume, model context metadata accuracy, and whether provider output limits—not context window—become the dominant reserve constraint.

### Structured continuity extension

Possible design: a Pi-native `session_before_compact` adapter that produces one summary with stable sections/fields:

- goals and acceptance criteria;
- invariant constraints and permissions;
- decisions and reasons;
- changed files/worktree/HEAD;
- commands/checks and outcomes;
- unresolved failures/risks;
- artifact, RAG, CodeGraph and broker-session references;
- task-state snapshot and next actions.

It can use Pi's default summarizer or an evaluated separate model. It must not create a second recap stream, retrieve arbitrary memory automatically or prune wire history independently.

### Capability-aware skill discovery

Possible design: index only skill name, description, version, declared tools/commands/MCP/paths and risk class. Filter metadata against the frozen capability snapshot. Load the full body only after task match or explicit selection. Validate that every referenced capability exists. Record skill ID/version in traces and compaction.

Unresolved: canonical metadata extension, conflict resolution between repository/user/global skills, and whether a selected skill may add a tool schema without starting a child/new cache epoch.

### Unified output coordinator

Possible design: command-class adapters emit a structured envelope with command, cwd, exit status, duration, bounded stdout/stderr synopsis, diagnostics, changed files and raw artifact reference. AST-aware summarization may help compiler output only when a mature parser exists; it should not be a generic lossy “AI summary.”

Unresolved: artifact retention, secret redaction, terminal progress streams and binary output.

### Capability broker for isolated intelligence

Possible design: run CodeGraph/RAG/LSP services outside a worker but expose narrowly typed read-only repo-relative methods bound to repository/worktree identity. This avoids duplicating heavy indexes while not granting arbitrary host filesystem access.

Unresolved: whether LSP's stateful filesystem assumptions make a narrow broker less reliable than simply running it in the guest; path/symlink races; service tenancy.

### Server-side self-improvement loop

Possible design: Hermes observes structured outcomes, proposes a procedure/skill/router-policy candidate, replays it on a frozen evaluation set, submits evidence for review, promotes a versioned artifact to a canary profile, and rolls back automatically on regression.

Hard boundary: it may never directly modify permission, containment, credential or immutable cache-contract code; those changes require a separate human-controlled engineering release.

## What should trigger reopening a rejected or parked idea

Reopen an idea only when traces show one of the following:

- repeated failure that the current authoritative owner cannot solve;
- repeated high token/runtime cost attributable to a measured component;
- repeated manual handoff or retrieval pattern suitable for deterministic automation;
- an upstream package gains a stable capability that removes a custom component;
- a provider or Pi lifecycle change materially alters cache/tool behavior;
- a security test disproves an assumed boundary;
- a real project class requires a capability absent from the current profiles.

When reopened, create a separate evaluation profile, define the challenger and baseline, record quality/cost/reliability/security metrics, and either promote one owner or close the experiment. Do not leave both active indefinitely.
