# Bundle Changelog

## 7 August 2026 (pin policy)

- Added ADR-039: packages resolve to their latest published version at install or refresh. A version
  in a document is evidence of a past resolution, never a target — the exact *resolved* version and
  hash are what get recorded, because the cache epoch and `SessionCompatibilityV1` are computed over
  them. Rejected genuinely floating ranges, which would make the manifest hash unreproducible.
- Re-resolved every pin carried in `docs/` on 7 August 2026: permission-system 20.9.1 → 24.0.0,
  interactive-shell 0.13.0 → 0.14.0, subagents 18.1.0 → 19.2.1, pi-lens 3.8.71 → 3.8.74, pi-sandbox
  0.5.0 → 0.6.2. Confirmed already-latest: subagents-worktrees 0.2.3, pi-container-sandbox 0.2.2,
  vmpi 0.4.1, @nqbao/pi-sandbox 0.1.3, pi-handoff-agent 0.2.0, rpiv-ask-user-question 2.4.0.
- Amended the pin rule in `CLAUDE.md` and rewrote R-050's mitigation; added R-092 (a version read as
  a decision rather than as evidence).

## 7 August 2026 (privileged-command channel)

- Added ADR-037: privileged commands have exactly one channel — `interactive_shell` in
  `mode: "interactive"`, the only blocking mode, where the focused overlay writes keystrokes
  straight to the PTY and the model's turn is suspended for the session's life.
- Added ADR-038: the harness account's sudo is time-boxed to Phase 0 and revoked as a V0.1 exit
  condition; `piops` never receives it. Permissions are intent control, containment is the boundary.
- **Corrected the T4 review §3.2.** `interactive_shell` does *not* escape command-level gating: the
  permission system's `shellTools` config maps its `command` onto the full bash enforcement stack,
  and `docs/01` §2.1 already specified the entry. The gating half is configuration, not code.
- Recorded what survives that correction: `mode` is model-supplied with no allowlist, and a call
  carrying only `sessionId` and `input` presents an empty command that matches `"*": "allow"` — so
  privilege classification must be sticky to the session, not evaluated per call.
- Added R-085 (silent alias degradation), R-086 (mode not enforced), R-087 (backgrounded sessions
  stay writable), R-088 (`yoloMode` reachable mid-session), R-089 (un-redacted handoff snapshots),
  R-090 (time-boxed sudo never revoked) and R-091 (empty-command injection).
- Added V0.1-T8 for the channel itself and extended T7's battery with its four probes.

## 6 August 2026 (V0.0 tagged; V0.1-T4 pin inspection)

- Closed and tagged `v0.0`: the closeout branch merged through `develop` to `main`, both gates clean.
- Added `docs/reviews/2026-08-06-v0.1-t4-package-pin-inspection.md` and checked V0.1-T4. All three
  pins accepted with conditions, read from published tarballs without installing or executing them.
- Recorded the R-001 answer: the permission system has no filesystem watcher, so on-disk edits are
  inert, but `/reload` (`resources_discover`) and the `/permission-system` config modal both mutate
  policy mid-session — the modal including `yoloMode`, which auto-approves every ask-state check.
  Parse-once cannot come from upstream; a launcher guard or pinned patch is required.
- Recorded that `pi-interactive-shell` has no secret-awareness of any kind and no permission-system
  integration: `sudo` is safe only because `sudo` disables echo, and the `interactive_shell` tool's
  free-form `command` receives neither the `bash` token gates nor automatic path extraction.
- Recorded the `UserQuestionV1` gap: upstream is a synchronous 1–4 question batch with no
  `sensitivity`, `status` or deadline concept, so an adapter is required and owns the rule that a
  `credential` question is never routed through a questionnaire that echoes typed text.

## 5 August 2026 (archive import and pruning)

- Imported the predecessor material as `docs/archive/`: frozen, non-authoritative provenance, excluded from lint and the JSON check so it can never fail current gates. Nested git history in the vendored SSSF clone was removed and its files are tracked as plain content.
- Pruned what carried no reference value: `setup-draft/` (verified byte-identical to the initial commit except the already-migrated review and the archive banner), the raw GCP quota CSVs (the readable `gcp-audit.md` is kept), and SSSF's bundled visualizer app (its `SKILL.md`, cookbooks and references are kept — that is what `05` compares against). Archive 14M → 916K.

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
