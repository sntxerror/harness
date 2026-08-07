# 11 — Execution Layer, Agentic Layer and the Switch

Status: accepted design, 7 August 2026. Implements ADR-040 and ADR-041. This document draws the line between the two layers of the system, states what "the execution layer is finished" means, and defines the measured gate at which daily development moves off VS Code + Claude Code and onto the harness.

## 1. Why the line exists

The plan up to this revision described one continuous sequence from a local Pi session to a server-resident control plane with personas, missions, schedules and a web UI. Every stage in it was justified, but the sequence had no point at which the thing being built became better than the thing being used to build it. Remote provisioning appeared at V0.5, before delegation; mission control and cross-session learning appeared before the harness could run a foreign CLI or answer a web question. The result was a long stretch of work whose output was infrastructure rather than leverage.

The line below fixes that by separating what makes *one task* run well from what makes *many tasks* run without a human present. The first is the execution layer, it is entirely local, and it is the whole of the near-term plan. The second is the agentic layer, and none of it starts until the first is the daily driver.

## 2. The line

| Concern | Layer | Owner |
| --- | --- | --- |
| Interactive session, tools, permissions, PTY | Execution | Pi upstream + permission-system + interactive-shell |
| Code intelligence: graph, LSP, AST, lexical search | Execution | CodeGraph, Pi Lens, `ast-grep`, and Pi's vendored `rg` — which lives in the profile's `bin/`, not on `PATH` (R-106) |
| Project knowledge retrieval | **Agentic** | Remote knowledge service at V0.7 (ADR-048) — the execution layer reads `docs/` directly |
| Correctness evidence | Execution | `project_check` on the shared `Executor` |
| Capability truth, cache contract, skill catalog | Execution | `pi-session-control` |
| Context economy: compaction, tool-output bounding, lean reads | Execution | Pi compaction + pre-insertion filters |
| Workflow sequencing, gates, run acceptance | Execution | `pi-factory` |
| Commit, changelog and documentation finalization | Execution | Parent-only skill + hooks |
| Delegation inside one machine: subagents, worktrees | Execution | `@gotgenes/pi-subagents` + worktree companion |
| Foreign CLI workers (Claude Code, Codex, Antigravity) | Execution | Session broker + provider adapters (`12`) |
| Local MCP: canonical registry, lazy proxy, per-task exports | Execution | `pi-mcp-adapter` or its fallback class |
| Session portability between harnesses | Execution | `PortableSessionBundleV1` exporter |
| Scheduling and unattended dispatch | Agentic | Mission orchestrator |
| Cross-session durable knowledge and learning | Agentic | Memory service + candidate pipeline |
| Personas as schedulable identities; mission board | Agentic | Persona registry + board |
| Remote interfaces: IM gateway, web mission control | Agentic | Gateway + DAW UI |
| Multi-runner placement, leases, registration | Agentic | Control plane |
| Containerized deployment and forge | Agentic | Packaged topology |

Two boundary cases are settled explicitly because they look like they belong to both:

**A worker is not an agentic component.** Spawning a Claude Code process in a worktree to execute one phase of one run is delegation, not orchestration: the run is already scheduled, the human is already present, and the result is consumed by a gate that exists in the execution layer. Foreign CLI workers therefore ship in the execution layer, and they ship *before* the switch, because the ability to route a phase to the best available model is a large part of what makes the harness competitive.

**Remote is a deployment property, not a capability.** Every execution-layer component runs locally and is complete when it works locally. Hosting the MCP registry, the RAG or the memory service on the existing server changes where a process runs and changes nothing about what the harness can do. The server therefore moves behind the switch, and `docs/07` becomes a runbook consulted at that point rather than a Phase 0 obligation.

## 3. What "the execution layer is finished" means

Finished is not "all stages implemented". It is the conjunction of four properties, each of which has a test somewhere in the version's task file:

1. **One task runs end to end inside the harness** — intake, recon, plan, implement, check, review, commit — with evidence that survives inspection and a commit that no path can produce without a fresh receipt.
2. **The model works against real code intelligence**, not against `grep` and hope: definitions and references come from the LSP, architecture and blast radius from the graph, structural edits from `ast-grep`, and the routing between them is measured on five representative questions. Decisions come from reading `docs/` directly — retrieval is a remote-tier service at V0.7 (ADR-048), and its absence is a recorded position rather than an unfilled row.
3. **The context economy is measured, not asserted** — a frozen prefix that something checks, cache reads that appear in traces from the second request onward, a skill catalog costing metadata only, and an MCP surface within its stated budget.
4. **Work can be delegated** to a parallel worktree child or to a foreign CLI under a compiled profile, and the result returns as a typed envelope that a gate can reject.

## 4. The parity gate

The earlier plan named V0.4 "the switch point" on the reasoning that once the system can commit its own changes, it should. That conflates *self-hosting* with *being the better tool*. A harness that can commit is not yet a harness worth using if it has no delegation, no web access and no editor. The switch is therefore a separate, later, measured event with its own version (V0.6) and its own exit criteria.

### 4.1 Capability parity matrix

Parity is assessed against the actual daily environment — Claude Code driven from VS Code — not against an idealized agent. Each row names our owner and the version that delivers it. A row marked **gap** has no owner in the current plan and is an open decision in the dossier (`docs/reviews/2026-08-07-open-decisions-dossier.md`).

