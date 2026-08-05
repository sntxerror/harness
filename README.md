# Harness — Ultimate Pi Agent System

This repository is the canonical home of the Ultimate Pi Agent System: a multi-persona, remotely controllable agent platform built around an upstream Pi coding harness, a deterministic workflow runtime (`pi-factory`), a persona/mission control plane and a single governed memory layer.

It contains three things:

1. **The project description** — `docs/` (implementation authority; start at `docs/00-documentation-index.md`).
2. **The trackable plan** — `ROADMAP.md` (functional versions) and `tasks/` (per-version task files with acceptance criteria).
3. **Eventually, the system itself** — code, profiles, registries and machine definitions land here as versions are implemented.

The former `setup-draft/` bundle is superseded by this repository and is kept only as a frozen archive.

## Bootstrap goal

The plan is ordered so the system becomes usable for its own development as early as possible:

- **V0.4 is the switch point.** From then on, changes to this repository are made through the system itself — the `self-dev` persona, factory runs, `project_check`, and deterministic commit finalization — instead of only through external tooling.
- Until then (and in parallel after), development continues with the current toolchain: Claude Code desktop and VS Code with Claude/Codex extensions. These remain legitimate clients/workers of the system afterwards (foreign-harness adapters, Stage 8; VS Code Remote as a viewing client, `docs/09`).
- The existing remote server is used early (V0.5) for the service tier — MCP lazy proxy + registry, RAG, memory service — before any control-plane migration.

## Working agreements

- **Gitflow:** `main` holds released versions (tagged `v0.x`), `develop` is integration, `feature/<task-id>-<slug>` branches per task. A version merges to `main` only when its task file's exit criteria all pass.
- **Remote:** a private GitHub repository is the initial remote (task V0.0-T4). The self-hosted forge joins at V1.0 per `docs/09-topology-and-clients.md` §7.
- **Change discipline:** follows `docs/00-documentation-index.md` — decisions change in ADRs first, then the plan, then code; new uncertainty goes to the risk register; every promoted component has a deterministic acceptance test.
- **Tasks:** each task has an ID (`V0.x-Ty`), a type (research / build / config / eval / ops), dependencies and acceptance criteria. Task status lives in the task files (checkboxes) until the system's own mission board exists (V0.7), which then becomes the tracker of record.
- **Commits:** once V0.4 lands, every commit goes through the commit-finalization transaction (changelog bullet, validated subject, documentation-impact result). Before that, keep messages Conventional-Commit shaped and prepend `CHANGELOG.md` manually.

## Layout

```text
docs/       implementation authority (00–09 + reviews/)
schemas/    canonical contracts (AgentProfileV1, TaskEnvelopeV1, …)
config/     templates — every REPLACE_ value must be resolved before use
scripts/    bundle validation and read-only server preflight
tasks/      per-version task files (V0.0 … V1.0)
ROADMAP.md  version sequence, value statements, switch point
```
