# Harness — Ultimate Pi Agent System

This repository is the canonical home of the Ultimate Pi Agent System: a multi-persona, remotely controllable agent platform built around an upstream Pi coding harness, a deterministic workflow runtime (`pi-factory`), a persona/mission control plane and a single governed memory layer.

It contains three things:

1. **The project description** — `docs/` (implementation authority; start at `docs/00-documentation-index.md`).
2. **The trackable plan** — `ROADMAP.md` (functional versions) and `tasks/` (per-version task files with acceptance criteria).
3. **Eventually, the system itself** — code, profiles, registries and machine definitions land here as versions are implemented.

The former `setup-draft/` bundle is superseded by this repository and is kept only as a frozen archive.

## Bootstrap goal

The plan is ordered in two layers (ADR-040, `docs/11`). The **execution layer** — everything that makes one task run well on one local machine — is completed, used and measured first; the **agentic layer** — scheduling, cross-session knowledge, mission control, remote interfaces — starts only after that:

- **V0.4 is where self-hosting starts.** Changes to this repository can be made through the system itself — the `self-dev` persona, factory runs, `project_check`, deterministic commit finalization — alongside the existing toolchain.
- **V0.6 is the switch.** Daily development moves onto the harness when it passes a measured parity gate against the environment actually in use: capability coverage plus completion rate, correctness, cost, latency, interaction and recovery over a ten-day dual run. The switch is declared per workload class and is reversible (`docs/11` §4).
- Until then, development continues with VS Code and Claude Code. They remain legitimate workers of the system afterwards — from V0.5 the factory spawns Claude Code, Codex and Antigravity under compiled provider profiles (`docs/12`).
- The existing remote server is used at **V0.7**, after the switch, for the service tier. Hosting location adds no capability, so it does not gate anything below the line.

## Working agreements

- **Gitflow:** `main` holds released versions (tagged `v0.x`), `develop` is integration, `feature/<task-id>-<slug>` branches per task. A version merges to `main` only when its task file's exit criteria all pass.
- **Remote:** a private GitHub repository is the initial remote (task V0.0-T4). The self-hosted forge joins at V1.0 per `docs/09-topology-and-clients.md` §7.
- **Change discipline:** follows `docs/00-documentation-index.md` — decisions change in ADRs first, then the plan, then code; new uncertainty goes to the risk register; every promoted component has a deterministic acceptance test.
- **Tasks:** each task has an ID (`V0.x-Ty`), a type (research / build / config / eval / ops), dependencies and acceptance criteria. Task status lives in the task files (checkboxes) until the system's own mission board exists (V0.8), which then becomes the tracker of record.
- **Commits:** once V0.4 lands, every commit goes through the commit-finalization transaction (changelog bullet, validated subject, documentation-impact result). Before that, keep messages Conventional-Commit shaped and prepend `CHANGELOG.md` manually.

## Layout

```text
docs/         implementation authority (00–12 + reviews/)
docs/archive/ frozen imported predecessor material — reference only, never edited
schemas/      canonical contracts (AgentProfileV1, TaskEnvelopeV1, …)
config/       templates — every REPLACE_ value must be resolved before use
scripts/      bundle validation and read-only server preflight
tasks/        per-version task files (V0.0 … V1.0)
ROADMAP.md    version sequence, value statements, switch point
HANDOFF.md    current state and next actions — read first
CLAUDE.md     working conventions for agent sessions in this repo
```

## Verification

Both commands are run from the repository root and must be clean before any commit. `validate-bundle.sh` is read-only, requires `jq`, and uses no network. Both skip `docs/archive/`, which is kept verbatim and must not be able to fail current checks.

```bash
bash scripts/validate-bundle.sh
npx --yes markdownlint-cli2
```
