# Ultimate Pi Setup — Documentation Index

Revision: 22 July 2026

## Purpose

This documentation set separates current implementation authority from history, uncertainty and future experiments. An idea appearing in the brainstorm is not permission to install or build it. The ordered plan is the only implementation sequence.

## Documents

| Document | Authority | Use |
|---|---|---|
| `ultimate-pi-setup-plan.md` | Authoritative | Current staged implementation, configuration examples, acceptance tests and final stack |
| `ultimate-pi-architecture-decisions.md` | Authoritative rationale | Stable decisions, boundaries, ownership and why alternatives were rejected or deferred |
| `ultimate-pi-risks-gaps-overlaps.md` | Active register | Known risks, unresolved questions, validation work, missing components and conflicts |
| `ultimate-pi-brainstorm-evolution.md` | Historical/non-authoritative | Evolution of the design, hypotheses, parked ideas and experiments worth revisiting |

## Reading order

1. Read the architecture decisions to understand the intended system.
2. Use the ordered plan to implement one stage at a time.
3. Check the risk register before promoting any stage.
4. Consult the brainstorm only when traces show a missing capability or a decision needs reconsideration.

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
- Native Pi subagents use compiled static profiles plus dynamic task envelopes. Foreign CLI harnesses run in attachable supervised tmux sessions with a structured user-question relay.
- MCP is used for genuinely remote/stateful services through one lazy proxy and task-specific exports. It does not duplicate native Pi Lens, CodeGraph, local CLIs or generic filesystem/shell access.
- Smart routing is deterministic and chooses a new child cache island. It never changes parent permissions, containment or model algorithmically.