| Claude Code capability in daily use | Our owner | Available |
| --- | --- | --- |
| Interactive streaming TUI, interruption, steering | Pi upstream | V0.1 |
| Read, write, edit, glob, grep, ls | Pi built-ins (one owner per tool) | V0.1 |
| Bash with per-command approval | permission-system intent gate | V0.1 |
| Privileged commands and password entry | `interactive_shell` interactive mode (ADR-037) | V0.1 |
| Structured questions to the user | Our native `ask_user_question` on Pi's dialog primitives (ADR-049) | V0.1 |
| Session resume and automatic compaction | Pi native compaction (ADR-012) | V0.1 |
| Semantic navigation, diagnostics, rename | Pi Lens conservative mode | V0.2 |
| Architecture, callers, blast radius | CodeGraph | V0.2 |
| Repository validation as the definition of done | `project_check` | V0.2 |
| Skills with progressive disclosure | `skill-capability-filter` + `.agents/skills/` | V0.3 |
| Hooks / deterministic enforcement around tools | Pi lifecycle + session-control guards | V0.3 |
| Plan mode | `pi-factory` `plan` workflow | V0.4 |
| Todo / task state across a long task | Parent conversation; optional parent-only todo | V0.4 |
| Git workflow, commit messages, changelog | Commit finalization transaction | V0.4 |
| Subagents with distinct roles and models | Compiled `AgentProfileV1` children | V0.5 |
| Background tasks with attach/detach | Session broker, supervised mode | V0.5 |
| MCP servers | Canonical registry + one lazy proxy | V0.5 |
| Access to a second frontier model for review | Foreign CLI workers (`12`) | V0.5 |
| Web search and page fetch | **gap** — no owner in the plan | Decide by V0.6 |
| Image and screenshot input | **gap** — Pi support unverified | Decide by V0.6 |
| Editor integration: diffs, selection context, file open | **gap** — ACP bridge or VS Code Remote | Decide by V0.6 |
| Checkpoint / rewind of a session | Deferred (plan Stage 13 backlog) | Post-switch |

The three gaps are the substantive finding of this revision. Two of them (web access, editor integration) are used daily in the current environment and were absent from the Outcome table in `docs/01`; a switch declared without them would be a downgrade dressed as progress.

### 4.2 Measured criteria

Capability coverage is necessary and not sufficient. The gate additionally requires, over a dual-run period of at least ten working days in which the same real tasks from `tasks/` are attempted in both environments:

| Criterion | Threshold | Evidence |
| --- | --- | --- |
| Task completion | Harness completes ≥ 90% of the tasks Claude Code completes, on the first attempt or after in-session correction | Factory run records with `finish_run(accepted)` |
| Correctness | No task accepted by the harness fails `project_check` afterwards | Receipt/tree-hash binding |
| Cost | Median cost per accepted task ≤ Claude Code's, counting foreign-worker spend | Per-run token/cost events (`10` §8) |
| Latency | Median wall clock within 1.5× | Run start/end events |
| Interaction | Every stall produced either a structured question or an attachable session; no silent hang | Question broker records |
| Recovery | A killed runner resumes the run from artifacts without losing accepted phases | Kill/recover test, run twice |
| Reversibility | An in-flight task can be exported and continued in Claude Code | `PortableSessionBundleV1` round trip |

The comparison is recorded as a dated review in `docs/reviews/`, with the run IDs, not as an impression. A gate declared from memory is the failure R-099 exists to prevent.

### 4.3 The switch is per workload and reversible

The switch is declared for one workload class at a time, in this order: (1) work on this repository, (2) other trusted repositories, (3) unfamiliar or risky code — which additionally requires the isolated profile that stays deferred until then. Claude Code and Codex remain installed and remain legitimate workers of the system afterwards; nothing about the switch removes them, and the reversibility criterion exists so that returning to them mid-task costs an export rather than a restart.

The rollback condition is stated in advance: two consecutive weeks in which the harness misses any threshold in §4.2 for the switched workload returns that workload to the previous environment and reopens the version. Rollback is a recorded decision, not a retreat.

## 5. What the line changes about sequencing

| Moved | From | To | Because |
| --- | --- | --- | --- |
| Remote service tier | V0.5 | V0.7 | Hosting location adds no capability; it was blocking delegation for no benefit |
| Native subagents + foreign CLI workers | V0.6 | V0.5 | Delegation is the largest single contributor to parity |
| Local MCP registry, lazy proxy and per-task exports | V0.5 (server) | V0.5 (local) | Foreign workers need generated `.mcp.json` before any server exists |
| `server-worker` isolated profile | V0.6 | V0.7 | Isolation matters when execution goes unattended and remote |
| Portable session export | V0.6 | V0.6 | Unchanged in position; reinterpreted as the switch's reversibility guarantee |
| Mission control, personas beyond `self-dev`, IM gateway, web UI | V0.7–V0.8 | V0.8–V0.9 | Agentic layer; starts only after the switch |
| "Switch point" label | V0.4 | V0.6 | V0.4 is where self-hosting starts, not where the harness wins |

The stage numbering in `docs/01` is unchanged — stages are units of implementation content and their ordering constraints are technical. What changed is which version claims which stages, which is `ROADMAP.md`'s business.
