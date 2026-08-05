# Roadmap — functional versions

Every version is a stable, usable increment: it must provide a capability you can exercise the day it ships, and it must pass its task file's exit criteria before merging to `main` and tagging. Plan-stage references point to `docs/01-ordered-implementation-plan.md`; design references to `docs/08` and `docs/09`.

| Version | Name | Value you can use immediately | Plan stages |
| --- | --- | --- | --- |
| V0.0 | Canonical repo & tracking | Single source of truth, gitflow, task tracker, GitHub sync | — |
| V0.1 | Baseline interactive harness | Daily-usable local Pi with permission gating, real PTY, structured questions | 0–2 |
| V0.2 | Code intelligence & validation | Harness understands this repo (CodeGraph, Pi Lens, RAG) and `project_check` gates its commits | 3, 5 (check only) |
| V0.3 | Session control | Frozen capability manifests, skill filtering, measured context economy, cache guard | 4 |
| V0.4 | **Switch point: factory core & self-dev** | Executor + `pi-factory` + commit finalization + event stream v0 + `self-dev` persona — the system starts building itself | 5, 6, 11.5 |
| V0.5 | Remote service tier | Existing server hosts MCP proxy/registry, RAG and memory services consumed by the local runner | 11, part of 12-area |
| V0.6 | Delegation & portability | Native subagents, worktree isolation, Claude Code/Codex as workers, portable session export, isolated server worker | 7–10 |
| V0.7 | Mission control plane alpha | Orchestrator, mission board, leases, statechart lifecycles, suggest-only router, read-only DAW web UI — remote-controllable observable missions | 08/09 designs |
| V0.8 | Interfaces & learning loop | Telegram gateway, persona registry + generated editor UI, per-persona memory proposers, candidate promotion with canary | 12-equivalent, 08 §4–6 |
| V1.0 | Packaged topology | Containerized control plane + runners, Forgejo, runner registration, workstation as peer runner, deploy runbook executed | 09 §7, 07 |

## Sequencing rules

- The event schema with lineage IDs ships **inside V0.4** (with the Executor), not with the UI in V0.7 — R-078.
- Measured token gates (skill catalog at V0.3, MCP surface at V0.5) are exit criteria, not optimizations.
- Statechart definitions for mission/persona/question/lease lifecycles are authored in V0.7 *before* orchestrator code; enforcement is generated from them (ADR-032).
- Optimizations (RTK, narrow LeanCTX, summary model, routing learning) stay after V1.0 unless traces justify earlier trial — plan stage 13 discipline.
- Any pinned package failing evaluation triggers its named fallback (e.g. MCP gateway class in Stage 11) without changing contracts.

## Self-development protocol (from V0.4)

1. Work is expressed as tasks from `tasks/`, executed as factory runs by the `self-dev` persona where the workflow fits, or attended sessions where it does not.
2. All commits go through commit finalization; `project_check` is the only green.
3. Improvements the system proposes to its own prompts/skills/profiles/machines are candidates: proposal → review (human) → versioned promotion — never direct writes (R-004/R-051/R-073).
4. From V0.7, `tasks/` files become mirrors of the mission board; the board is the tracker of record.
