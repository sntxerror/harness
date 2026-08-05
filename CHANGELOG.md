# Bundle Changelog

## 5 August 2026 (governance and host survey)

- Added ADR-036: documented decisions are authority over content, not authorization to act. Agent sessions obtain explicit operator approval per architecture decision before implementing it; runbook command blocks are reviewed content, not scripts to run on sight. Reflected in `CLAUDE.md`, `docs/00` change discipline and the runbook header.
- Surveyed the remote host and recorded actual facts plus four divergences from the runbook's assumptions in `07` (single sudo-capable account rather than an operator/service split, Ubuntu 26.04, nvm-hidden node/Pi in non-interactive shells, no container runtime).
- Added `10` §10: provider calibration for the current pin — measured cost/context data from the host's model catalog, the explicit-versus-automatic cache-write distinction across model families, and the list of mechanics that are not yet established for this API surface.

## 5 August 2026 (V0.0 closeout)

- Closed V0.0: markdown lint clean; `validate-bundle.sh` repaired (dropped the hard `rg` dependency, prunes `.git`, now asserts docs 00–10, all five schemas and a task file per roadmap version); placeholder resolution checklist recorded per template.
- Added `10-context-and-cache-discipline.md`: request zones, breakpoint placement, append-only mutation channels, silent-invalidator audit, cache economics and per-version obligations — the mechanism implementing ADR-007.
- Added ADR-034 (append-only mid-session change; no prefix edits) and ADR-035 (cache conformance as a hash-verified CI gate).
- Added R-082 (breakpoint lookback starvation), R-083 (fan-out cache stampede) and R-084 (unimplemented cache verification).
- Tracked the new obligations as V0.3-T8/T9/T10 and V0.4-T9/T10.
- Added `CLAUDE.md` (repository working conventions) and `HANDOFF.md` (current state and next actions).

## 5 August 2026 (evening revision)

- Added `08-persona-mission-control.md`: personas as top-level profiles, missions, capability assignment pipeline, multi-scope memory, leases, statechart lifecycles and the observability event contract.
- Added `09-topology-and-clients.md`: one control plane with registered runners and stateless clients, placement policy, boundary-only session transfer, forge/IDE/web-UI viewing layers and the edge-only A2A stance.
- Added ADR-028 through ADR-033 and risks R-073 through R-081.
- Integrated the MCP/skills review: measured token-cost exit conditions for Stages 4 and 11, skill authoring budgets and scope precedence, `directTools` epoch rule and the named MCP-gateway fallback class.
- Declared `self-dev` the first persona; self-development begins at factory-core stage via gitflow and the candidate pipeline.

## 5 August 2026

- Consolidated the researched Pi architecture, implementation plan, risks and experiment history.
- Added the deterministic `pi-factory` closed-loop design and SSSF comparison.
- Added `PortableSessionBundleV1` and the local-readable-record portability decision.
- Split Hermes into the narrow `Hermes Memory Service` and later full `Hermes Coordinator`.
- Added a gradual remote-server runbook from vanilla SSH Pi through isolated workers and IM coordination.
- Added permission, interactive shell, profile, router, project-check, session-manifest and systemd templates.
- Added initial schemas for profiles, task envelopes, project checks, user questions and portable session manifests.
- Added read-only preflight and bundle validation scripts.
