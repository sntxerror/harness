# Roadmap — functional versions

Every version is a stable, usable increment: it must provide a capability you can exercise the day it ships, and it must pass its task file's exit criteria before merging to `main` and tagging. Plan-stage references point to `docs/01-ordered-implementation-plan.md`; the layer split and the switch to `docs/11`; foreign workers to `docs/12`; persona/topology designs to `docs/08` and `docs/09`.

The sequence follows ADR-040: the **execution layer** — everything that makes one task run well on one local machine — is completed, used and measured before any **agentic layer** component starts. Remote hosting is a deployment property of the agentic layer, not a prerequisite for anything below the line.

## Execution layer — local, ends at the switch

| Version | Name | Value you can use immediately | Plan stages |
| --- | --- | --- | --- |
| V0.0 | Canonical repo & tracking | Single source of truth, gitflow, task tracker, GitHub sync | — |
| V0.1 | Baseline interactive harness | Daily-usable local Pi with permission gating, real PTY, structured questions | 0–2 |
| V0.2 | Code intelligence & validation | Harness understands this repo (CodeGraph, Pi Lens, RAG) and `project_check` gates its commits | 3, 5 |
| V0.3 | Session control | Frozen capability manifests, skill filtering, measured context economy, cache guard | 2.6, 4 |
| V0.4 | Factory core & self-hosting | Executor + `pi-factory` + commit finalization + event stream v0 + `self-dev` persona — the system starts building itself | 6, 6.5, 11.5 |
| V0.5 | Delegation & foreign CLI workers | Subagents in worktrees, local MCP registry, and Claude Code/Codex/Antigravity as compiled-profile phase workers | 9, 10, 11 local |
| V0.6 | **Switch: parity gate** | Web surface, editor integration, portable export; dual run against Claude Code; the harness becomes the daily driver | 12.4 + parity gaps |

## Agentic layer — starts only after the switch

| Version | Name | Value you can use immediately | Plan stages |
| --- | --- | --- | --- |
| V0.7 | Remote services & memory | Server hosts MCP proxy/registry, RAG and memory; isolated `server-worker` profile; reviewed cross-session knowledge | 11 server, 13, 7-equivalent |
| V0.8 | Mission control plane alpha | Orchestrator, mission board, leases, statechart lifecycles, suggest-only router, read-only DAW web UI | 08/09 designs |
| V0.9 | Interfaces & learning loop | Telegram gateway, persona registry + generated editor UI, per-persona memory proposers, candidate promotion with canary | 15, 08 §4–6 |
| V1.0 | Packaged topology | Containerized control plane + runners, Forgejo, runner registration, workstation as peer runner, deploy runbook executed | 09 §7, 07 |

## What moved on 7 August 2026, and why

| Change | Reason |
| --- | --- |
| Remote service tier V0.5 → V0.7 | Hosting location adds no capability and was blocking delegation (ADR-040) |
| Delegation + foreign CLI workers V0.6 → V0.5 | Routing a phase to the best available model is the largest single contributor to parity (ADR-042) |
| Local MCP registry and lazy proxy → V0.5, locally | Foreign workers need a generated `.mcp.json` before any server exists |
| `server-worker` isolated profile V0.6 → V0.7 | Isolation is load-bearing when execution goes unattended, not before (D17, R-102) |
| Switch point V0.4 → V0.6 | Self-hosting and being the better tool are different properties (ADR-041) |
| Mission control V0.7 → V0.8; interfaces V0.8 → V0.9 | Displaced by the new V0.5/V0.6; content unchanged |

## Sequencing rules

- The event schema with lineage IDs ships **inside V0.4** (with the Executor), not with the UI in V0.8 — R-078.
- Measured token gates are exit criteria, not optimizations: the skill catalog at V0.3, the MCP surface and every foreign worker's prefix at V0.5 (ADR-043).
- Statechart definitions for mission/persona/question/lease lifecycles are authored in V0.8 *before* orchestrator code; enforcement is generated from them (ADR-032).
- Optimizations (RTK, narrow LeanCTX, summary model, hashline, routing learning) are scheduled from the V0.4 baseline traces at whatever point those traces justify them — never from position in the plan.
- Any pinned package failing evaluation triggers its named fallback without changing contracts.
- Open decisions are collected in `docs/reviews/2026-08-07-open-decisions-dossier.md` with the version each one blocks; a decision is taken by writing an ADR, not by starting the work.

## Self-development protocol (from V0.4)

1. Work is expressed as tasks from `tasks/`, executed as factory runs by the `self-dev` persona where the workflow fits, or attended sessions where it does not.
2. All commits go through commit finalization; `project_check` is the only green.
3. Improvements the system proposes to its own prompts/skills/profiles/machines are candidates: proposal → review (human) → versioned promotion — never direct writes (R-004/R-051/R-073).
4. From V0.4 the system builds itself; from V0.6 it is also the environment that work is done in. These are different claims and are gated separately (ADR-041).
5. From V0.8, `tasks/` files become mirrors of the mission board; the board is the tracker of record.
